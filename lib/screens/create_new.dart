import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io';
import '../services/database_helper.dart';

class CreateNew extends StatefulWidget {
  @override
  _CreateNewState createState() => _CreateNewState();
}

class _CreateNewState extends State<CreateNew> {
  List<Map<String, dynamic>> _markerDetails = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  File? _imageFile;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _markerDetails = []; // Clear markers when a new image is picked
      });
    }
  }

  void _handleTap(TapDownDetails details) {
    if (_imageFile != null) {
      Offset tapPosition = details.localPosition;

      bool isMarkerRemoved = false;
      for (int i = 0; i < _markerDetails.length; i++) {
        final marker = _markerDetails[i];
        final markerOffset = Offset(marker['x'], marker['y']);
        if ((markerOffset - tapPosition).distance < 20.0) {
          setState(() {
            _markerDetails.removeAt(i);
          });
          isMarkerRemoved = true;
          break;
        }
      }

      if (!isMarkerRemoved) {
        _showMarkerDialog(tapPosition);
      }
    }
  }

  void _showMarkerDialog(Offset tapPosition) {
    String? markerName;
    String markerIcon = 'location_on';
    String markerColor = 'red';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(labelText: 'Marker Name'),
                        onChanged: (value) {
                          markerName = value;
                        },
                      ),
                      DropdownButton<String>(
                        value: markerIcon,
                        onChanged: (String? newValue) {
                          setState(() {
                            markerIcon = newValue!;
                          });
                        },
                        items: <String>['location_on', 'place', 'star', 'flag']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      DropdownButton<String>(
                        value: markerColor,
                        onChanged: (String? newValue) {
                          setState(() {
                            markerColor = newValue!;
                          });
                        },
                        items: <String>['red', 'blue', 'green', 'yellow']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _markerDetails.add({
                              'x': tapPosition.dx,
                              'y': tapPosition.dy,
                              'name': markerName ?? 'New Marker',
                              'icon': markerIcon,
                              'color': markerColor,
                            });
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text('Add Marker'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      // Ensure the UI updates after closing the dialog
      setState(() {});
    });
  }

  void _saveMarkers() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No image selected!')));
      return;
    }

    // Insert item and get its ID
    final itemId = await _databaseHelper.insertItem(_imageFile!.path);

    // Use the itemId to insert markers
    await _databaseHelper.insertMarker(itemId, _markerDetails);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Markers saved!')));
  }

  Future<String> getDocumentsPath() async {
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      String path = directory.path.split('/Android/data').first;
      String documentsPath = '$path/Documents';
      return documentsPath;
    }
    return '';
  }

  Future<void> _saveAsSvg() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No image selected!')));
      return;
    }

    final sharedPath = await getDocumentsPath();
    // final directory = await getApplicationDocumentsDirectory();
    final path = '${sharedPath}/image_with_markers.svg';
    print('Svg path: $path');

    // Read the image and convert it to base64
    final imageBytes = await _imageFile!.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final svgContent = StringBuffer();
    svgContent
        .writeln('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">');
    svgContent.writeln(
        '<image href="data:image/png;base64,$base64Image" width="100%" height="100%"/>');

    for (var marker in _markerDetails) {
      final x = marker['x'];
      final y = marker['y'];
      final name = marker['name'] ?? 'Unnamed';
      final icon = marker['icon'];
      final color = marker['color'];

      final iconSvg = _getIconSvg(icon);
      svgContent.writeln('<g transform="translate($x, $y)">');
      svgContent.writeln(
          '<text x="0" y="-10" fill="black" font-size="12">$name</text>');
      svgContent.writeln('<g fill="$color">$iconSvg</g>');
      svgContent.writeln('</g>');
    }

    svgContent.writeln('</svg>');

    final file = File(path);
    await file.writeAsString(svgContent.toString());

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('SVG saved at $path')));
  }

  String _getIconSvg(String icon) {
    switch (icon) {
      case 'place':
        return '<path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5S10.62 6.5 12 6.5s2.5 1.12 2.5 2.5S13.38 11.5 12 11.5z"/>';
      case 'star':
        return '<path d="M12 17.27L18.18 21 16.54 14.27 22 9.24 15.81 8.63 12 2 8.19 8.63 2 9.24 7.46 14.27 5.82 21z"/>';
      case 'flag':
        return '<path d="M14.4 6l.6 2H8v9H6V4h8l-1.6 2H18v2z"/>';
      default:
        return '<path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5S10.62 6.5 12 6.5s2.5 1.12 2.5 2.5S13.38 11.5 12 11.5z"/>';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Markers'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveMarkers,
          ),
          IconButton(
            icon: Icon(Icons.save_alt),
            onPressed: _saveAsSvg,
          ),
        ],
      ),
      body: GestureDetector(
        onTapDown: _handleTap,
        child: Stack(
          children: <Widget>[
            if (_imageFile != null)
              Positioned.fill(
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                ),
              )
            else
              Center(child: Text('No image selected')),
            ..._markerDetails.map((marker) {
              return Positioned(
                left: marker['x'],
                top: marker['y'],
                child: Stack(
                  children: [
                    Icon(
                      marker['icon'] == 'place'
                          ? Icons.place
                          : marker['icon'] == 'star'
                              ? Icons.star
                              : marker['icon'] == 'flag'
                                  ? Icons.flag
                                  : Icons.location_on,
                      color: marker['color'] == 'red'
                          ? Colors.red
                          : marker['color'] == 'blue'
                              ? Colors.blue
                              : marker['color'] == 'green'
                                  ? Colors.green
                                  : marker['color'] == 'yellow'
                                      ? Colors.yellow
                                      : Colors.red,
                    ),
                    Positioned(
                      left: -20, // Adjust as needed
                      top: -30, // Adjust as needed
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        color: Colors.white,
                        child: Text(
                          marker['name'] ?? 'Unnamed',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
