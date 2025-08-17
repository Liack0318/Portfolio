import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

// this screen is for adding a new item
// services
import 'package:inventory_app_mp/services/item_service.dart';
import 'package:inventory_app_mp/services/storage_service.dart';
import 'package:inventory_app_mp/services/category_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  // Controllers to get input from text fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  // Default selected category and list of avaiable ones
  String _selectedCategory = 'Other';

  // services
  final CategoryService _categoryService = CategoryService();

  // Holds the selected image file
  File? _imageFile;

  // saving state to prevent double taps
  bool _isSaving = false;

  // services instances (no singleton in your code)
  final ItemService _itemService = ItemService();
  final StorageService _storageService = StorageService();

  // builds a simple line-style input decoration
  InputDecoration _lineDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const UnderlineInputBorder(),
      enabledBorder: const UnderlineInputBorder(),
      focusedBorder: const UnderlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  //Opens gallery to let user pick an image
  void _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  // Validates form and sends data to services
  Future<void> _submitItem() async {
    final name = _nameController.text.trim();
    final quantityText = _quantityController.text.trim();

    // Check the required fields are filled
    if (name.isEmpty || quantityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and quantity are required')),
      );
      return;
    }

    // parse quantity
    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be a non-negative integer')),
      );
      return;
    }

    // parse price (optional)
    final priceText = _priceController.text.trim();
    final double? price = priceText.isEmpty ? null : double.tryParse(priceText);
    if (priceText.isNotEmpty && price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be a number (e.g., 19.99)')),
      );
      return;
    }

    // check auth user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add items.')),
      );
      return;
    }
    final uid = user.uid;

    //Gets todays date
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // build item map for back end
      final data = <String, dynamic>{
        'name': name,
        'nameLower': name.trim().toLowerCase(),
        'description': _descriptionController.text.trim(),
        'quantity': quantity,
        'price': price, // can be null
        'category': _selectedCategory,
        'categoryLower': _selectedCategory.toLowerCase(),
        'dateAdded': now,
        'dateFormatted': date,
        'ownerUid': uid,
        'imageUrl': null, // will be set after upload if we have one
      };

      // create item via item service (matches your signature)
      final String itemId = await _itemService.addItem(data);

      // upload image if user selected one (matches your signature)
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _storageService.uploadItemImage(_imageFile!, itemId);

        // update item with image url (matches your signature)
        await _itemService.updateItem(itemId, {'imageUrl': imageUrl});
      }

      // go back with result payload
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved')),
        );
        Navigator.pop(context, {
          'itemId': itemId,
          'imageUrl': imageUrl,
        }); // go back
      }
    } catch (e) {
      // show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save item: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image preview or default icon
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            //button to upload image
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _pickImage,
              icon: const Icon(Icons.upload),
              label: const Text('Upload Image'),
            ),

            const SizedBox(height: 20),

            // Item name required
            TextField(
              controller: _nameController,
              decoration: _lineDecoration('Name *'),
            ),
            const SizedBox(height: 12),

            // Description optional
            TextField(
              controller: _descriptionController,
              decoration: _lineDecoration('Description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            //quantity required
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: _lineDecoration('Quantity *'),
            ),
            const SizedBox(height: 12),

            // Category (live from firestore)
            StreamBuilder<List<String>>(
              stream: _categoryService.streamNames(),
              builder: (context, snap) {
                final cats = snap.data ?? [];
                // ensure a safe selection
                final List<String> items = cats.isEmpty ? ['Other'] : cats;
                if (!items.contains(_selectedCategory)) {
                  _selectedCategory = items.first;
                }

                return DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: _lineDecoration('Category'), // or use a plain InputDecoration
                  items: items
                      .map((cat) => DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  ))
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                    setState(() => _selectedCategory = value!);
                  },
                );
              },
            ),

            // Price optional
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: _lineDecoration('Price (optional)'),
            ),
            const SizedBox(height: 20),

            // Save button
            //TODO: Connect to backend
            ElevatedButton(
              onPressed: _isSaving ? null : _submitItem,
              child: _isSaving
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Save Item'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
