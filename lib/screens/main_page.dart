import 'package:flutter/material.dart';
import 'create_new.dart';
import 'view_markers_page.dart';
import '../widgets/custom_app_bar.dart';

class MainPage extends StatelessWidget {
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
                  MaterialPageRoute(builder: (context) => CreateNew()),
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
          ],
        ),
      ),
    );
  }
}
