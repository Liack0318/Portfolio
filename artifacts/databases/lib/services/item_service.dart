// lib/services/item_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add a new item document to Firestore.
  /// Returns the document ID so we can link it with an image.
  Future<String> addItem(Map<String, dynamic> data) async {
    final doc = await _db.collection('items').add(data);
    return doc.id;
  }

  /// Update an existing item document by its ID.
  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await _db.collection('items').doc(id).update(data);
  }

  /// (Optional) Delete an item document.
  Future<void> deleteItem(String id) async {
    await _db.collection('items').doc(id).delete();
  }
}
