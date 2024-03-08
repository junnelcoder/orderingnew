import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/cart_nav_bar.dart';

class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: ListView(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black,
                            size: screenWidth * 0.07,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.08),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Text(
                      "Order List",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  //Item
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                      child: Container(
                        width: screenWidth * 0.9,
                        height: screenWidth * 0.35,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              child: Image.asset(
                                "images/SISIG.png",
                                height: screenWidth * 0.22,
                                width: screenWidth * 0.35,
                              ),
                            ),
                            Container(
                              width: screenWidth * 0.33,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    "Hot Burger",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Taste our Hot Pizza",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                    ),
                                  ),
                                  Text(
                                    "\$10",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.015),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      CupertinoIcons.plus,
                                      color: Colors.white,
                                      size: screenWidth * 0.08,
                                    ),
                                    Text(
                                      "2",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.06,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.minus,
                                      color: Colors.white,
                                      size: screenWidth * 0.08,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  //item (Example of additional item, you can adjust as needed)
                  // This item will be more responsive with less hardcoding
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                      child: Container(
                        width: screenWidth * 0.9,
                        height: screenWidth * 0.35,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              child: Image.asset(
                                "images/COKE1L.png",
                                height: screenWidth * 0.22,
                                width: screenWidth * 0.35,
                              ),
                            ),
                            Container(
                              width: screenWidth * 0.33,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    "Hot Burger",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Taste our Hot Pizza",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                    ),
                                  ),
                                  Text(
                                    "\$10",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.015),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      CupertinoIcons.plus,
                                      color: Colors.white,
                                      size: screenWidth * 0.08,
                                    ),
                                    Text(
                                      "2",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.06,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.minus,
                                      color: Colors.white,
                                      size: screenWidth * 0.08,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.05),
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.02,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Items: ",
                                  style: TextStyle(fontSize: screenWidth * 0.06),
                                ),
                                Text(
                                  "\$10",
                                  style: TextStyle(fontSize: screenWidth * 0.06),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: Colors.black,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.02,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Sub-Total: ",
                                  style: TextStyle(fontSize: screenWidth * 0.06),
                                ),
                                Text(
                                  "\$10",
                                  style: TextStyle(fontSize: screenWidth * 0.06),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: Colors.black,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.02,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Text(
                                //   "Delivery: ",
                                //   style: TextStyle(fontSize: screenWidth * 0.06),
                                // ),
                                // Text(
                                //   "\$10",
                                //   style: TextStyle(fontSize: screenWidth * 0.06),
                                // ),
                              ],
                            ),
                          ),
                          // Divider(
                          //   color: Colors.black,
                          // ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.02,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total: ",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.06,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "\$10",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      // drawer: DrawerWidget(),
      bottomNavigationBar: CartNavBar(),
    );
  }
}
