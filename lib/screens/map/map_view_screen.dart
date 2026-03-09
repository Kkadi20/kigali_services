import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/listing_provider.dart';
import '../../models/listing_model.dart';
import '../../core/app_theme.dart';
import '../listings/listing_detail_screen.dart';

// Shows all listings as markers on an OpenStreetMap — no API key required
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapController _mapController = MapController();

  // Default map center — Kigali city center
  static const _kigaliCenter = LatLng(-1.9441, 30.0619);

  // Tapped listing — drives the bottom info card
  ListingModel? _selectedListing;

  // Builds a gold pin marker for each listing
  List<Marker> _buildMarkers(List<ListingModel> listings) {
    return listings.map((listing) {
      final position = LatLng(listing.latitude, listing.longitude);
      return Marker(
        point: position,
        width: 50, height: 50,
        child: GestureDetector(
          onTap: () => setState(() => _selectedListing = listing),
          child: Icon(
            Icons.location_pin,
            // Brighter colour when this marker is selected
            color: _selectedListing?.id == listing.id
                ? AppColors.accentLight
                : AppColors.accent,
            size: 45,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = context.watch<ListingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: Stack(
        children: [
          // Full-screen OpenStreetMap with all listing markers
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _kigaliCenter,
              initialZoom: 12.0,
              // Tapping empty map dismisses the selected listing card
              onTap: (_, __) => setState(() => _selectedListing = null),
            ),
            children: [
              // Free OpenStreetMap tiles — no API key needed
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.kigali_services',
              ),
              MarkerLayer(markers: _buildMarkers(listingProvider.allListings)),
            ],
          ),

          // Badge showing total number of listings on the map
          Positioned(
            top: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${listingProvider.allListings.length} places',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Bottom card — appears when a marker is tapped, links to detail screen
          if (_selectedListing != null)
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ListingDetailScreen(listing: _selectedListing!))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3),
                          blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.place, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedListing!.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          Text(_selectedListing!.category,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}