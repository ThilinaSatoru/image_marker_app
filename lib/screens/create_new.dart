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
        setState(() {
          _markerDetails.add({
            'x': tapPosition.dx,
            'y': tapPosition.dy,
            'name': 'New Marker',
            'icon': 'location_on',
            'color': 'red',
          });
        });
      }
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
