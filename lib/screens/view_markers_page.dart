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

  @override
  void initState() {
    super.initState();
    _items = _databaseHelper.getItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Items'),
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

              return Card(
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
                    ListTile(
                      title: Text('Item ID: $id'),
                      subtitle: Text('Image Path: $imagePath'),
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
                    ),
                  ],
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
