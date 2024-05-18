// floatingActionButton: Stack(
//   alignment: Alignment.topRight,
//   children: [
//     Padding(
//       padding: const EdgeInsets.only(top: 80.0), // Adjust the top padding
//       child: Visibility(
//         visible: _showExtraButtons, // Show the button based on the state
//         child: FloatingActionButton.extended(
//           onPressed: () {
//             // Add onPressed action for the new button
//           },
//           label: Text("New Button"),
//           icon: Icon(Icons.add),
//           backgroundColor: Colors.blue,
//         ),
//       ),
//     ),
//     AnimatedOpacity(
//       opacity: _isSwitchOn ? 1.0 : 0.0,
//       duration: Duration(milliseconds: 200),
//       child: _isSwitchOn
//           ? FloatingActionButton.extended(
//               onPressed: () {
//                 setState(() {
//                   _showExtraButtons = !_showExtraButtons;
//                 });
//               },
//               label: Text(""),
//               icon: Icon(Icons.more_horiz),
//               backgroundColor: isDarkMode
//                   ? Colors.grey.withOpacity(0.85)
//                   : Colors.orange.withOpacity(0.85),
//               foregroundColor: Colors.white,
//               elevation: 4.0,
//             )
//           : SizedBox(),
//     ),
//   ],
// ),
