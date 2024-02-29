import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';

class ItemWidget extends StatefulWidget {
  final String category;

  const ItemWidget({required this.category});

  @override
  _ItemWidgetState createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  late List<Item> items = [];

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    String url = 'http://192.168.0.104:8080/items';
    if (widget.category != 'ALL') {
      url +=
          '?category=${Uri.encodeQueryComponent(widget.category)}'; // Use Uri.encodeQueryComponent
    }

    final response = await http.get(Uri.parse(url));

    if (mounted) {
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          items = data.map((item) => Item.fromJson(item)).toList();
        });
      } else {
        throw Exception('Failed to fetch items');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return items.isNotEmpty
        ? GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            childAspectRatio: 0.76,
            children: items.map((item) => buildItemCard(item)).toList(),
          )
        : Center(
            child:
                CircularProgressIndicator()); // Show loading indicator while fetching items
  }

  Widget buildItemCard(Item item) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, "singleItemPage");
            },
            child: Container(
              margin: EdgeInsets.all(10),
              child: Image.asset(
                "images/burger.png",
                width: 120,
                height: 120,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                item.itemName,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              "${item.itemCode}", // Placeholder for item description
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.03,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${item.sellingPrice}",
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Icon(
                  CupertinoIcons.plus,
                  size: 25,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Item {
  final String itemName;
  final String itemCode;
  final double sellingPrice;

  Item({
    required this.itemName,
    required this.itemCode,
    required this.sellingPrice,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemName: json['itemName'] ?? '',
      itemCode: json['itemCode'] ?? '',
      sellingPrice: double.parse(json['sellingPrice'].toString()),
    );
  }
}
