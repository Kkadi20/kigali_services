// ═══════════════════════════════════════════════════════════════════════════════
// FILE: lib/providers/listing_provider.dart
//
// WHY THIS FILE EXISTS:
//   Manages all state related to service listings:
//     - The full list from Firestore (real-time stream)
//     - The filtered/searched list shown in the UI
//     - The user's own listings for "My Listings" screen
//     - Loading and error states for CRUD operations
//
// KEY CONCEPT – TWO LISTS:
//   _allListings     = everything from Firestore (never filtered)
//   filteredListings = what the UI actually shows (result of search + category)
//
//   Why two? Because if you filter _allListings in place, you lose data.
//   The user searches "café" → only cafés show.
//   User clears search → you need the original list back.
//
// DATA FLOW:
//   Firestore stream → _allListings → filterListings() → filteredListings → UI
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';

class ListingProvider extends ChangeNotifier {
  final ListingService _listingService = ListingService();

  // ── State variables ────────────────────────────────────────────────────────
  List<ListingModel> _allListings       = [];
  List<ListingModel> _myListings        = [];
  List<ListingModel> _filteredListings  = [];
  bool   _isLoading     = false;
  String? _errorMessage;

  // Search & filter state
  String  _searchQuery    = '';
  String? _selectedCategory;        // null = All categories

  // ── Stream subscriptions ───────────────────────────────────────────────────
  // WHY: We hold references so we can cancel them when done (avoid memory leaks).
  StreamSubscription<List<ListingModel>>? _allListingsSub;
  StreamSubscription<List<ListingModel>>? _myListingsSub;

  // ── Public getters ─────────────────────────────────────────────────────────
  List<ListingModel> get allListings      => _allListings;
  List<ListingModel> get filteredListings => _filteredListings;
  List<ListingModel> get myListings       => _myListings;
  bool               get isLoading        => _isLoading;
  String?            get errorMessage     => _errorMessage;
  String             get searchQuery      => _searchQuery;
  String?            get selectedCategory => _selectedCategory;

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM SETUP
  // ═══════════════════════════════════════════════════════════════════════════

  // ── startListeningToAllListings ───────────────────────────────────────────
  // WHY: Called once when the Directory screen is first built.
  //      Subscribes to the Firestore stream so any change in the database
  //      automatically updates the UI without any manual refresh.
  //
  // HOW IT WORKS:
  //   _listingService.getAllListings() returns Stream<List<ListingModel>>
  //   .listen() registers a callback that runs every time the stream emits
  //   Inside the callback: save the new list, re-run the filter, notify UI
  void startListeningToAllListings() {
    _allListingsSub?.cancel();  // cancel any previous subscription first

    _allListingsSub = _listingService.getAllListings().listen(
      (listings) {
        _allListings = listings;
        _applyFilter();          // always re-filter when data changes
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load listings: $error';
        notifyListeners();
      },
    );
  }

  // ── startListeningToMyListings ────────────────────────────────────────────
  // WHY: Called once when "My Listings" tab is first shown.
  //      Filters Firestore to only the current user's listings.
  void startListeningToMyListings(String uid) {
    _myListingsSub?.cancel();

    _myListingsSub = _listingService.getListingsByUser(uid).listen(
      (listings) {
        _myListings = listings;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load your listings: $error';
        notifyListeners();
      },
    );
  }

  // ── stopListening ─────────────────────────────────────────────────────────
  // WHY: Called when user logs out. Cancelling subscriptions frees memory
  //      and prevents Firestore billing for unused listeners.
  void stopListening() {
    _allListingsSub?.cancel();
    _myListingsSub?.cancel();
    _allListings = [];
    _myListings = [];
    _filteredListings = [];
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH & FILTER
  // ═══════════════════════════════════════════════════════════════════════════

  // ── updateSearch ──────────────────────────────────────────────────────────
  // WHY: Called every time the user types in the search TextField.
  //      Updates the query and immediately re-filters the list.
  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  // ── selectCategory ────────────────────────────────────────────────────────
  // WHY: Called when a category chip is tapped.
  //      Passing null means "All categories" (no category filter).
  void selectCategory(String? category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  // ── _applyFilter ──────────────────────────────────────────────────────────
  // WHY: Private helper that runs the filter logic and stores the result.
  //      Called whenever _allListings, _searchQuery, or _selectedCategory changes.
  void _applyFilter() {
    _filteredListings = _listingService.filterListings(
      allListings:    _allListings,
      query:          _searchQuery,
      category:       _selectedCategory,
    );
  }

  // ── clearFilters ──────────────────────────────────────────────────────────
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _applyFilter();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── createListing ─────────────────────────────────────────────────────────
  // WHY: UI calls this to add a new listing.
  //      The stream will automatically update _allListings when Firestore confirms.
  //
  // Returns true on success so the UI can navigate back or show a success message.
  Future<bool> createListing(ListingModel listing) async {
    _setLoading(true);
    _clearError();
    try {
      await _listingService.createListing(listing);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create listing: $e';
      _setLoading(false);
      return false;
    }
  }

  // ── updateListing ─────────────────────────────────────────────────────────
  Future<bool> updateListing(ListingModel listing) async {
    _setLoading(true);
    _clearError();
    try {
      await _listingService.updateListing(listing);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update listing: $e';
      _setLoading(false);
      return false;
    }
  }

  // ── deleteListing ─────────────────────────────────────────────────────────
  Future<bool> deleteListing(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _listingService.deleteListing(id);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete listing: $e';
      _setLoading(false);
      return false;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    // No notifyListeners here – caller will trigger it soon
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── dispose ───────────────────────────────────────────────────────────────
  // WHY: Called automatically when the Provider is removed from the widget tree.
  //      MUST cancel stream subscriptions here, or they keep running + billing you.
  @override
  void dispose() {
    _allListingsSub?.cancel();
    _myListingsSub?.cancel();
    super.dispose();
  }
}