import 'dart:async';
import 'dart:typed_data'; // For Uint8List
import 'dart:convert'; // For base64 encoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class ImageCanvas extends StatefulWidget {
  @override
  _ImageCanvasState createState() => _ImageCanvasState();
}

class _ImageCanvasState extends State<ImageCanvas> {
  List<Marker> markers = [];
  final GlobalKey _imageKey = GlobalKey();
  Size? _imageSize;
  final double markerRadius = 10; // Marker radius in pixels
  final String imagePath = 'assets/default_image.png';
  late Size originalImageSize;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final Image image = Image.asset(imagePath);
    final Completer<Size> completer = Completer();
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()));
      }),
    );
    originalImageSize = await completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Canvas'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _imageSize != null
                ? _saveAsSVG
                : null, // Ensure _imageSize is not null
          ),
        ],
      ),
      body: GestureDetector(
        onTapUp: (TapUpDetails details) {
          setState(() {
            markers.add(Marker(position: details.localPosition));
          });
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              key: _imageKey,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  width: constraints.maxWidth,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame != null && _imageSize == null) {
                      WidgetsBinding.instance!.addPostFrameCallback((_) {
                        final RenderBox renderBox =
                            context.findRenderObject() as RenderBox;
                        setState(() {
                          _imageSize = renderBox.size;
                        });
                      });
                    }
                    return child;
                  },
                ),
                ...markers.map((marker) => Positioned(
                      left: marker.position.dx -
                          markerRadius, // Adjust for icon size
                      top: marker.position.dy -
                          markerRadius, // Adjust for icon size
                      child: Draggable(
                        feedback: Icon(Icons.location_on,
                            color: Colors.red, size: 40),
                        child: Icon(Icons.location_on,
                            color: Colors.red, size: 40),
                        childWhenDragging: Container(),
                        onDragEnd: (details) {
                          setState(() {
                            // Convert global position to local position
                            RenderBox renderBox = _imageKey.currentContext!
                                .findRenderObject() as RenderBox;
                            Offset localOffset =
                                renderBox.globalToLocal(details.offset);
                            marker.position = localOffset;
                          });
                        },
                      ),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<String> _loadImageAsBase64() async {
    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List bytes = data.buffer.asUint8List();
    return 'data:image/png;base64,' + base64Encode(bytes);
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

  Future<void> _saveAsSVG() async {
    if (_imageSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image size is not available!')));
      return;
    }

    final svgString = await _generateSVG();

    // Save SVG to file
    final documentsPath = await _getDocumentsPath();
    if (documentsPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get documents path!')));
      return;
    }
    final filePath = '$documentsPath/combined_image.svg';

    final file = File(filePath);
    await file.writeAsString(svgString);

    print('SVG saved to $filePath');

    // Notify the user
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('SVG saved to $filePath')));
  }

  Future<String> _generateSVG() async {
    final base64Image = await _loadImageAsBase64();
    final imageWidth = originalImageSize.width;
    final imageHeight = originalImageSize.height;

    final svgHeader = '''
<svg width="$imageWidth" height="$imageHeight" xmlns="http://www.w3.org/2000/svg">
  <image href="$base64Image" x="0" y="0" width="$imageWidth" height="$imageHeight" />
''';

    final scaleX = imageWidth / (_imageSize?.width ?? imageWidth);
    final scaleY = imageHeight / (_imageSize?.height ?? imageHeight);

    final svgMarkers = markers.map((marker) {
      final scaledX = marker.position.dx * scaleX;
      final scaledY = marker.position.dy * scaleY;
      return '''
    <circle cx="$scaledX" cy="$scaledY" r="$markerRadius" fill="red" />
''';
    }).join();

    final svgFooter = '''
</svg>
''';

    return svgHeader + svgMarkers + svgFooter;
  }
}

class Marker {
  Offset position;
  Marker({required this.position});
}
