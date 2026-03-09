import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';

// Manages all listing state — full list, filtered list, my listings, and CRUD operations
class ListingProvider extends ChangeNotifier {
  final ListingService _listingService = ListingService();

  // Two separate lists: all from Firestore, and the filtered result shown in UI
  List<ListingModel> _allListings      = [];
  List<ListingModel> _myListings       = [];
  List<ListingModel> _filteredListings = [];
  bool    _isLoading       = false;
  String? _errorMessage;

  // Current search and filter state
  String  _searchQuery     = '';
  String? _selectedCategory;

  // Stream subscriptions — kept so we can cancel them on logout
  StreamSubscription<List<ListingModel>>? _allListingsSub;
  StreamSubscription<List<ListingModel>>? _myListingsSub;

  // Getters for UI
  List<ListingModel> get allListings      => _allListings;
  List<ListingModel> get filteredListings => _filteredListings;
  List<ListingModel> get myListings       => _myListings;
  bool               get isLoading        => _isLoading;
  String?            get errorMessage     => _errorMessage;
  String             get searchQuery      => _searchQuery;
  String?            get selectedCategory => _selectedCategory;

  // Subscribes to all listings stream — called when Directory tab loads
  void startListeningToAllListings() {
    _allListingsSub?.cancel();
    _allListingsSub = _listingService.getAllListings().listen(
      (listings) {
        _allListings = listings;
        _applyFilter();
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load listings: $error';
        notifyListeners();
      },
    );
  }

  // Subscribes to the current user's listings — called when My Listings tab loads
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

  // Cancels all streams and clears data on logout
  void stopListening() {
    _allListingsSub?.cancel();
    _myListingsSub?.cancel();
    _allListings = [];
    _myListings  = [];
    _filteredListings = [];
    notifyListeners();
  }

  // Updates search query and re-filters the list
  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  // Updates selected category chip and re-filters the list
  void selectCategory(String? category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  // Runs filter logic against the full list and stores the result
  void _applyFilter() {
    _filteredListings = _listingService.filterListings(
      allListings: _allListings,
      query:       _searchQuery,
      category:    _selectedCategory,
    );
  }

  void clearFilters() {
    _searchQuery      = '';
    _selectedCategory = null;
    _applyFilter();
    notifyListeners();
  }

  // Creates a new listing in Firestore
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

  // Updates an existing listing in Firestore
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

  // Deletes a listing from Firestore by document ID
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Cancels stream subscriptions when provider is removed from widget tree
  @override
  void dispose() {
    _allListingsSub?.cancel();
    _myListingsSub?.cancel();
    super.dispose();
  }
}