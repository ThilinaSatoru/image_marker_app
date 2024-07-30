import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class ImageMarkerPage extends StatefulWidget {
  @override
  _ImageMarkerPageState createState() => _ImageMarkerPageState();
}

class _ImageMarkerPageState extends State<ImageMarkerPage> {
  ui.Image? image;
  List<Offset> markers = [];
  GlobalKey imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
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
                  child: CustomPaint(
                    painter: ImageMarkerPainter(image!, markers),
                    size: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.width *
                          image!.height /
                          image!.width,
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveAsSvg,
        child: Icon(Icons.save),
      ),
    );
  }

  void _handleTap(TapUpDetails details) {
    final RenderBox renderBox =
        imageKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition =
        renderBox.globalToLocal(details.globalPosition);
    final Size imageSize = renderBox.size;
    final double scale = imageSize.width / image!.width;

    setState(() {
      markers.add(Offset(
        localPosition.dx / scale,
        localPosition.dy / scale,
      ));
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
    final RenderRepaintBoundary boundary =
        imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image renderedImage = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData =
        await renderedImage.toByteData(format: ui.ImageByteFormat.png);
    final String base64Image = base64Encode(byteData!.buffer.asUint8List());

    final double width = MediaQuery.of(context).size.width;
    final double height = width * image!.height / image!.width;

    String svgString = '''
    <svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
      <image xlink:href="data:image/png;base64,$base64Image" width="$width" height="$height" />
    ''';

    final double scale = width / image!.width;
    for (final marker in markers) {
      final double cx = marker.dx * scale;
      final double cy = marker.dy * scale;
      svgString += '''
      <circle cx="$cx" cy="$cy" r="5" fill="red" />
      ''';
    }

    svgString += '</svg>';
    return svgString;
  }
}

class ImageMarkerPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> markers;

  ImageMarkerPainter(this.image, this.markers);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      image,
      Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    final markerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final scale = size.width / image.width;
    for (final marker in markers) {
      canvas.drawCircle(
        Offset(marker.dx * scale, marker.dy * scale),
        5,
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
