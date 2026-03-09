import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/listing_model.dart';
import '../../core/app_theme.dart';

// Shows full details of a listing with an embedded OpenStreetMap and directions button
class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final MapController _mapController = MapController();

  // Opens Google Maps app for navigation — no API key needed
  Future<void> _launchNavigation() async {
    final lat  = widget.listing.latitude;
    final lng  = widget.listing.longitude;
    final name = Uri.encodeComponent(widget.listing.name);
    final uri  = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final fallback = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
      if (await canLaunchUrl(fallback)) {
        await launchUrl(fallback);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open Maps. Please install Google Maps.'),
        ));
      }
    }
  }

  // Opens the phone dialler with the listing contact number
  Future<void> _callNumber() async {
    final uri = Uri.parse('tel:${widget.listing.contactNumber}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final listing  = widget.listing;
    final position = LatLng(listing.latitude, listing.longitude);

    return Scaffold(
      appBar: AppBar(title: Text(listing.name)),
      body: Column(
        children: [
          // Embedded OpenStreetMap with a pin at the listing location
          SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: position,
                initialZoom: 15.0,
              ),
              children: [
                // Free OpenStreetMap tiles — no API key required
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.kigali_services',
                ),
                // Gold pin marker at listing coordinates
                MarkerLayer(markers: [
                  Marker(
                    point: position,
                    width: 50, height: 50,
                    child: const Icon(Icons.location_pin,
                        color: AppColors.accent, size: 50),
                  ),
                ]),
              ],
            ),
          ),

          // Scrollable details section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and category badge
                  Text(listing.name,
                      style: const TextStyle(fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(listing.category,
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 13)),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Description
                  const Text('About',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(listing.description,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 20),

                  // Address, contact, and coordinates rows
                  _InfoRow(icon: Icons.location_on_outlined,
                      label: 'Address', value: listing.address),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.phone_outlined,
                      label: 'Contact', value: listing.contactNumber,
                      onTap: _callNumber),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.my_location_outlined,
                      label: 'Coordinates',
                      value: '${listing.latitude.toStringAsFixed(4)}, '
                          '${listing.longitude.toStringAsFixed(4)}'),
                  const SizedBox(height: 32),

                  // Directions button — launches Google Maps app
                  ElevatedButton.icon(
                    onPressed: _launchNavigation,
                    icon: const Icon(Icons.directions, color: Colors.black),
                    label: const Text('Get Directions'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable row for displaying an icon, label, and value
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({required this.icon, required this.label,
      required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                    color: onTap != null
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}