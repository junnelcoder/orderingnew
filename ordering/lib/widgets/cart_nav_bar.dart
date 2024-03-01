import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CartNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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

      // padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Price:",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15, // smaller font size
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                  height:
                      4), // Adjust the space between "Total Price:" and the price value
              Text(
                "\₱400", // Display the formatted total
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18, // smaller font size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "Save Order",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
