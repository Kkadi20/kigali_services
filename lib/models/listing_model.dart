// ═══════════════════════════════════════════════════════════════════════════════
// FILE: lib/models/listing_model.dart
//
// WHY THIS FILE EXISTS:
//   A "model" is a Dart class that mirrors one Firestore document.
//   Instead of working with raw Map<String, dynamic> everywhere in the app,
//   we define a typed object so that:
//     1. The compiler catches typos (e.g. 'adress' instead of 'address')
//     2. IDE autocomplete works
//     3. You have one place to change the schema
//
// DATA FLOW POSITION:
//   Firestore document  →  ListingModel  →  Provider  →  UI widget
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Category constants ───────────────────────────────────────────────────────
// WHY: A fixed list prevents typos in the database and powers the filter chips.
class ListingCategory {
  static const String hospital        = 'Hospital';
  static const String policeStation   = 'Police Station';
  static const String library         = 'Library';
  static const String restaurant      = 'Restaurant';
  static const String cafe            = 'Café';
  static const String park            = 'Park';
  static const String touristAttraction = 'Tourist Attraction';
  static const String utilityOffice   = 'Utility Office';
  static const String market   = 'Markert';

  // All categories in one list – used to build the filter chips in the UI.
  static const List<String> all = [
    hospital,
    policeStation,
    library,
    restaurant,
    cafe,
    park,
    touristAttraction,
    utilityOffice,
    market,
  ];
}

// ─── The main model class ─────────────────────────────────────────────────────
class ListingModel {
  // 'id' is the Firestore document ID, NOT stored inside the document.
  // We attach it when we fetch the document so we can later update/delete it.
  final String id;

  final String name;
  final String category;
  final String address;
  final String contactNumber;
  final String description;
  final double latitude;
  final double longitude;
  final String createdBy;   // Firebase Auth UID of the creator
  final DateTime createdAt;

  // Constructor uses named parameters with 'required' so you can't forget any.
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

  // ── fromFirestore ──────────────────────────────────────────────────────────
  // WHY: Firestore returns a DocumentSnapshot. This factory converts it into
  //      a ListingModel so the rest of the app never touches raw Maps.
  //
  // HOW IT WORKS:
  //   DocumentSnapshot has an 'id' field (the document key).
  //   snapshot.data() returns Map<String, dynamic> – the field values.
  factory ListingModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return ListingModel(
      id:            snapshot.id,           // Firestore auto-generated key
      name:          data['name'] ?? '',
      category:      data['category'] ?? '',
      address:       data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      description:   data['description'] ?? '',
      // Firestore stores numbers as num; cast to double for the map widget.
      latitude:      (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude:     (data['longitude'] as num?)?.toDouble() ?? 0.0,
      createdBy:     data['createdBy'] ?? '',
      // Firestore Timestamps must be converted to Dart DateTime.
      createdAt:     (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── toMap ──────────────────────────────────────────────────────────────────
  // WHY: When we CREATE or UPDATE a document we need a Map<String, dynamic>.
  //      This method converts our model back to that format.
  //
  // NOTE: We use FieldValue.serverTimestamp() on creation so the timestamp
  //       is set by Firestore's clock, not the device clock (safer & consistent).
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

  // ── copyWith ───────────────────────────────────────────────────────────────
  // WHY: Models should be immutable (const constructor).
  //      When you want to edit one field, copyWith gives you a new object
  //      with everything the same except the fields you override.
  ListingModel copyWith({
    String? id,
    String? name,
    String? category,
    String? address,
    String? contactNumber,
    String? description,
    double? latitude,
    double? longitude,
    String? createdBy,
    DateTime? createdAt,
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


// ═══════════════════════════════════════════════════════════════════════════════
// FILE: lib/models/user_model.dart  (defined here for brevity)
//
// WHY: Each Firebase Auth user also gets a Firestore document in /users/{uid}.
//      This model represents that document.
// ═══════════════════════════════════════════════════════════════════════════════
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserModel(
      uid:         snapshot.id,
      email:       data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      createdAt:   (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'email':       email,
    'displayName': displayName,
    'createdAt':   FieldValue.serverTimestamp(),
  };
}