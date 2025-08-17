import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AllItemsScreen extends StatefulWidget {
  const AllItemsScreen({Key? key}) : super(key: key);

  @override
  State<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends State<AllItemsScreen> {
  String _selectedCategory = 'All';
  String _searchTermLower = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args.containsKey('category')) {
        _selectedCategory = (args['category'] as String).trim();
      }
      if (args.containsKey('searchTerm')) {
        _searchTermLower =
            (args['searchTerm'] as String).trim().toLowerCase();
      }
      setState(() {});
    }
  }

  // builds the Firestore query based on selected category and search term
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q =
    FirebaseFirestore.instance.collection('items');

    // (optional) scope to the current user if you save ownerUid on items
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      q = q.where('ownerUid', isEqualTo: uid);
    }

    // category filter (use normalized field)
    if (_selectedCategory != 'All') {
      q = q.where('categoryLower',
          isEqualTo: _selectedCategory.toLowerCase());
    }

    // text prefix search on nameLower if provided
    if (_searchTermLower.isNotEmpty) {
      final end = '$_searchTermLower\uf8ff';
      q = q
          .orderBy('nameLower') // required for range filters
          .where('nameLower', isGreaterThanOrEqualTo: _searchTermLower)
          .where('nameLower', isLessThanOrEqualTo: end);
    } else {
      // default ordering
      q = q.orderBy('dateAdded');
    }
    return q;
  }

  @override
  Widget build(BuildContext context) {
    final hasSearch = _searchTermLower.isNotEmpty;
    final label = (_selectedCategory == 'All')
        ? 'All Items'
        : 'Items • ${_selectedCategory}';
    final sub = hasSearch ? 'Search: ${_searchTermLower}' : null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            if (sub != null)
              Text(
                sub,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white70),
              ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _buildQuery().snapshots(),
          builder: (context, snapshot) {
            // error state
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading items: ${snapshot.error}'));
            }
            // loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // empty state
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No items found'));
            }

            final docs = snapshot.data!.docs;

            return GridView.builder(
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // two items per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0, // make each tile square
              ),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();

                final name = (data['name'] ?? '').toString();
                final qty = data['quantity'];
                final imageUrl = (data['imageUrl'] ?? '').toString();

                final priceVal = data['price'];
                final String priceText =
                priceVal == null ? '' : '\$${priceVal.toString()}';

                return GestureDetector(
                  onTap: () {
                    // go to item detail (we pass id + fields together)
                    Navigator.pushNamed(
                      context,
                      '/itemDetail',
                      arguments: {'id': doc.id, ...data},
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // image area (square)
                        Positioned.fill(
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image,
                                  size: 48, color: Colors.grey),
                            ),
                          )
                              : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image,
                                  size: 64, color: Colors.grey),
                            ),
                          ),
                        ),

                        // bottom overlay with name, quantity, and price (if any)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.65),
                                  Colors.black.withOpacity(0.15),
                                ],
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // name and qty on the left
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Qty: ${qty ?? '-'}',
                                        style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.9)),
                                      ),
                                    ],
                                  ),
                                ),
                                // price on the right (only if present)
                                if (priceText.isNotEmpty)
                                  Text(
                                    priceText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
