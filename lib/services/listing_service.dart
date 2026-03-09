// ═══════════════════════════════════════════════════════════════════════════════
// FILE: lib/services/listing_service.dart
//
// WHY THIS FILE EXISTS:
//   This is the ONLY file that talks to Firestore for listings.
//   Every query, add, update, and delete goes through here.
//
//   RULE: No widget or provider should ever import cloud_firestore directly.
//   This is the "repository pattern" – a single source of truth for data.
//
// FIRESTORE STRUCTURE:
//   /listings
//     /{auto-id}
//       name:          "Kimironko Café"
//       category:      "Café"
//       address:       "KG 11 Ave, Kigali"
//       contactNumber: "+250 788 000 000"
//       description:   "Popular neighborhood café..."
//       latitude:      -1.9441
//       longitude:     30.0619
//       createdBy:     "uid_of_creator"
//       createdAt:     Timestamp(...)
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Collection reference ───────────────────────────────────────────────────
  // WHY: We use a getter so we always get a fresh reference.
  //      'listings' is the top-level Firestore collection name.
  CollectionReference get _listingsRef =>
      _firestore.collection('listings');

  // ═══════════════════════════════════════════════════════════════════════════
  // READ OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── getAllListings ─────────────────────────────────────────────────────────
  // WHY: Returns a REAL-TIME Stream of all listings.
  //
  // HOW STREAMS WORK WITH FIRESTORE:
  //   .snapshots() returns Stream<QuerySnapshot>.
  //   Every time ANY document in 'listings' changes (add/edit/delete),
  //   Firestore pushes a new QuerySnapshot down the stream.
  //   The Provider listens to this stream and rebuilds the UI automatically.
  //   You never need to manually "refresh" the list.
  //
  // .map() transforms the stream:
  //   QuerySnapshot → List<ListingModel>
  //   For each document snapshot, we call ListingModel.fromFirestore()
  Stream<List<ListingModel>> getAllListings() {
    return _listingsRef
        .orderBy('createdAt', descending: true)  // newest first
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
            .map((doc) => ListingModel.fromFirestore(doc))
            .toList());
  }

  // ── getListingsByUser ──────────────────────────────────────────────────────
  // WHY: The "My Listings" screen should only show listings the logged-in
  //      user created. We filter by the 'createdBy' field == current user's UID.
  //
  // FIRESTORE RULE: To use .where() + .orderBy() on different fields,
  //   you must create a Composite Index in the Firebase Console.
  //   The app will throw an error with a link to create it automatically.
  Stream<List<ListingModel>> getListingsByUser(String uid) {
    return _listingsRef
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  // ── getListingById ────────────────────────────────────────────────────────
  // WHY: The detail screen needs a single listing by its Firestore document ID.
  //      We use .get() (one-time fetch) instead of .snapshots() (stream)
  //      because the detail screen doesn't need live updates.
  Future<ListingModel?> getListingById(String id) async {
    final doc = await _listingsRef.doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE
  // ═══════════════════════════════════════════════════════════════════════════

  // ── createListing ─────────────────────────────────────────────────────────
  // WHY: Adds a new document to the 'listings' collection.
  //
  // .add() vs .doc().set():
  //   .add() lets Firestore auto-generate the document ID (safer).
  //   .doc('myId').set() lets you choose the ID (use when ID matters).
  //
  // We use .add() because we don't care about the listing ID format.
  // Firestore returns a DocumentReference whose .id is the new document's ID.
  Future<String> createListing(ListingModel listing) async {
    final docRef = await _listingsRef.add(listing.toMap());
    return docRef.id;  // return the new Firestore-generated ID
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE
  // ═══════════════════════════════════════════════════════════════════════════

  // ── updateListing ─────────────────────────────────────────────────────────
  // WHY: Updates ONLY the fields in the Map, leaving other fields untouched.
  //
  // .update() vs .set():
  //   .update() merges changes – doesn't delete fields you don't include.
  //   .set()    replaces the whole document – deletes unlisted fields.
  //
  // We call listing.toMap() which includes all our fields, so update is safe.
  Future<void> updateListing(ListingModel listing) async {
    await _listingsRef.doc(listing.id).update(listing.toMap());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE
  // ═══════════════════════════════════════════════════════════════════════════

  // ── deleteListing ─────────────────────────────────────────────────────────
  // WHY: Permanently removes a document from Firestore.
  //      The listing ID is the Firestore document ID (snapshot.id from fromFirestore).
  Future<void> deleteListing(String id) async {
    await _listingsRef.doc(id).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH & FILTER (client-side)
  // ═══════════════════════════════════════════════════════════════════════════

  // ── filterListings ────────────────────────────────────────────────────────
  // WHY: Firestore's full-text search is limited (no LIKE queries).
  //      The professional approach for a small dataset like this is:
  //      1. Stream ALL listings from Firestore
  //      2. Filter them in Dart memory
  //
  //      The Provider holds the full list and the filtered list separately.
  //      When the user types or picks a category, the Provider calls this method.
  //
  // PARAMETERS:
  //   allListings – the complete list from Firestore
  //   query       – text typed in the search bar (empty = no filter)
  //   category    – category chip selected (null = show all)
  List<ListingModel> filterListings({
    required List<ListingModel> allListings,
    String query = '',
    String? category,
  }) {
    return allListings.where((listing) {
      // Name filter: check if listing name contains the search query
      // toLowerCase() makes the search case-insensitive
      final matchesQuery = query.isEmpty ||
          listing.name.toLowerCase().contains(query.toLowerCase()) ||
          listing.address.toLowerCase().contains(query.toLowerCase());

      // Category filter: null means "All", otherwise exact match
      final matchesCategory = category == null || listing.category == category;

      // Both conditions must be true for the listing to appear
      return matchesQuery && matchesCategory;
    }).toList();
  }
}