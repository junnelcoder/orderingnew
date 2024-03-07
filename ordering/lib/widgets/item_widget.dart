import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../pages/single_item_page.dart';
import '../pages/config.dart';
import 'dart:async';

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
    String ipAddress = AppConfig.serverIPAddress;
    String url = 'http://$ipAddress:8080/items';
    if (widget.category != 'ALL') {
      url += '?category=${Uri.encodeQueryComponent(widget.category)}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        items = data.map((item) => Item.fromJson(item)).toList();
      });
    } else {
      throw Exception('Failed to fetch items');
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
              childAspectRatio: 0.8,
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
    return screenWidth > 600 ? 3 : 2;
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
                _getImagePathForItem(item),
                width: 155,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'images/DEFAULT.png',
                    width: 155,
                    height: 120,
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.itemname,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "${item.itemcode}",
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
                    "\$${item.sellingprice}",
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
String _getImagePathForItem(Item item) {
  if (item.picture_path.trim().isNotEmpty) {
    return item.picture_path;
  } else {
    String itemName = item.itemname.trim().toUpperCase().replaceAll(' ', '_');

    // Listahan ng mga pangalan ng mga file ng larawan
    List<String> imageFiles = [
      // Idinagdag ang 'HOTCHOCO.png'
      // Idagdag ang iba pang mga pangalan ng mga file dito
    ];

    // Ihanap ng mga kasalukuyang pangalan ng mga file ng larawan
    for (String imageFileName in imageFiles) {
      // Kung ang pangalan ng item ay naglalaman ng substring ng filename, gamitin ito
      if (itemName.contains(imageFileName)) {
        return 'images/${imageFileName.toUpperCase()}.png';
      }
    }

    // Kung walang katugmaang natagpuan, ibalik ang default na larawan
    return 'images/DEFAULT.png';
  }
}







}

class Item {
  final String itemname;
  final String itemcode;
  final double sellingprice;

  // Additional properties with default valuesr
  final String category;
  final double unitPrice;
  final double markup;
  final String department;
  final String uom;
  final String vatable;
  final String section;
  final int close_status;
  final String picture_path;
  final String division;
  final String brand;

  // New properties
  final double total;
  final double subtotal;

  Item({
    required this.itemname,
    required this.itemcode,
    required this.sellingprice,
    // Additional properties with default values
    this.category = '',
    this.unitPrice = 0.0,
    this.markup = 0.0,
    this.department = '',
    this.uom = '',
    this.vatable = '',
    this.section = '',
    this.close_status = 0,
    this.picture_path = '',
    this.division = '',
    this.brand = '',
    // New properties with default values
    this.total = 0.0,
    this.subtotal = 0.0,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemname: json['itemname'] ?? '',
      itemcode: json['itemcode'] ?? '',
      sellingprice: json['sellingprice'] != null
          ? double.parse(json['sellingprice'].toString())
          : 0.0,
      // Additional properties initialized from JSON
      category: json['category'] ?? '',
      unitPrice: json['unitprice'] != null
          ? double.parse(json['unitprice'].toString())
          : 0.0,
      markup: json['markup'] != null
          ? double.parse(json['markup'].toString())
          : 0.0,
      department: json['department'] ?? '',
      uom: json['uom'] ?? '',
      vatable: json['vatable'] ?? '',
      section: json['section'] ?? '',
      division: json['division'] ?? '',
      close_status: json['close_status'] != null
          ? int.parse(json['close_status'].toString())
          : 0,
      picture_path: json['picture_path'] ?? '',
      brand: json['brand'] ?? '',
      // New properties initialized from JSON
      total:
          json['total'] != null ? double.parse(json['total'].toString()) : 0.0,
      subtotal: json['subtotal'] != null
          ? double.parse(json['subtotal'].toString())
          : 0.0,
    );
  }
}