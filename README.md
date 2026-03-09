# Kigali City Services & Places Directory

A Flutter mobile application for discovering and managing services and places in Kigali, Rwanda. Built with Firebase Authentication, Cloud Firestore, and the Provider state management pattern.

---

## Features

- **Email Authentication** — Sign up, log in, and log out using Firebase Auth with enforced email verification
- **Browse Directory** — View all listings in real time with search by name and category filter chips
- **Add Listings** — Create new service or place listings with name, category, address, contact, description, and GPS coordinates
- **Edit & Delete** — Update or remove your own listings with confirmation dialogs
- **Map View** — See all listings as markers on an embedded OpenStreetMap (no API key required)
- **Listing Detail** — View full details with an embedded map pin and Get Directions button
- **Settings** — View your profile, toggle notifications, and sign out

---

## Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** Authentication under Authentication → Sign-in method
3. Create a **Cloud Firestore** database in production mode (region: europe-west1)
4. Register an Android app with package name `com.example.kigali_services`
5. Download `google-services.json` and place it in `android/app/`
6. Run `flutterfire configure` to generate `lib/firebase_options.dart`
7. Apply the Firestore security rules below

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
    match /listings/{listingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
                            && request.auth.uid == resource.data.createdBy;
    }
  }
}
```

### Composite Index Required

The My Listings screen requires a composite index on the `listings` collection:

| Field | Order |
|-------|-------|
| createdBy | Ascending |
| createdAt | Descending |

Create it in Firebase Console → Firestore → Indexes → Add Index.

---

## Firestore Collections

### `/listings/{auto-id}`

| Field | Type | Description |
|-------|------|-------------|
| name , String , Display name of the service or place |
| category , String , One of the predefined categories |
| address , String , Street address in Kigali |
| contactNumber String  Phone number |
| description String , Brief description |
| latitude  Number , GPS latitude (e.g. -1.9441) |
| longitude  Number , GPS longitude (e.g. 30.0619) |
| createdBy  String , Firebase Auth UID of the creator |
| createdAt  Timestamp , Server timestamp on creation |

### `/users/{uid}`

| Field | Type | Description |
|-------|------|-------------|
| email , String , User email address |
| displayName , String , Full name from signup |
| createdAt , Timestamp , Account creation time |

---

## State Management

The app uses the **Provider** package with a strict three-layer architecture:

```
Firestore → Service Layer → Provider Layer → UI Widgets
```

- **Services** (`lib/services/`) — the only files that import Firebase and handels  all Firestore queries and Auth calls live here.
- **Providers** (`lib/providers/`) — hold app state as private variables, expose via getters, call `notifyListeners()` on changes.
- **Screens** (`lib/screens/`) — never import Firebase. Use `context.watch<Provider>()` to subscribe and `context.read<Provider>()` for actions.

### Real-time Data Flow

```
Firestore stream emits new data
  → ListingService maps snapshot to List<ListingModel>
  → ListingProvider updates state and calls notifyListeners()
  → All watching widgets rebuild automatically
```

---

## Navigation Structure

`BottomNavigationBar` with `IndexedStack` — keeps all tabs alive to preserve streams and scroll state.

---

## Folder Structure

```
lib/
├── core/
│   └── app_theme.dart          # Color palette and MaterialApp theme
├── models/
│   ├── listing_model.dart      # Firestore listing document model
│   └── user_model.dart         # Firestore user document model
├── services/
│   ├── auth_service.dart       # Firebase Auth operations
│   └── listing_service.dart    # Firestore CRUD operations
├── providers/
│   ├── auth_provider.dart      # Authentication state
│   └── listing_provider.dart   # Listings state + search/filter
├── screens/
│   ├── auth/                   # Login, Signup, EmailVerification, AuthWrapper
│   ├── directory/              # Directory browse screen
│   ├── listings/               # Add/Edit, Detail, My Listings screens
│   ├── map/                    # Map view screen
│   ├── settings/               # Settings screen
│   └── home_screen.dart        # BottomNavigationBar shell
└── widgets/
    └── listing_card.dart       # Reusable listing card widget
```

---

## Dependencies

```yaml
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
provider: ^6.1.1
flutter_map: ^6.1.0
latlong2: ^0.9.0
url_launcher: ^6.2.4
```

> **Note:** `flutter_map` uses free OpenStreetMap tiles — no API key required.

---

## Running the App

```bash
flutter pub get
flutter run
```
