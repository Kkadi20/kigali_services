import 'package:cloud_firestore/cloud_firestore.dart';

// Category constants used for filter chips and dropdown in the UI
class ListingCategory {
  static const String hospital          = 'Hospital';
  static const String policeStation     = 'Police Station';
  static const String library           = 'Library';
  static const String restaurant        = 'Restaurant';
  static const String cafe              = 'Café';
  static const String park              = 'Park';
  static const String touristAttraction = 'Tourist Attraction';
  static const String utilityOffice     = 'Utility Office';
  static const String market            = 'Market';

  static const List<String> all = [
    hospital, policeStation, library, restaurant,
    cafe, park, touristAttraction, utilityOffice, market,
  ];
}

// Mirrors one Firestore document in the /listings collection
class ListingModel {
  final String id;          // Firestore document ID
  final String name;
  final String category;
  final String address;
  final String contactNumber;
  final String description;
  final double latitude;
  final double longitude;
  final String createdBy;   // Firebase Auth UID of the creator
  final DateTime createdAt;

  const ListingModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.contactNumber,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdBy,
    required this.createdAt,
  });

  // Converts a Firestore DocumentSnapshot into a ListingModel
  factory ListingModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ListingModel(
      id:            snapshot.id,
      name:          data['name'] ?? '',
      category:      data['category'] ?? '',
      address:       data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      description:   data['description'] ?? '',
      latitude:      (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude:     (data['longitude'] as num?)?.toDouble() ?? 0.0,
      createdBy:     data['createdBy'] ?? '',
      createdAt:     (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Converts this model to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name':          name,
      'category':      category,
      'address':       address,
      'contactNumber': contactNumber,
      'description':   description,
      'latitude':      latitude,
      'longitude':     longitude,
      'createdBy':     createdBy,
      'createdAt':     FieldValue.serverTimestamp(),
    };
  }

  // Returns a copy of this model with selected fields overridden
  ListingModel copyWith({
    String? id, String? name, String? category, String? address,
    String? contactNumber, String? description,
    double? latitude, double? longitude,
    String? createdBy, DateTime? createdAt,
  }) {
    return ListingModel(
      id:            id            ?? this.id,
      name:          name          ?? this.name,
      category:      category      ?? this.category,
      address:       address       ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      description:   description   ?? this.description,
      latitude:      latitude      ?? this.latitude,
      longitude:     longitude     ?? this.longitude,
      createdBy:     createdBy     ?? this.createdBy,
      createdAt:     createdAt     ?? this.createdAt,
    );
  }

  @override
  String toString() => 'ListingModel(id: $id, name: $name, category: $category)';
}