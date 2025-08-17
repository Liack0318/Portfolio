// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an item's image and return its public download URL.
  /// We store it at: item_images/<itemId>.jpg
  Future<String> uploadItemImage(File file, String itemId) async {
    final ref = _storage.ref().child('item_images/$itemId.jpg');

    // You can adjust contentType if you support PNG, etc.
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    await ref.putFile(file, metadata);
    final url = await ref.getDownloadURL();
    return url;
  }

  /// Delete an item's image.
  Future<void> deleteItemImage(String itemId) async {
    final ref = _storage.ref().child('item_images/$itemId.jpg');
    await ref.delete();
  }
}
