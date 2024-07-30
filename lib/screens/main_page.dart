import 'package:flutter/material.dart';
import 'create_new.dart';
import 'view_markers_page.dart';
import '../widgets/custom_app_bar.dart';
import '../services/database_helper.dart';

class MainPage extends StatelessWidget {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Main Page'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImageMarkerPage()),
                );
              },
              child: Text('Tap Position Example'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewMarkersPage()),
                );
              },
              child: Text('View Saved Markers'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Clear the database
                await _databaseHelper.clearDatabase();

                // Show a confirmation message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Database cleared')),
                );
              },
              child: Text('Clear Database'),
            ),
          ],
        ),
      ),
    );
  }
}
