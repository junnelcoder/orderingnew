import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class IpScreen extends StatefulWidget {
  const IpScreen({Key? key}) : super(key: key);

  @override
  _IpScreenState createState() => _IpScreenState();
}

class _IpScreenState extends State<IpScreen> {
  DateTime? currentBackPressTime;
  late List<String> authorizedDeviceIds = [];
  bool isLoading = false;
  final String _encryptionKey = 'my32lengthsupersecretnooneknows1';

  @override
  void initState() {
    super.initState();
    getSavedIpAddress();
    fetchCategories();
    currentBackPressTime = null;
    loadAuthorizedDeviceIds(); // Load authorized device IDs
    getDeviceId().then((deviceId) {
      print('Device ID: $deviceId');
      if (!authorizedDeviceIds.contains(deviceId)) {
        // Device is not authorized
        Fluttertoast.showToast(
          msg: "Device is not authorized",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 7,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        // Delay exiting the app by 3 seconds after showing the toast
        Future.delayed(Duration(milliseconds: 250), () {
          exit(0); // Exit the app
        });
      }
    });
  }

  void loadAuthorizedDeviceIds() async {
    try {
      String data = await rootBundle.loadString('authorized_device_ids.json');

      Map<String, dynamic> jsonData = jsonDecode(data);
      List<dynamic> encryptedDeviceIds = jsonData['authorizedDeviceIds'];

      // Decrypt each encrypted device ID
      List<String> decryptedDeviceIds = encryptedDeviceIds.map((encryptedId) {
        return _decryptFernet(encryptedId);
      }).toList();

      authorizedDeviceIds = decryptedDeviceIds;

      print('Authorized Device IDs: $authorizedDeviceIds');
    } catch (e) {
      print('Error loading authorized device IDs: $e');
    }
  }

  String _decryptFernet(String encryptedDeviceId) {
    final keyBytes = utf8.encode(_encryptionKey); // Convert key to bytes
    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(encrypt.Fernet(key));

    // Add padding to the encrypted value if needed
    final paddedEncryptedDeviceId =
        encryptedDeviceId.padRight((encryptedDeviceId.length + 3) & ~3, '=');

    final decrypted = encrypter.decrypt64(paddedEncryptedDeviceId);
    return decrypted;
  }

  void getSavedIpAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');

    if (ipAddress != null) {
      setState(() {
        _ipAddressController.text = ipAddress;
      });
    }
  }

  Future<void> fetchCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    if (ipAddress != null) {
      try {
        final response = await http
            .get(Uri.parse(
                'http://$ipAddress:${AppConfig.serverPort}/api/ipConn'))
            .timeout(Duration(seconds: 5));
        if (response.statusCode == 200) {
          String serverResponse = response.body;
          print('Server response: $serverResponse');
          AppConfig.serverIPAddress = ipAddress;
          bool? getBackBool = prefs.getBool('backToIP');
          if (getBackBool != null && getBackBool) {
            await prefs.setBool('backToIP', false);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(),
              ),
            );
          }
        } else {
          await prefs.setBool('backToIP', false);
          Fluttertoast.showToast(
            msg: "Server is Down",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 7,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } catch (e) {
        await prefs.remove('ipAddress');
        print('Error connecting to server: $e');
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(
          msg: "Invalid Ip Address",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: const Color.fromARGB(255, 112, 109, 109),
          textColor: const Color.fromARGB(255, 0, 0, 0),
          fontSize: 16.0,
        );
      }
    } else {
      print('IP Address not found in SharedPreferences');
    }
  }

  Future<String> getDeviceId() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceId;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      var iosDeviceInfo = await deviceInfoPlugin.iosInfo;
      deviceId = iosDeviceInfo.identifierForVendor ??
          'Unknown iOS ID'; // Unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfoPlugin.androidInfo;
      deviceId = androidDeviceInfo.id; // Unique ID on Android
    }

    return deviceId;
  }

  final TextEditingController _ipAddressController =
      TextEditingController(); // Controller for IP address input

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (currentBackPressTime == null ||
            DateTime.now().difference(currentBackPressTime!) >
                Duration(seconds: 2)) {
          currentBackPressTime = DateTime.now();
          Fluttertoast.showToast(
            msg: "Press back again to exit",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(
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
                                controller:
                                    _ipAddressController, // Assign controller
                                style: TextStyle(fontFamily: 'MaanJoy'),
                                decoration: InputDecoration(
                                  hintText: "Enter your IP address",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        screenWidth * 0.05),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              SizedBox(
                                width: double.infinity,
                                height: screenHeight * 0.06,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    String ipAddress = _ipAddressController.text
                                        .trim(); // Trim whitespace
                                    if (ipAddress != "") {
                                      // IP address is not empty
                                      AppConfig.serverIPAddress = ipAddress;

                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setString(
                                          'ipAddress', ipAddress);
                                      fetchCategories();
                                    } else {
                                      Fluttertoast.showToast(
                                        msg: "Please Input IP Address First",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIosWeb: 3,
                                        backgroundColor: const Color.fromARGB(
                                            255, 112, 109, 109),
                                        textColor:
                                            const Color.fromARGB(255, 0, 0, 0),
                                        fontSize: 16.0,
                                      );
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          screenWidth * 0.05),
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
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
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
