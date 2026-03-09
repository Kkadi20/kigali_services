import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/listing_provider.dart';
import '../../models/listing_model.dart';
import '../../core/app_theme.dart';
import '../../widgets/listing_card.dart';
import '../listings/listing_detail_screen.dart';
import '../listings/add_edit_listing_screen.dart';

// Browsing screen — shows search bar, category chips, and filtered listings
class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final listingProvider = context.watch<ListingProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with listing count and add button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kigali City',
                          style: TextStyle(fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      Text('${listingProvider.filteredListings.length} services found',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: AppColors.accent, size: 32),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AddEditListingScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar — filters listings in real time as user types
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: listingProvider.updateSearch,
                decoration: InputDecoration(
                  hintText: 'Search for a service...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: listingProvider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => listingProvider.updateSearch(''),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal category filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _CategoryChip(
                    label: 'All',
                    isSelected: listingProvider.selectedCategory == null,
                    onTap: () => listingProvider.selectCategory(null),
                  ),
                  ...ListingCategory.all.map((category) => _CategoryChip(
                    label: category,
                    isSelected: listingProvider.selectedCategory == category,
                    onTap: () => listingProvider.selectCategory(category),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Near You',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 8),

            // Listings list — handles loading, error, empty, and data states
            Expanded(child: _buildListingsList(context, listingProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsList(BuildContext context, ListingProvider provider) {
    if (provider.isLoading && provider.allListings.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (provider.errorMessage != null && provider.allListings.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(provider.errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary)),
          TextButton(
            onPressed: provider.clearError,
            child: const Text('Retry',
                style: TextStyle(color: AppColors.accent)),
          ),
        ]),
      );
    }

    if (provider.filteredListings.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.search_off, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            provider.searchQuery.isNotEmpty
                ? 'No results for "${provider.searchQuery}"'
                : 'No listings yet. Add one!',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ]),
      );
    }

    // Scrollable list of listing cards
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: provider.filteredListings.length,
      itemBuilder: (context, index) {
        final listing = provider.filteredListings[index];
        return ListingCard(
          listing: listing,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => ListingDetailScreen(listing: listing))),
        );
      },
    );
  }
}

// Reusable chip widget — highlights in gold when selected
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}