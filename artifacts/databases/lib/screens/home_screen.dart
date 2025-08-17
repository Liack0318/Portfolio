import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({Key? key, required this.username}) : super(key: key);

  // refs to collections
  CollectionReference<Map<String, dynamic>> get _itemsCol =>
      FirebaseFirestore.instance.collection('items');
  CollectionReference<Map<String, dynamic>> get _catsCol =>
      FirebaseFirestore.instance.collection('categories');

  @override
  Widget build(BuildContext context) {
    // streams for counts
    final itemsStream = _itemsCol.snapshots();
    final catsStream = _catsCol.snapshots();

    // last 10 items stream
    final lastTenStream =
    _itemsCol.orderBy('dateAdded', descending: true).limit(10).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top blue area with background image and shortcut buttons
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/cardB.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // overlay
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    // content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $username!',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Inventory App',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionButton(
                                Icons.add,
                                'Add Item',
                                    () => Navigator.pushNamed(context, '/addItem'),
                              ),
                              _buildActionButton(
                                Icons.add_box,
                                'Add Category',
                                    () => _showAddCategoryDialog(context),
                              ),
                              _buildActionButton(
                                Icons.search,
                                'Search',
                                    () => _showSearchDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // totals
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: itemsStream,
                      builder: (context, snap) {
                        final totalItems =
                        snap.hasData ? snap.data!.docs.length : 0;
                        return _buildStatCard(
                            'Items', totalItems, Icons.inventory);
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: catsStream,
                      builder: (context, snap) {
                        final totalCategories =
                        snap.hasData ? snap.data!.docs.length : 0;
                        return _buildStatCard(
                            'Categories', totalCategories, Icons.category);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // shortcuts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/allItems'),
                    icon: const Icon(Icons.list),
                    label: const Text('View All Items'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/viewCategories'),
                    icon: const Icon(Icons.grid_view),
                    label: const Text('View All Categories'),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                'Last 10 Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: lastTenStream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('Error loading items: ${snap.error}'),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Text('No recent items');
                  }
                  return Column(
                    children: docs.map((d) {
                      final data = d.data();
                      final name = (data['name'] ?? '').toString();
                      final category = (data['category'] ?? '').toString();
                      final ts = data['dateAdded'];
                      String date = '';
                      if (ts is Timestamp) {
                        final dt = ts.toDate();
                        date =
                        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                      } else {
                        date = (data['dateFormatted'] ?? '').toString();
                      }
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.inventory),
                          title: Text(name),
                          subtitle: Text('Category: $category'),
                          trailing: Text(date),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/itemDetail',
                              arguments: {'id': d.id, ...data},
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // stat card
  Widget _buildStatCard(String label, int value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController _categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newCategory = _categoryController.text.trim();
                if (newCategory.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a category name')),
                  );
                  return;
                }

                final nameLower = newCategory.toLowerCase();

                try {
                  // duplicate check (case-insensitive)
                  final dup = await _catsCol
                      .where('nameLower', isEqualTo: nameLower)
                      .limit(1)
                      .get();

                  if (dup.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                          Text('Category "$newCategory" already exists')),
                    );
                    return;
                  }

                  await _catsCol.add({
                    'name': newCategory,
                    'nameLower': nameLower,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category "$newCategory" added')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add category: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // SEARCH: opens dialog, selects category (live), and pushes to /allItems with args
  void _showSearchDialog(BuildContext context) {
    final TextEditingController _searchController = TextEditingController();
    String selectedCategory = 'All';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Search Items'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name search field
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Item name (prefix)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Categories dropdown (live)
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .orderBy('nameLower')
                        .snapshots(),
                    builder: (context, snap) {
                      final names = <String>['All'];
                      if (snap.hasData) {
                        names.addAll(snap.data!.docs
                            .map((d) =>
                            (d.data()['name'] ?? '').toString().trim())
                            .where((s) => s.isNotEmpty));
                      }
                      if (!names.contains(selectedCategory)) {
                        selectedCategory = 'All';
                      }
                      return DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: names
                            .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (v) => setLocal(() {
                          selectedCategory = v ?? 'All';
                        }),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final term = _searchController.text.trim();
                    Navigator.pop(context);

                    Navigator.pushNamed(
                      context,
                      '/allItems',
                      arguments: {
                        'category': selectedCategory, // 'All' or specific
                        'searchTerm': term,           // can be empty
                      },
                    );
                  },
                  child: const Text('Search'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // reusable shortcut button
  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
