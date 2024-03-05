import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import '../pages/single_item_page.dart';
import '../pages/config.dart';

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
    String url = 'http://${AppConfig.serverIPAddress}:8080/items';
    if (widget.category != 'ALL') {
      url += '?category=${Uri.encodeQueryComponent(widget.category)}';
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
        ? GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _calculateCrossAxisCount(context),
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8, // Adjust aspect ratio for better fitting
            ),
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return buildItemCard(context, items[index]);
            },
          )
        : Center(
            child: CircularProgressIndicator(),
          );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2; // Default value for smaller screens

    if (screenWidth > 600) {
      crossAxisCount = 3; // For larger screens, display more items per row
    }

    return crossAxisCount;
  }

  Widget buildItemCard(BuildContext context, Item item) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SingleItemPage(item: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Image.asset(
                "images/pizza.jpg",
                width: 155,
                height: 120,
                // fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.itemName,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2, // Limit the number of lines
                overflow: TextOverflow.ellipsis, // Handle overflow by ellipsis
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "${item.itemCode}",
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\$${item.sellingPrice}",
                    style: TextStyle(
                      fontSize: 14.0,
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
