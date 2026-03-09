import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../core/app_theme.dart';

// Reusable card used in both Directory and My Listings screens
class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback? onTap;
  final bool showActions; // true on My Listings — shows edit and delete buttons
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getCategoryIcon(listing.category),
                    color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 12),

              // Name, category badge, and address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.name,
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 15, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(listing.category,
                            style: const TextStyle(color: AppColors.accent,
                                fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.textMuted, size: 13),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(listing.address,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ),
              ),

              // Edit and delete buttons (My Listings only)
              if (showActions) ...[
                const SizedBox(width: 8),
                Column(children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.accent, size: 20),
                    onPressed: onEdit,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ]),
              ] else
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // Maps each category to a relevant Material icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case ListingCategory.hospital:          return Icons.local_hospital_outlined;
      case ListingCategory.policeStation:     return Icons.local_police_outlined;
      case ListingCategory.library:           return Icons.local_library_outlined;
      case ListingCategory.restaurant:        return Icons.restaurant_outlined;
      case ListingCategory.cafe:              return Icons.local_cafe_outlined;
      case ListingCategory.park:              return Icons.park_outlined;
      case ListingCategory.touristAttraction: return Icons.tour_outlined;
      case ListingCategory.utilityOffice:     return Icons.business_outlined;
      default:                                return Icons.place_outlined;
    }
  }
}