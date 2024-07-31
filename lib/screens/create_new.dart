import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';

class ImageMarkerPage extends StatefulWidget {
  @override
  _ImageMarkerPageState createState() => _ImageMarkerPageState();
}

class _ImageMarkerPageState extends State<ImageMarkerPage> {
  ui.Image? image;
  List<Marker> markers = [];
  GlobalKey imageKey = GlobalKey();
  bool isEditingExistingSvg = false;
  bool isAddingMarker = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final ui.Image loadedImage = await decodeImageFromList(imageBytes);

      setState(() {
        image = loadedImage;
        markers.clear();
      });
    }
  }

  Future<void> _loadImage() async {
    final ByteData data = await rootBundle.load('assets/default_image.png');
    image = await decodeImageFromList(data.buffer.asUint8List());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Marker')),
      body: Center(
        child: image == null
            ? CircularProgressIndicator()
            : GestureDetector(
                onTapUp: _handleTap,
                child: RepaintBoundary(
                  key: imageKey,
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: ImagePainter(image!),
                        size: Size(
                          MediaQuery.of(context).size.width,
                          MediaQuery.of(context).size.width *
                              image!.height /
                              image!.width,
                        ),
                      ),
                      ...markers.map((marker) => Positioned(
                            left: marker.offset.dx,
                            top: marker.offset.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) =>
                                  _updateMarkerPosition(marker, details),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.close,
                                      size: 15, color: Colors.white),
                                  onPressed: () => _removeMarker(marker),
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _toggleAddMarker,
            child: Icon(isAddingMarker ? Icons.close : Icons.add_location),
            heroTag: 'toggle',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _saveAsSvg,
            child: Icon(Icons.save),
            heroTag: 'save',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _loadSvg,
            child: Icon(Icons.folder_open),
            heroTag: 'load',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _pickImage,
            child: Icon(Icons.photo_library),
            heroTag: 'pickImage',
          ),
        ],
      ),
    );
  }

  void _toggleAddMarker() {
    setState(() {
      isAddingMarker = !isAddingMarker;
    });
  }

  void _handleTap(TapUpDetails details) {
    if (!isAddingMarker) return;

    final RenderBox renderBox =
        imageKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition =
        renderBox.globalToLocal(details.globalPosition);

    setState(() {
      markers.add(Marker(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        offset: localPosition,
      ));
    });

    // Debug logging
    print('Marker added at: $localPosition');
  }


  void _updateMarkerPosition(Marker marker, DragUpdateDetails details) {
    setState(() {
      final RenderBox renderBox =
          imageKey.currentContext!.findRenderObject() as RenderBox;
      final Size size = renderBox.size;
      Offset newPosition = marker.offset + details.delta;
      newPosition = Offset(
        newPosition.dx.clamp(0, size.width),
        newPosition.dy.clamp(0, size.height),
      );
      marker.offset = newPosition;
    });
  }

  void _removeMarker(Marker marker) {
    setState(() {
      markers.remove(marker);
    });
  }

  Future<String> _getDocumentsPath() async {
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      String path = directory.path.split('/Android/data').first;
      String documentsPath = '$path/Documents';
      return documentsPath;
    }
    return '';
  }

  Future<void> _saveAsSvg() async {
    final svgString = await _generateSvg();

    // Save SVG to file
    final documentsPath = await _getDocumentsPath();
    if (documentsPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get documents path!')));
      return;
    }
    final filePath = '$documentsPath/marked_image.svg';

    final file = File(filePath);
    await file.writeAsString(svgString);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved as SVG')),
    );
  }

  Future<String> _generateSvg() async {
    final double originalWidth = image!.width.toDouble();
    final double originalHeight = image!.height.toDouble();
    final double displayedWidth = MediaQuery.of(context).size.width;
    final double displayedHeight =
        displayedWidth * originalHeight / originalWidth;

    // Convert the original image to base64
    final ByteData? originalImageData =
        await image!.toByteData(format: ui.ImageByteFormat.png);
    final String base64OriginalImage =
        base64Encode(originalImageData!.buffer.asUint8List());

    // Calculate the scale factor between the displayed size and the original size
    final double scaleX = originalWidth / displayedWidth;
    final double scaleY = originalHeight / displayedHeight;

    // Define the offset to be added to the marker positions
    const double offsetX = 20.0;
    const double offsetY = 20.0;

    String svgString = '''
  <svg width="$originalWidth" height="$originalHeight" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <image xlink:href="data:image/png;base64,$base64OriginalImage" width="$originalWidth" height="$originalHeight" />
  ''';

    for (final marker in markers) {
      final double cx = (marker.offset.dx * scaleX) + offsetX;
      final double cy = (marker.offset.dy * scaleY) + offsetY;
      final double scaledRadius = 15 * scaleX; // Scale the radius of the marker

      // Debug logging
      print('Marker position: (${marker.offset.dx}, ${marker.offset.dy})');
      print('Scaled position: ($cx, $cy)');

      svgString += '''
    <circle cx="$cx" cy="$cy" r="$scaledRadius" fill="red" />
    ''';
    }

    svgString += '</svg>';
    return svgString;
  }






  Future<void> _loadSvg() async {
    final documentsPath = await _getDocumentsPath();
    if (documentsPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get documents path!')));
      return;
    }
    final filePath = '$documentsPath/marked_image.svg';
    final file = File(filePath);

    if (await file.exists()) {
      final svgContent = await file.readAsString();
      _parseSvg(svgContent);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No saved SVG file found')),
      );
    }
  }

  void _parseSvg(String svgContent) async {
    final document = XmlDocument.parse(svgContent);
    final imageElement = document.findAllElements('image').first;
    final base64Image = imageElement.getAttribute('xlink:href')!.split(',')[1];

    // Decode base64 image
    final decodedImage = base64Decode(base64Image);
    image = await decodeImageFromList(decodedImage);

    // Parse markers
    markers.clear();
    final circleElements = document.findAllElements('circle');
    final double width = image!.width.toDouble();
    final double height = image!.height.toDouble();
    final Size size = Size(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.width * height / width,
    );

    for (final circle in circleElements) {
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      final double cx = double.parse(circle.getAttribute('cx')!);
      final double cy = double.parse(circle.getAttribute('cy')!);
      final double x = (cx / width) * size.width;
      final double y = (cy / height) * size.height;
      markers.add(Marker(id: id, offset: Offset(x, y)));
    }

    setState(() {
      isEditingExistingSvg = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('SVG loaded successfully')),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      image,
      Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Marker {
  final String id;
  Offset offset;

  Marker({required this.id, required this.offset});
}
