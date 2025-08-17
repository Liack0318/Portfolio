import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final _col = FirebaseFirestore.instance.collection('categories');

  /// live list of category names (sorted)
  Stream<List<String>> streamNames() {
    return _col.orderBy('nameLower').snapshots().map((s) => s.docs
        .map((d) => (d.data()['name'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList());
  }

  /// one-time fetch of category names (sorted)
  Future<List<String>> getNames() async {
    final s = await _col.orderBy('nameLower').get();
    return s.docs
        .map((d) => (d.data()['name'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList();
  }
}
