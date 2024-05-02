import 'package:flutter/material.dart';

class BackButtonPage extends StatelessWidget {
  final Widget child;

  const BackButtonPage({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Check if current page is HomePage, if not, navigate back to HomePage
        if (ModalRoute.of(context)?.settings.name != '/') {
          Navigator.popUntil(context, ModalRoute.withName('/'));
          return false; // Prevent default back button behavior
        }
        return true; // Allow default back button behavior on HomePage
      },
      child: child,
    );
  }
}
