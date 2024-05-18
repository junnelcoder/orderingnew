// Widget build(BuildContext context) {
//   selectedFromShared();
//   List<String> filteredCategories = categories.toList();

//   String labelText = alreadySelectedTable.isNotEmpty
//       ? '$alreadySelectedTable'
//       : 'Select Table';

//   // Check if categories are empty to show shimmer effect
//   bool showShimmer = categories.isEmpty;

//   return WillPopScope(
//     onWillPop: () async {
//       // Code for back button handling...
//     },
//     child: DefaultTabController(
//       length: filteredCategories.length,
//       child: Scaffold(
//         backgroundColor:
//             isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.white,
//         body: SafeArea(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   vertical: 10,
//                   horizontal: 15,
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         height: 50,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: isDarkMode
//                                   ? Colors.grey.withOpacity(0.4)
//                                   : Colors.black.withOpacity(0.4),
//                               spreadRadius: 1,
//                               blurRadius: 8,
//                             ),
//                           ],
//                         ),
//                         child: Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 10),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 CupertinoIcons.search,
//                                 color: Colors.black,
//                               ),
//                               Expanded(
//                                 child: Padding(
//                                   padding:
//                                       EdgeInsets.symmetric(horizontal: 15),
//                                   child: TextFormField(
//                                     controller: _searchController,
//                                     decoration: InputDecoration(
//                                       hintText: "Search...",
//                                       border: InputBorder.none,
//                                     ),
//                                     onChanged: (value) {
//                                       setState(() {});
//                                     },
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: _toggleDarkMode,
//                       icon: Icon(
//                         isDarkMode ? Icons.light_mode : Icons.dark_mode,
//                         color: isDarkMode ? Colors.white : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               TabBar(
//                 isScrollable: true,
//                 indicator: BoxDecoration(),
//                 labelStyle: TextStyle(fontSize: 15),
//                 labelPadding: EdgeInsets.symmetric(horizontal: 20),
//                 tabs: filteredCategories
//                     .map<Tab>((category) => Tab(text: category))
//                     .toList(),
//                 unselectedLabelColor:
//                     isDarkMode ? Colors.grey : Colors.grey,
//                 labelColor: isDarkMode ? Colors.white : Colors.black,
//               ),
//               Flexible(
//                 flex: 1,
//                 child: showShimmer
//                     ? Shimmer.fromColors(
//                         // Shimmer implementation...
//                       )
//                     : TabBarView(
//                         // TabBarView implementation...
//                       ),
//               ),
//             ],
//           ),
//         ),
//         bottomNavigationBar: HomeNavBar(
//           // HomeNavBar implementation...
//         ),
//         floatingActionButton: Align(
//           // FloatingActionButton implementation...
//         ),
//       ),
//     ),
//   );
// }
