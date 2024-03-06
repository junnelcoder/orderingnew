import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'config.dart'; // Import the config.dart file

class IpScreen extends StatefulWidget {
  const IpScreen({Key? key}) : super(key: key);

  @override
  _IpScreenState createState() => _IpScreenState();
}

class _IpScreenState extends State<IpScreen> {
  final TextEditingController _ipAddressController = TextEditingController(); // Controller for IP address input

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: screenHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [
                Colors.grey[900]!,
                Colors.grey[600]!,
                Colors.grey[300]!,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: screenHeight * 0.1),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GlowingText(
                      text: "IP ADDRESS",
                      glowColor: Colors.black,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenHeight * 0.05,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MaanJoy',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    GlowingText(
                      text: "Please Enter an IP address to continue",
                      glowColor: Colors.black,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenHeight * 0.025,
                        fontFamily: 'MaanJoy',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.1),
                      topRight: Radius.circular(screenWidth * 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: screenWidth * 0.02,
                        blurRadius: screenWidth * 0.04,
                        offset: Offset(0, screenWidth * 0.03),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: screenHeight * 0.1),
                        TextFormField(
                          controller: _ipAddressController, // Assign controller
                          style: TextStyle(fontFamily: 'MaanJoy'),
                          decoration: InputDecoration(
                            hintText: "Enter your IP address",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.05),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.06,
                          child: ElevatedButton(
                            onPressed: () {
                              // Get IP address from text field
                              String ipAddress = _ipAddressController.text;
                              // Set IP address in AppConfig
                              AppConfig.serverIPAddress = ipAddress;
                              // Navigate to LoginScreen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                              ),
                            ),
                            child: GlowingText(
                              text: "Confirm",
                              glowColor: Colors.black,
                              style: TextStyle(
                                fontSize: screenHeight * 0.025,
                                color: Colors.white,
                                fontFamily: 'MaanJoy',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlowingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color glowColor;

  const GlowingText({
    Key? key,
    required this.text,
    required this.style,
    required this.glowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style.copyWith(shadows: [
        Shadow(
          blurRadius: 10.0,
          color: glowColor,
          offset: const Offset(0, 0),
        ),
        Shadow(
          blurRadius: 10.0,
          color: glowColor,
          offset: const Offset(0, 0),
        ),
      ]),
    );
  }
}
