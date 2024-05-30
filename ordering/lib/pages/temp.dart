// child: DefaultTabController(
//   length: filteredCategories.length,
//   child: Scaffold(
//     backgroundColor: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.white,
//     body: SafeArea(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: EdgeInsets.symmetric(
//               vertical: 10,
//               horizontal: 0,
//             ),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     // Open the sidebar when the menu icon is tapped
//                     Scaffold.of(context).openDrawer();
//                   },
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 15),
//                     child: Icon(
//                       Icons.menu, 
//                       size: 30, 
//                       color: isDarkMode ? Colors.white : Colors.black,
//                     ),
//                   ),
//                 ),
//                 // Your existing code...
//               ],
//             ),
//           ),
//           // Your existing code...
//         ],
//       ),
//     ),
//     // Add a Drawer for the sidebar
//     drawer: Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: <Widget>[
//           DrawerHeader(
//             decoration: BoxDecoration(
//               color: Colors.blue,
//             ),
//             child: Text(
//               'Sidebar Header',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 24,
//               ),
//             ),
//           ),
//           ListTile(
//             title: Text('Sidebar Item 1'),
//             onTap: () {
//               // Update UI or perform any action when the sidebar item is tapped
//             },
//           ),
//           ListTile(
//             title: Text('Sidebar Item 2'),
//             onTap: () {
//               // Update UI or perform any action when the sidebar item is tapped
//             },
//           ),
//           // Add more sidebar items as needed
//         ],
//       ),
//     ),
//     // Your existing code...
//   ),
// ),
