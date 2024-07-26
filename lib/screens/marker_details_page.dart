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
          updatedMarkers.add({
            'x': tapPosition.dx,
            'y': tapPosition.dy,
            'name': 'New Marker',
            'icon': 'location_on',
            'color': 'red',
          });
        }

        _markerDetails = updatedMarkers;
      });
    }
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
              Positioned(
                left: marker['x'],
                top: marker['y'],
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                ),
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
