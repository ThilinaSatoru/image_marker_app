import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Tap Position Example'),
        ),
        body: TapPositionExample(),
      ),
    );
  }
}

class TapPositionExample extends StatefulWidget {
  @override
  _TapPositionExampleState createState() => _TapPositionExampleState();
}

class _TapPositionExampleState extends State<TapPositionExample> {
  List<Offset> _markerPositions = [];

  void _handleTap(TapDownDetails details) {
    Offset tapPosition = details.localPosition;

    // Check if the tap is on an existing marker
    bool isMarkerRemoved = false;
    for (int i = 0; i < _markerPositions.length; i++) {
      if ((_markerPositions[i] - tapPosition).distance < 20.0) {
        setState(() {
          _markerPositions.removeAt(i);
        });
        isMarkerRemoved = true;
        break;
      }
    }

    // If no marker was removed, add a new marker
    if (!isMarkerRemoved) {
      setState(() {
        _markerPositions.add(tapPosition);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'assets/room1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          for (Offset position in _markerPositions)
            Positioned(
              left: position.dx,
              top: position.dy,
              child: Icon(
                Icons.location_on,
                color: Color.fromARGB(255, 255, 0, 0),
              ),
            ),
        ],
      ),
    );
  }
}
