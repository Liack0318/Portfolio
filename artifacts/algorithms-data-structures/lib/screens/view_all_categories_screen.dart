import 'package:flutter/material.dart';

class ViewAllCategoriesScreen extends StatelessWidget {
  // Example data for now
  final List<Map<String, dynamic>> categories = [
    {'name': 'Electronics', 'count': 5, 'color': Colors.blue},
    {'name': 'Clothing', 'count': 8, 'color': Colors.green},
    {'name': 'Books', 'count': 3, 'color': Colors.orange},
    {'name': 'Furniture', 'count': 2, 'color': Colors.purple},
    {'name': 'Other', 'count': 10, 'color': Colors.red},
  ];

  ViewAllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Add edit categories action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Categories coming soon')),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 tiles per row
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/allItems',
                  arguments: {'category': category['name']},
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: category['color'],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${category['count']} items',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
