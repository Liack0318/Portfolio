import 'package:flutter/material.dart';

// This screen after login. It shows a welcome message, stats, and shortcuts.
class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample data just to display for now
    final int totalItems = 52;
    final int totalCategories = 7;

    // Fake list of the 10 most recent items
    final List<Map<String, String>> lastItems = List.generate(
      10,
          (i) =>
      {
        'name': 'Item ${i + 1}',
        'category': 'Category ${(i % 3) + 1}',
        'date': '2025-07-${(20 - i).toString().padLeft(2, '0')}',
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top blue area with backgroun image and shortcut buttons
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
                    // White transparent overlay for visibility
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    // Content inside blue box
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
                              // Add item button
                              _buildActionButton(
                                Icons.add,
                                'Add Item',
                                    () {
                                  Navigator.pushNamed(context, '/addItem');
                                },
                              ),
                              // Add category button
                              _buildActionButton(
                                Icons.add_box,
                                'Add Category',
                                    () => _showAddCategoryDialog(context),
                              ),
                              // Search button
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

              // Row showing total items and total categories
              Row(
                children: [
                  _buildStatCard('Items', totalItems, Icons.inventory),
                  const SizedBox(width: 20),
                  _buildStatCard('Categories', totalCategories, Icons.category),
                ],
              ),

              const SizedBox(height: 30),

              // Buttons to view all items and categories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/allItems');
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('View All Items'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/viewCategories');
                    },
                    icon: const Icon(Icons.grid_view),
                    label: const Text('View All Categories'),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Title for recet items list
              const Text(
                'Last 10 Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              // List of Item Cards
              Column(
                children: lastItems.map((item) {
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.inventory),
                      title: Text(item['name']!),
                      subtitle: Text('Category: ${item['category']}'),
                      trailing: Text(item['date']!),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Box showing number card and icon
  Widget _buildStatCard(String label, int value, IconData icon) {
    return Expanded(
      child: Card(
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
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(label),
            ],
          ),
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
              onPressed: () {
                String newCategory = _categoryController.text.trim();
                if (newCategory.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category "$newCategory" added')),
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

  void _showSearchDialog(BuildContext context) {
    final TextEditingController _searchController = TextEditingController();
    final List<String> categories = [
      'All Categories', 'Electronics', 'Clothing', 'Books', 'Other'
    ];
    String selectedCategory = 'All Categories';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name search field
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Dropdown for category
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(),
                ),
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
                final searchTerm = _searchController.text.trim();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Searching "$searchTerm" in $selectedCategory'),
                  ),
                );

                // TODO: Add actual search logic here later
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }


  // Reusable shortcut button
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(height: 6),
          Text(
              label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}


