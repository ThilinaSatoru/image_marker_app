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
  Size? _imageSize;
  Size? _displaySize;
  double _imageScale = 1.0; // Scaling factor for the image

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _markerDetails = []; // Clear markers when a new image is picked
        _getImageSize(_imageFile!);
      });
    }
  }

  Future<void> _getImageSize(File imageFile) async {
    final image = img.decodeImage(await imageFile.readAsBytes());
    if (image != null) {
      setState(() {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
    }
  }

  void _handleTap(TapDownDetails details) {
    if (_imageFile != null && _imageSize != null && _displaySize != null) {
      Offset tapPosition = details.localPosition;

      // Convert widget coordinates to image coordinates
      final imageWidth = _imageSize!.width * _imageScale;
      final imageHeight = _imageSize!.height * _imageScale;

      // Calculate scale factor if the image is resized
      final scaleX = imageWidth / _displaySize!.width;
      final scaleY = imageHeight / _displaySize!.height;

      Offset imageTapPosition =
          Offset(tapPosition.dx * scaleX, tapPosition.dy * scaleY);

      bool isMarkerRemoved = false;
      for (int i = 0; i < _markerDetails.length; i++) {
        final marker = _markerDetails[i];
        final markerOffset = Offset(marker['x'], marker['y']);
        if ((markerOffset - imageTapPosition).distance < 20.0) {
          setState(() {
            _markerDetails.removeAt(i);
          });
          isMarkerRemoved = true;
          break;
        }
      }

      if (!isMarkerRemoved) {
        _showMarkerDialog(imageTapPosition);
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
                              'x': tapPosition.dx /
                                  _imageScale, // Adjust for scaling
                              'y': tapPosition.dy /
                                  _imageScale, // Adjust for scaling
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

    final documentsPath = await getDocumentsPath();
    if (documentsPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get documents path!')));
      return;
    }
    final path = '$documentsPath/image_with_markers.svg';

    // Read the image as base64
    final imageBytes = await _imageFile!.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final svgContent = '''
<svg width="${_imageSize?.width}" height="${_imageSize?.height}" xmlns="http://www.w3.org/2000/svg">
  <image href="data:image/png;base64,$base64Image" x="0" y="0" width="${_imageSize?.width}" height="${_imageSize?.height}" />
  ${_markerDetails.map((marker) {
      final icon = marker['icon'];
      final color = marker['color'];
      final name = marker['name'];
      final x = marker['x'] * _imageScale; // Apply scaling
      final y = marker['y'] * _imageScale; // Apply scaling

      return '''
    <circle cx="$x" cy="$y" r="10" fill="$color" />
    <text x="$x" y="${y - 15}" font-size="10" text-anchor="middle" fill="black">$name</text>
    ''';
    }).join()}
</svg>
''';

    final file = File(path);
    await file.writeAsString(svgContent);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('SVG saved to $path')));
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          _displaySize = Size(constraints.maxWidth, constraints.maxHeight);

          return GestureDetector(
            onTapDown: _handleTap,
            child: Stack(
              children: <Widget>[
                if (_imageFile != null)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Image.file(
                        _imageFile!,
                        width: _displaySize?.width,
                        height: _displaySize?.height,
                      ),
                    ),
                  )
                else
                  Center(child: Text('No image selected')),
                ..._markerDetails.map((marker) {
                  final scaledX = marker['x'] * _imageScale;
                  final scaledY = marker['y'] * _imageScale;

                  return Positioned(
                    left: scaledX,
                    top: scaledY,
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
                              style:
                                  TextStyle(fontSize: 12, color: Colors.black),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
