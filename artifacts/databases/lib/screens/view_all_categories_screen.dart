import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAllCategoriesScreen extends StatefulWidget {
  const ViewAllCategoriesScreen({super.key});

  @override
  State<ViewAllCategoriesScreen> createState() => _ViewAllCategoriesScreenState();
}

class _ViewAllCategoriesScreenState extends State<ViewAllCategoriesScreen> {
  // preset palette; we pick one deterministically from the name hash
  static const List<Color> _palette = <Color>[
    Color(0xFF4F46E5), // indigo
    Color(0xFF22C55E), // green
    Color(0xFFF97316), // orange
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFFEF4444), // red
    Color(0xFFF59E0B), // amber
    Color(0xFF10B981), // emerald
    Color(0xFF3B82F6), // blue
    Color(0xFFEC4899), // pink
  ];

  // stable random color per name
  Color _colorFor(String name) {
    final h = name.hashCode.abs();
    return _palette[h % _palette.length];
  }

  // aggregate count for items in a given category
  Future<int> _countForCategory(String name) async {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return 0;

    final agg = FirebaseFirestore.instance
        .collection('items')
        .where('categoryLower', isEqualTo: key)
        .count();

    final snap = await agg.get();
    return snap.count ?? 0;
  }

  Future<void> _renameCategory({
    required String oldName,
    required String newName,
  }) async {
    final db = FirebaseFirestore.instance;

    final oldTrim = oldName.trim();
    final newTrim = newName.trim();

    if (newTrim.isEmpty) {
      throw Exception('New name cannot be empty.');
    }
    // No-op if same (case-insensitive)
    if (oldTrim.toLowerCase() == newTrim.toLowerCase()) return;

    final oldLower = oldTrim.toLowerCase();
    final newLower = newTrim.toLowerCase();

    // 1) Find the category doc by old nameLower
    final catSnap = await db
        .collection('categories')
        .where('nameLower', isEqualTo: oldLower)
        .limit(1)
        .get();

    if (catSnap.docs.isEmpty) {
      throw Exception('Category "$oldTrim" not found.');
    }
    final catRef = catSnap.docs.first.reference;

    // 2) Prevent duplicates (another category with same newLower)
    final dup = await db
        .collection('categories')
        .where('nameLower', isEqualTo: newLower)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty && dup.docs.first.id != catRef.id) {
      throw Exception('Category "$newTrim" already exists.');
    }

    // 3) Update the category doc
    await catRef.update({
      'name': newTrim,
      'nameLower': newLower,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 4) Update all items referencing the old category (in pages)
    // Use document ID ordering to paginate safely with an equality filter
    const pageSize = 400; // under Firestore's 500 writes per batch
    Query<Map<String, dynamic>> baseQuery = db
        .collection('items')
        .where('categoryLower', isEqualTo: oldLower)
        .orderBy(FieldPath.documentId);

    DocumentSnapshot? lastDoc;
    while (true) {
      var q = baseQuery.limit(pageSize);
      if (lastDoc != null) q = q.startAfterDocument(lastDoc);

      final page = await q.get();
      if (page.docs.isEmpty) break;

      final batch = db.batch();
      for (final d in page.docs) {
        batch.update(d.reference, {
          'category': newTrim,
          'categoryLower': newLower,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (page.docs.length < pageSize) break;
      lastDoc = page.docs.last;
    }
  }

  Future<String?> _promptNewName(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              final v = controller.text.trim();
              Navigator.of(context).pop(v.isEmpty ? null : v);
            },
            decoration: const InputDecoration(
              labelText: 'New name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final v = controller.text.trim();
                Navigator.of(context).pop(v.isEmpty ? null : v);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catsStream = FirebaseFirestore.instance
        .collection('categories')
        .orderBy('nameLower')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Categories'),
        // Removed the AppBar "Edit" action and moved edit per-tile for clarity.
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: catsStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No categories yet'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 tiles per row
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data();
                final name = (data['name'] ?? '').toString();
                final color = _colorFor(name);

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/allItems',
                      arguments: {'category': name},
                    );
                  },
                  onLongPress: () async {
                    // Long-press also opens rename pop-up
                    final newName = await _promptNewName(context, name);
                    if (newName == null) return;

                    try {
                      await _renameCategory(oldName: name, newName: newName);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Renamed "$name" to "$newName".')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Rename failed: $e')),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        // Edit button (top-right)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            tooltip: 'Rename',
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () async {
                              final newName = await _promptNewName(context, name);
                              if (newName == null) return;

                              try {
                                await _renameCategory(oldName: name, newName: newName);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Renamed "$name" to "$newName".')),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Rename failed: $e')),
                                );
                              }
                            },
                          ),
                        ),

                        // Title + count
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('items')
                                  .where('categoryLower', isEqualTo: name.trim().toLowerCase())
                                  .snapshots(),
                              builder: (context, s) {
                                if (s.connectionState == ConnectionState.waiting) {
                                  return const Text(
                                    '… items',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  );
                                }
                                if (s.hasError) {
                                  return const Text(
                                    '0 items',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  );
                                }
                                final count = s.data?.size ?? 0;
                                return Text(
                                  '$count items',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                );
                              },
                            )

                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
