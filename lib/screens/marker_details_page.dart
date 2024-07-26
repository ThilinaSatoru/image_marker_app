import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/database_helper.dart';

class MarkerDetailsPage extends StatefulWidget {
  final int itemId;

  MarkerDetailsPage({required this.itemId});

  @override
  _MarkerDetailsPageState createState() => _MarkerDetailsPageState();
}

class _MarkerDetailsPageState extends State<MarkerDetailsPage> {
  List<Map<String, dynamic>> _markerDetails = [];
  File? _imageFile;
  bool _isEditing = false;
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final item = await _databaseHelper.getItem(widget.itemId);
      if (item != null) {
        setState(() {
          _imageFile = File(item['imagePath']);
        });

        final markers = await _databaseHelper.getMarkersForItem(widget.itemId);
        setState(() {
          _markerDetails = List<Map<String, dynamic>>.from(markers);
        });
      } else {
        setState(() {
          _imageFile = null;
          _markerDetails = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _handleTap(TapDownDetails details) {
    if (_isEditing) {
      Offset tapPosition = details.localPosition;

      setState(() {
        bool isMarkerRemoved = false;

        List<Map<String, dynamic>> updatedMarkers = List.from(_markerDetails);

        for (int i = updatedMarkers.length - 1; i >= 0; i--) {
          final marker = updatedMarkers[i];
          final markerOffset = Offset(marker['x'], marker['y']);
          if ((markerOffset - tapPosition).distance < 20.0) {
            updatedMarkers.removeAt(i);
            isMarkerRemoved = true;
            break;
          }
        }

        if (!isMarkerRemoved) {
          _showMarkerDialog(tapPosition);
        } else {
          _markerDetails = updatedMarkers;
        }
      });
    }
  }

  Future<void> _showMarkerDialog(Offset tapPosition) async {
    String? markerName;
    String markerIcon = 'location_on';
    String markerColor = 'red';

    await showDialog(
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
                          Navigator.of(context).pop(); // Close the dialog
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
      // Refresh the widget tree after the dialog closes
      setState(() {});
    });
  }


  Future<void> _saveChanges() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
      return;
    }

    try {
      await _databaseHelper.updateMarker(
        widget.itemId,
        _imageFile!.path,
        _markerDetails,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes saved!')),
      );
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageFile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Marker Details'),
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: () {
                setState(() {
                  if (_isEditing) {
                    _saveChanges();
                  }
                  _isEditing = !_isEditing;
                });
              },
            ),
          ],
        ),
        body: Center(child: Text('No image available')),
        floatingActionButton: _isEditing
            ? FloatingActionButton(
                onPressed: _pickImage,
                child: Icon(Icons.add_a_photo),
              )
            : null,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Marker Details'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _saveChanges();
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTapDown: _handleTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(
                _imageFile!,
                fit: BoxFit.cover,
              ),
            ),
            for (var marker in _markerDetails)
              Stack(
                children: [
                  Positioned(
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
                      size: 24, // Adjust the size of the icon as needed
                    ),
                  ),
                  Positioned(
                    left: marker['x'] - 10, // Adjust as needed
                    top: marker['y'] - 20, // Adjust as needed
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
          ],
        ),
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: _pickImage,
              child: Icon(Icons.add_a_photo),
            )
          : null,
    );
  }
}
