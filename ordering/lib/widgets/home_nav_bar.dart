import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../pages/config.dart';

class HomeNavBar extends StatelessWidget {
  Future<int> fetchOpenCartItemsCount() async {
    var ipAddress = AppConfig.serverIPAddress;
    var url = Uri.parse('http://$ipAddress:8080/api/get-open-cart-items-count');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final int count = data['count'] as int;
      return count;
    } else {
      throw Exception('Failed to fetch open cart items count');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: fetchOpenCartItemsCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          int openCartItemsCount = snapshot.data!;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, "cartPage");
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.assignment_add,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    if (openCartItemsCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: Text(
                            openCartItemsCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
