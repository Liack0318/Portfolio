import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// services
import 'package:inventory_app_mp/services/storage_service.dart';
import 'package:inventory_app_mp/services/category_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isEditing = false;
  bool _isBusy = false;

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late String _selectedCategory;

  final CategoryService _categoryService = CategoryService();

  // convenience getter for doc id
  String get _itemId => widget.item['id'] as String;

  // holds a new image chosen while editing (preview before saving)
  File? _newImageFile;

  // storage service instance
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: (widget.item['name'] ?? '').toString());
    _descController = TextEditingController(text: (widget.item['description'] ?? '').toString());
    _quantityController = TextEditingController(text: (widget.item['quantity'] ?? '').toString());
    _priceController = TextEditingController(text: (widget.item['price'] ?? '').toString());
    _selectedCategory = (widget.item['category'] ?? 'Other').toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // applies Firestore data to the inputs (only when not editing)
  void _hydrateFrom(Map<String, dynamic> data) {
    if (_isEditing) return; // don't stomp user edits
    _nameController.text = (data['name'] ?? '').toString();
    _descController.text = (data['description'] ?? '').toString();
    _quantityController.text = (data['quantity'] ?? '').toString();
    _priceController.text = (data['price'] ?? '').toString();
    _selectedCategory = (data['category'] ?? 'Other').toString();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      // cancel pending image if user exits edit mode
      if (!_isEditing) _newImageFile = null;
    });
  }

  // lets user pick a new image while editing
  Future<void> _pickNewImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newImageFile = File(picked.path);
      });
    }
  }

  // validates and saves changes (and uploads image if changed)
  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final quantityText = _quantityController.text.trim();
    final priceText = _priceController.text.trim();

    // simple checks
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be a non-negative integer')),
      );
      return;
    }
    final double? price = priceText.isEmpty ? null : double.tryParse(priceText);
    if (priceText.isNotEmpty && price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be a valid number (e.g., 19.99)')),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      final updates = <String, dynamic>{
        'name': name,
        'nameLower': name.trim().toLowerCase(),
        'description': _descController.text.trim(),
        'quantity': quantity,
        'price': price,
        'category': _selectedCategory,
        'categoryLower': _selectedCategory.toLowerCase(),
        'dateUpdated': DateTime.now(),
      };

      // if user picked a new image, upload then include the new URL
      if (_newImageFile != null) {
        final url = await _storageService.uploadItemImage(_newImageFile!, _itemId);
        updates['imageUrl'] = url;
      }

      await FirebaseFirestore.instance.collection('items').doc(_itemId).update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated')),
        );
        // leave edit mode and clear the pending image
        setState(() {
          _isEditing = false;
          _newImageFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // asks user to confirm delete
  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      await _deleteItem();
    }
  }

  // deletes the doc (and optionally its image in storage)
  Future<void> _deleteItem() async {
    setState(() => _isBusy = true);
    try {
      await FirebaseFirestore.instance.collection('items').doc(_itemId).delete();

      // optional: also delete storage image
      // try { await StorageService().deleteItemImage(_itemId); } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
        Navigator.pop(context, {'deleted': true});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('items').doc(_itemId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          // delete icon shows only in edit mode
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isBusy ? null : _confirmDelete,
              tooltip: 'Delete',
            ),
          IconButton(
            icon: _isBusy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _isBusy ? null : (_isEditing ? _saveChanges : _toggleEdit),
            tooltip: _isEditing ? 'Save' : 'Edit',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.data!.exists) {
            return const Center(child: Text('Item not found'));
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          _hydrateFrom(data);
          final imageUrl = (data['imageUrl'] ?? '').toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // image with optional local preview while editing
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _newImageFile != null
                        ? Image.file(_newImageFile!, fit: BoxFit.cover, alignment: Alignment.center)
                        : (imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image, size: 64, color: Colors.grey),
                      ),
                    )),
                  ),
                ),

                // change image button visible while editing
                if (_isEditing) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _isBusy ? null : _pickNewImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Change image'),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // name
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  enabled: _isEditing && !_isBusy,
                ),
                const SizedBox(height: 12),

                // description
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                  enabled: _isEditing && !_isBusy,
                ),
                const SizedBox(height: 12),

                // quantity
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  enabled: _isEditing && !_isBusy,
                ),
                const SizedBox(height: 12),

                // price
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  enabled: _isEditing && !_isBusy,
                ),
                const SizedBox(height: 12),

                // category (live from firestore)
                StreamBuilder<List<String>>(
                  stream: _categoryService.streamNames(),
                  builder: (context, snap) {
                    final cats = snap.data ?? [];
                    final items = cats.isEmpty ? ['Other'] : cats;

                    // keep value valid if categories changed
                    if (!items.contains(_selectedCategory)) {
                      _selectedCategory = items.first;
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: items
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: _isEditing && !_isBusy
                          ? (v) => setState(() => _selectedCategory = v!)
                          : null,
                      decoration: const InputDecoration(labelText: 'Category'),
                    );
                  },
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}
