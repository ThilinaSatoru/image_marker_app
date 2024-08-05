import 'package:flutter/material.dart';
import 'svg_create_page.dart';
import 'svg_list_page.dart';
import '../widgets/custom_app_bar.dart';


class MainPage extends StatelessWidget {
  // final DatabaseHelper _databaseHelper = DatabaseHelper();
  
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
                  MaterialPageRoute(builder: (context) => SvgCreatePage()),
                );
              },
              child: Text('Create Blueprint'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SvgListPage()),
                );
              },
              child: Text('View Blueprints'),
            ),
          ],
        ),
      ),
    );
  }
}
