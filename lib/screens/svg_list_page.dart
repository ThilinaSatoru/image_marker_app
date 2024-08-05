import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'svg_edit_page.dart';
import 'svg_viewer.dart';

class SvgListPage extends StatefulWidget {
  @override
  _SvgListPageState createState() => _SvgListPageState();
}

class _SvgListPageState extends State<SvgListPage> {
  List<Map<String, dynamic>> _svgList = [];

  @override
  void initState() {
    super.initState();
    _loadSvgList();
  }

  Future<void> _loadSvgList() async {
    final svgList = await DatabaseHelper.instance.getSvgList();
    setState(() {
      _svgList = svgList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved SVGs'),
      ),
      body: ListView.builder(
        itemCount: _svgList.length,
        itemBuilder: (context, index) {
          final svg = _svgList[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text('SVG #${svg['id']}'),
              subtitle: Text('Created at: ${svg['created_at']}'),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SvgEditPage(svgId: svg['id']),
                  ),
                );
                if (result == true) {
                  // Refresh the list if the SVG was updated
                  _loadSvgList();
                }
              },
              trailing: IconButton(
                icon: Icon(Icons.visibility),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SvgViewerPage(
                        svgContent: svg['svg_content'],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
