import 'dart:io';
import 'package:flutter/material.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item['name']);
    _descController = TextEditingController(text: widget.item['description'] ?? '');
    _quantityController = TextEditingController(text: widget.item['quantity'] ?? '1');
    _priceController = TextEditingController(text: widget.item['price'] ?? '');
    _selectedCategory = widget.item['category'] ?? 'Other';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    // Here you can add logic to update the item in database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item updated (not saved yet)')),
    );
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.item['image'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _isEditing ? _saveChanges : _toggleEdit,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📸 Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imagePath != null
                  ? Image.asset(imagePath, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // 📝 Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              enabled: _isEditing,
            ),

            const SizedBox(height: 12),

            // 📄 Description
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              enabled: _isEditing,
            ),

            const SizedBox(height: 12),

            // 🔢 Quantity
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              enabled: _isEditing,
            ),

            const SizedBox(height: 12),

            // 💰 Price
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              enabled: _isEditing,
            ),

            const SizedBox(height: 12),

            // 🗂️ Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: ['Electronics', 'Clothing', 'Books', 'Other'].map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: _isEditing
                  ? (value) => setState(() => _selectedCategory = value!)
                  : null,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
      ),
    );
  }
}
