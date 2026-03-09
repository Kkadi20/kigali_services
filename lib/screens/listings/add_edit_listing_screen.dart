import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../models/listing_model.dart';
import '../../core/app_theme.dart';

// Dual-purpose screen — Add mode when listing is null, Edit mode when listing is provided
class AddEditListingScreen extends StatefulWidget {
  final ListingModel? listing;
  const AddEditListingScreen({super.key, this.listing});

  @override
  State<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends State<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  String _selectedCategory = ListingCategory.all.first;

  // True when editing an existing listing
  bool get _isEditMode => widget.listing != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields in edit mode, empty in add mode
    final l = widget.listing;
    _nameController        = TextEditingController(text: l?.name ?? '');
    _addressController     = TextEditingController(text: l?.address ?? '');
    _contactController     = TextEditingController(text: l?.contactNumber ?? '');
    _descriptionController = TextEditingController(text: l?.description ?? '');
    _latController         = TextEditingController(text: l?.latitude.toString() ?? '');
    _lngController         = TextEditingController(text: l?.longitude.toString() ?? '');
    if (l != null) _selectedCategory = l.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // Builds a ListingModel from form values and calls create or update
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider    = context.read<AuthProvider>();
    final listingProvider = context.read<ListingProvider>();

    final listingData = ListingModel(
      id:            _isEditMode ? widget.listing!.id : '',
      name:          _nameController.text.trim(),
      category:      _selectedCategory,
      address:       _addressController.text.trim(),
      contactNumber: _contactController.text.trim(),
      description:   _descriptionController.text.trim(),
      latitude:      double.tryParse(_latController.text) ?? 0.0,
      longitude:     double.tryParse(_lngController.text) ?? 0.0,
      createdBy:     _isEditMode
                       ? widget.listing!.createdBy
                       : authProvider.authUser!.uid,
      createdAt:     _isEditMode ? widget.listing!.createdAt : DateTime.now(),
    );

    final success = _isEditMode
        ? await listingProvider.updateListing(listingData)
        : await listingProvider.createListing(listingData);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditMode ? 'Listing updated!' : 'Listing created!'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = context.watch<ListingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Listing' : 'Add New Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              _buildLabel('Service / Place Name *'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Kimironko Market'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              _buildLabel('Category *'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                items: ListingCategory.all.map((cat) => DropdownMenuItem(
                  value: cat, child: Text(cat),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              // Address field
              _buildLabel('Address *'),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(hintText: 'e.g. KG 11 Ave, Kigali'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),

              // Contact number field
              _buildLabel('Contact Number *'),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'e.g. +250 788 000 000'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Contact number is required' : null,
              ),
              const SizedBox(height: 16),

              // Description field
              _buildLabel('Description *'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe this service or place...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // GPS coordinates — find on Google Maps by right-clicking a location
              _buildLabel('GPS Coordinates'),
              const Text(
                'Tip: Right-click any location on Google Maps to copy coordinates',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                        hintText: 'Latitude (e.g. -1.9441)'),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(v!) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                        hintText: 'Longitude (e.g. 30.0619)'),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(v!) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 32),

              // Error banner
              if (listingProvider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(listingProvider.errorMessage!,
                      style: const TextStyle(color: AppColors.error)),
                ),
                const SizedBox(height: 16),
              ],

              // Submit button — shows spinner while saving
              ElevatedButton(
                onPressed: listingProvider.isLoading ? null : _submit,
                child: listingProvider.isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text(_isEditMode ? 'Save Changes' : 'Add Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable label widget for form sections
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(color: AppColors.textSecondary,
              fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}