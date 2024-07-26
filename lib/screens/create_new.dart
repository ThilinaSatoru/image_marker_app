import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
                            print(
                                'Added marker: $_markerDetails'); // Debug line
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
    );
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
                child: Icon(
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
