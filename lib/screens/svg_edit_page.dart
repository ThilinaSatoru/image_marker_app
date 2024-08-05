import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xml/xml.dart';

class SvgEditPage extends StatefulWidget {
  final int svgId;

  SvgEditPage({required this.svgId});

  @override
  _SvgEditPageState createState() => _SvgEditPageState();
}

class _SvgEditPageState extends State<SvgEditPage> {
  ui.Image? image;
  List<Marker> markers = [];
  GlobalKey imageKey = GlobalKey();
  bool isAddingMarker = false;

  static const double svg_marker_radius = 15;

  @override
  void initState() {
    super.initState();
    _loadSvgFromDatabase();
  }

  Future<void> _loadSvgFromDatabase() async {
    final svgData = await DatabaseHelper.instance.getSvgById(widget.svgId);
    if (svgData != null) {
      _parseSvg(svgData['svg_content']);
    }
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

  void _parseSvg(String svgContent) async {
    final document = XmlDocument.parse(svgContent);
    final imageElement = document.findAllElements('image').first;
    final base64Image = imageElement.getAttribute('xlink:href')!.split(',')[1];

    // Decode base64 image
    final decodedImage = base64Decode(base64Image);
    image = await decodeImageFromList(decodedImage);

    // Calculate the scale factor between the displayed size and the original size
    final double originalWidth = image!.width.toDouble();
    final double originalHeight = image!.height.toDouble();
    final double displayedWidth = MediaQuery.of(context).size.width;
    final double displayedHeight =
        displayedWidth * originalHeight / originalWidth;
    final double scaleX = originalWidth / displayedWidth;
    final double scaleY = originalHeight / displayedHeight;

    // Calculate the additional offsets based on the image size
    final Offset additionalOffsets =
        calculateAdditionalOffsets(originalWidth, originalHeight);

    // Parse markers
    markers.clear();
    final circleElements = document.findAllElements('circle');

    for (final circle in circleElements) {
      final double cx =
          double.parse(circle.getAttribute('cx')!) - additionalOffsets.dx;
      final double cy =
          double.parse(circle.getAttribute('cy')!) - additionalOffsets.dy;

      // Adjust marker position based on scale factor
      final double markerX = cx / scaleX;
      final double markerY = cy / scaleY;

      markers.add(Marker(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        offset: Offset(markerX, markerY),
      ));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit SVG')),
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
                                  color: const Color.fromARGB(171, 244, 67, 54),
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
            onPressed: _updateSvg,
            child: Icon(Icons.save),
            heroTag: 'save',
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

  Offset calculateAdditionalOffsets(double imageWidth, double imageHeight) {
    const double standardWidth = 480.0;
    const double standardHeight = 320.0;
    const double standardOffsetX = 20.0;
    const double standardOffsetY = 20.0;

    final double scaleX = imageWidth / standardWidth;
    final double scaleY = imageHeight / standardHeight;

    final double additionalOffsetX = standardOffsetX * scaleX;
    final double additionalOffsetY = standardOffsetY * scaleY;

    return Offset(additionalOffsetX, additionalOffsetY);
  }

  Future<void> _updateSvg() async {
    final svgString = await _generateSvg();

    try {
      await DatabaseHelper.instance.updateSvg(widget.svgId, svgString);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SVG updated successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating SVG: $e')),
      );
    }
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

    // Calculate the additional offsets based on the image size
    final Offset additionalOffsets =
        calculateAdditionalOffsets(originalWidth, originalHeight);

    String svgString = '''
  <svg width="$originalWidth" height="$originalHeight" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <image xlink:href="data:image/png;base64,$base64OriginalImage" width="$originalWidth" height="$originalHeight" />
  ''';

    for (final marker in markers) {
      final double cx = (marker.offset.dx * scaleX) + additionalOffsets.dx;
      final double cy = (marker.offset.dy * scaleY) + additionalOffsets.dy;

      svgString += '''
    <circle cx="$cx" cy="$cy" r="$svg_marker_radius" fill="red" fill-opacity="0.7"/>
    ''';
    }

    svgString += '</svg>';
    return svgString;
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
