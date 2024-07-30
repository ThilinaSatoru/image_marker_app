import 'package:flutter/material.dart';

class ImageCanvas extends StatefulWidget {
  @override
  _ImageCanvasState createState() => _ImageCanvasState();
}

class _ImageCanvasState extends State<ImageCanvas> {
  List<Marker> markers = [];
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Canvas')),
      body: GestureDetector(
        onTapUp: (TapUpDetails details) {
          setState(() {
            markers.add(Marker(position: details.localPosition));
          });
        },
        child: Stack(
          key: _imageKey,
          children: [
            Image.asset('assets/default_image.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity),
            ...markers.map((marker) => Positioned(
                  left: marker.position.dx, // Adjust for icon size
                  top: marker.position.dy, // Adjust for icon size
                  child: Draggable(
                    feedback:
                        Icon(Icons.location_on, color: Colors.red, size: 40),
                    child: Icon(Icons.location_on, color: Colors.red, size: 40),
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            markers.add(Marker(position: Offset(100, 100)));
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Marker {
  Offset position;
  Marker({required this.position});
}
