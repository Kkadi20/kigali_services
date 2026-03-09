import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

// Handles all Firestore operations for listings — the only file that touches Firestore
class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the listings collection
  CollectionReference get _listingsRef => _firestore.collection('listings');

  // Returns a real-time stream of all listings, newest first
  Stream<List<ListingModel>> getAllListings() {
    return _listingsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs
            .map((doc) => ListingModel.fromFirestore(doc))
            .toList());
  }

  // Returns a real-time stream of listings created by a specific user
  Stream<List<ListingModel>> getListingsByUser(String uid) {
    return _listingsRef
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs
            .map((doc) => ListingModel.fromFirestore(doc))
            .toList());
  }

  // Fetches a single listing by its Firestore document ID
  Future<ListingModel?> getListingById(String id) async {
    final doc = await _listingsRef.doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }

  // Adds a new listing document to Firestore, returns the new document ID
  Future<String> createListing(ListingModel listing) async {
    final docRef = await _listingsRef.add(listing.toMap());
    return docRef.id;
  }

  // Updates an existing listing document in Firestore
  Future<void> updateListing(ListingModel listing) async {
    await _listingsRef.doc(listing.id).update(listing.toMap());
  }

  // Permanently deletes a listing document from Firestore
  Future<void> deleteListing(String id) async {
    await _listingsRef.doc(id).delete();
  }

  // Filters listings in memory by search query and category
  List<ListingModel> filterListings({
    required List<ListingModel> allListings,
    String query = '',
    String? category,
  }) {
    return allListings.where((listing) {
      final matchesQuery = query.isEmpty ||
          listing.name.toLowerCase().contains(query.toLowerCase()) ||
          listing.address.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = category == null || listing.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
  }
}