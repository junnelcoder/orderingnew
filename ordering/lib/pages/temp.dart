import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showButtons = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Animated Buttons'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main Circle Button
            GestureDetector(
              onTap: () {
                setState(() {
                  _showButtons = !_showButtons;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _showButtons ? 150 : 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(_showButtons ? 30 : 50),
                ),
                child: _showButtons
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Button 1
                          AnimatedOpacity(
                            duration: Duration(milliseconds: 300),
                            opacity: _showButtons ? 1.0 : 0.0,
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text('Button 1'),
                            ),
                          ),
                          // Button 2
                          AnimatedOpacity(
                            duration: Duration(milliseconds: 300),
                            opacity: _showButtons ? 1.0 : 0.0,
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text('Button 2'),
                            ),
                          ),
                          // Button 3
                          AnimatedOpacity(
                            duration: Duration(milliseconds: 300),
                            opacity: _showButtons ? 1.0 : 0.0,
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text('Button 3'),
                            ),
                          ),
                        ],
                      )
                    : Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}
