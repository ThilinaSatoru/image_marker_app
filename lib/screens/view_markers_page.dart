import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'marker_details_page.dart';
import 'dart:io';

class ViewMarkersPage extends StatefulWidget {
  @override
  _ViewMarkersPageState createState() => _ViewMarkersPageState();
}

class _ViewMarkersPageState extends State<ViewMarkersPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _items;
  int? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _items = _databaseHelper.getItems();
  }

  void _deleteItem() async {
    if (_selectedItemId != null) {
      try {
        await _databaseHelper.deleteItem(_selectedItemId!);
        setState(() {
          _items = _databaseHelper.getItems();
          _selectedItemId = null; // Reset selected item
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Items'),
        actions: [
          if (_selectedItemId != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteItem,
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Database Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No items found.'));
          }

          final items = snapshot.data!;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final id = item['id'] as int;
              final imagePath =
                  item['imagePath'] as String? ?? 'Default Image Path';

              return GestureDetector(
                onLongPress: () {
                  setState(() {
                    _selectedItemId = id; // Set the selected item ID
                  });
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarkerDetailsPage(itemId: id),
                    ),
                  ).then((_) {
                    // Refresh items after returning from MarkerDetailsPage
                    setState(() {
                      _items = _databaseHelper.getItems();
                    });
                  });
                },
                child: Card(
                  margin: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: _getImageProvider(imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Item ID: $id',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _databaseHelper.getMarkersForItem(id),
                          builder: (context, markerSnapshot) {
                            if (markerSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text('Loading markers...');
                            } else if (markerSnapshot.hasError) {
                              return Text('Error loading markers');
                            } else if (!markerSnapshot.hasData ||
                                markerSnapshot.data!.isEmpty) {
                              return Text('No markers');
                            }

                            final markers = markerSnapshot.data!;
                            final markerNames = markers
                                .map((marker) => marker['name'])
                                .join(', ');

                            return Text(
                              'Markers: $markerNames',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey[700],
                              ),
                            );
                          },
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
    );
  }

  ImageProvider _getImageProvider(String imagePath) {
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        return AssetImage(
            'assets/default_image.png'); // Provide a default image
      }
    } catch (e) {
      // Log error and return default image
      print('Error loading image: $e');
      return AssetImage('assets/default_image.png'); // Provide a default image
    }
  }
}
