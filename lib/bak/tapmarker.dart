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
  Offset? _tapPosition;

  void _handleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Text('Tap anywhere on the screen'),
              ),
            ),
          ),
          if (_tapPosition != null)
            Positioned(
              left: _tapPosition!.dx,
              top: _tapPosition!.dy,
              child: Icon(
                Icons.location_on,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
