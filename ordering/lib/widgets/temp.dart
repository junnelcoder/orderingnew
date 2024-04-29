// Widget buildItemCard(BuildContext context, Item item) {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   String? selectedTablesString = prefs.getString('selectedTables');

//   return Card(
//     color: widget.isDarkMode
//         ? Colors.grey.withOpacity(0.7)
//         : Colors.white.withOpacity(0.85),
//     margin: EdgeInsets.all(8.0),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(20.0),
//     ),
//     elevation: widget.isDarkMode ? 2 : 5.0,
//     child: InkWell(
//       onTap: () {
//         if (selectedTablesString != null && selectedTablesString.isNotEmpty) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => SingleItemPage(item: item),
//             ),
//           );
//         } else {
//           // Show a snackbar indicating that selected tables are empty
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Selected tables are empty'),
//               duration: Duration(seconds: 3),
//             ),
//           );
//         }
//       },
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Your item card content here...
//         ],
//       ),
//     ),
//   );
// }
