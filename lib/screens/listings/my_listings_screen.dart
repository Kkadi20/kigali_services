import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../core/app_theme.dart';
import '../../widgets/listing_card.dart';
import 'add_edit_listing_screen.dart';
import 'listing_detail_screen.dart';

// Shows only the listings created by the logged-in user, with edit and delete actions
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  // Shows a confirmation dialog before permanently deleting a listing
  Future<void> _confirmDelete(
      BuildContext context, String listingId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Listing',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete "$name"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ListingProvider>().deleteListing(listingId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = context.watch<ListingProvider>();
    // ignore: unused_local_variable
    final authProvider    = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const AddEditListingScreen())),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        // Loading state
        if (listingProvider.isLoading && listingProvider.myListings.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }

        // Empty state — user has no listings yet
        if (listingProvider.myListings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_location_alt_outlined,
                    color: AppColors.textMuted, size: 64),
                const SizedBox(height: 16),
                const Text("You haven't added any listings yet",
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Tap + to add your first service or place',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AddEditListingScreen())),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text('Add Listing'),
                ),
              ],
            ),
          );
        }

        // List of user's own listings with edit and delete buttons
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: listingProvider.myListings.length,
          itemBuilder: (context, index) {
            final listing = listingProvider.myListings[index];
            return ListingCard(
              listing: listing,
              showActions: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(listing: listing))),
              onEdit: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => AddEditListingScreen(listing: listing))),
              onDelete: () =>
                  _confirmDelete(context, listing.id, listing.name),
            );
          },
        );
      }),
    );
  }
}