import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

class SvgViewerPage extends StatelessWidget {
  final String svgContent;

  SvgViewerPage({required this.svgContent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SVG Preview'),
      ),
      body: SvgPreview(svgContent: svgContent),
    );
  }
}

class SvgPreview extends StatelessWidget {
  final String svgContent;

  SvgPreview({required this.svgContent});

  @override
  Widget build(BuildContext context) {
    try {
      // Parse the SVG content
      final document = XmlDocument.parse(svgContent);
      final svgElement = document.rootElement;

      // Extract width and height
      final width = double.parse(svgElement.getAttribute('width') ?? '100');
      final height = double.parse(svgElement.getAttribute('height') ?? '100');

      return InteractiveViewer(
        boundaryMargin: EdgeInsets.all(20),
        minScale: 0.1,
        maxScale: 4,
        child: Center(
          child: AspectRatio(
            aspectRatio: width / height,
            child: SvgPicture.string(
              svgContent,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Text('Error loading SVG: $e'),
      );
    }
  }
}
