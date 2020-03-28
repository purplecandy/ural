// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// import 'package:ural/widgets/all.dart';
// import 'package:ural/utils/bloc_provider.dart';
// import 'package:ural/blocs/screen_bloc.dart';
// import 'package:ural/pages/setup.dart';
// import 'package:ural/pages/textview.dart';

// class HomePage extends StatefulWidget {
//   HomePage({Key key}) : super(key: key);

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
//   ScreenBloc _bloc = ScreenBloc();
//   TabController _tabController;
//   final PageController _pageController = PageController();
//   final _scaffold = GlobalKey<ScaffoldState>();
//   final recognizer = FirebaseVision.instance.textRecognizer();
//   String searchQuery = "";
//   int currentTab = 0;

//   bool intial = false;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     startup();
//   }

//   void startup() async {
//     intialSetup();
//     //gotta wait for database to get initialized
//     await _bloc.initializeDatabase();
//     //then lazily load all the screens
//     _bloc.listAllScreens();
//   }

//   @override
//   void dispose() {
//     _bloc.dispose();
//     super.dispose();
//   }

//   void refresh() {
//     _scaffold.currentState.showSnackBar(SnackBar(
//         content: Text(
//       "Refreshing...",
//     )));
//     _bloc.listAllScreens();
//   }

//   Future<void> intialSetup() async {
//     final pref = await SharedPreferences.getInstance();
//     setState(() {
//       intial = pref.containsKey("ural_initial_setup");
//     });
//     if (intial == false) {
//       Navigator.push(
//           context,
//           MaterialPageRoute(
//               fullscreenDialog: true, builder: (context) => Setup()));
//     }
//   }

//   void onSubmitTF() => _bloc.handleTextField(searchQuery);

//   /// Handles Settings button events
//   void handleSettings() async {
//     showModalBottomSheet(
//         context: context,
//         builder: (context) => SingleChildScrollView(
//               child: SettingsModalWidget(),
//             ));
//   }

//   ///Handle textView events
//   void handleTextView() async {
//     File image = await ImagePicker.pickImage(source: ImageSource.gallery);
//     final blocks = await _bloc.recognizeImage(image, getBlocks: true);
//     Navigator.push(
//         context,
//         MaterialPageRoute(
//             fullscreenDialog: true,
//             builder: (context) => TextView(
//                   textBlocks: blocks,
//                 )));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleBlocProvider<ScreenBloc>(
//       bloc: _bloc,
//       child: Scaffold(
//         key: _scaffold,
//         body: NestedScrollView(
//           headerSliverBuilder: (context, isBoxScroll) => [
//             SliverAppBar(
//               leading: null,
//               expandedHeight: 150,
//               elevation: 10,
//               pinned: true,
//               floating: true,
//               forceElevated: isBoxScroll,
//               // title: Container(height: 40, child: Text("Ural")),
//               title: Container(
//                 height: 40,
//                 width: MediaQuery.of(context).size.width,
//                 child: Container(
//                   padding: EdgeInsets.only(bottom: 20),
//                   decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20)),
//                   child: TextField(
//                     onChanged: (val) {
//                       searchQuery = val;
//                     },
//                     onSubmitted: (val) {
//                       onSubmitTF();
//                     },
//                     decoration: InputDecoration(
//                         prefixIcon: Icon(Icons.search),
//                         // prefix: IconButton(
//                         //   color: Colors.black,
//                         //   icon: Icon(Icons.search),
//                         //   onPressed: onSubmitTF,
//                         // ),
//                         border: InputBorder.none,
//                         hintText: "Type what you're looking for here"),
//                   ),
//                 ),
//               ),
//               // actions: <Widget>[
//               //   IconButton(icon: Icon(Icons.refresh), onPressed: refresh),
//               //   IconButton(
//               //       icon: Icon(Icons.help_outline),
//               //       onPressed: () {
//               //         setState(() {
//               //           intial = false;
//               //         });
//               //       }),
//               //   IconButton(
//               //       icon: Icon(Icons.settings),
//               //       onPressed: () {
//               //         handleSettings();
//               //       })
//               // ],
//               bottom: PreferredSize(
//                 preferredSize: Size.fromHeight(48),
//                 child: TabBar(
//                   controller: _tabController,
//                   tabs: <Widget>[
//                     Tab(child: Text("Browse")),
//                     Tab(child: Text("Search")),
//                   ],
//                 ),
//               ),
//               // flexibleSpace: FlexibleSpaceBar(
//               //   background: Container(
//               //     margin: EdgeInsets.only(top: 60),
//               //     child: Column(
//               //       crossAxisAlignment: CrossAxisAlignment.center,
//               //       children: <Widget>[
//               //         Container(
//               //           height: 110,
//               //           width: MediaQuery.of(context).size.width,
//               //           child: Padding(
//               //             padding: const EdgeInsets.all(30.0),
//               //             child: Center(
//               //               child: Container(
//               //                 decoration: BoxDecoration(
//               //                     color: Colors.white,
//               //                     borderRadius: BorderRadius.circular(20)),
//               //                 child: ListTile(
//               //                     title: TextField(
//               //                       onChanged: (val) {
//               //                         searchQuery = val;
//               //                       },
//               //                       onSubmitted: (val) {
//               //                         onSubmitTF();
//               //                       },
//               //                       decoration: InputDecoration(
//               //                           border: InputBorder.none,
//               //                           hintText:
//               //                               "Type what you're looking for here"),
//               //                     ),
//               //                     trailing: IconButton(
//               //                       icon: Icon(Icons.search),
//               //                       onPressed: onSubmitTF,
//               //                     )),
//               //               ),
//               //             ),
//               //           ),
//               //         ),
//               //       ],
//               //     ),
//               //   ),
//               // ),
//             ),
//           ],
//           body: TabBarView(
//             controller: _tabController,
//             // onPageChanged: (index) {
//             //   setState(() {
//             //     currentTab = index;
//             //   });
//             // },
//             // controller: _pageController,
//             // physics: NeverScrollableScrollPhysics(),
//             children: <Widget>[
//               StreamBuilder<RecentScreenStates>(
//                 stream: _bloc.streamOfRecentScreens,
//                 builder: (context, snapshot) {
//                   if (snapshot.hasData) {
//                     if (snapshot.data == RecentScreenStates.loading) {
//                       return Material(
//                         child: Center(
//                           child: CircularProgressIndicator(),
//                         ),
//                       );
//                     } else {
//                       if (_bloc.recentScreenshots.length > 0) {
//                         return HomeBodyWidget(
//                           title: "Recent Screenshots",
//                           screenshots: _bloc.recentScreenshots,
//                         );
//                       } else {
//                         return Material(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: <Widget>[
//                               Text(
//                                 "You don't have any screenshots synced.",
//                                 style: TextStyle(
//                                     fontSize: 18, color: Colors.white),
//                               ),
//                               SizedBox(
//                                 height: 40,
//                               ),
//                               FlatButton(
//                                   shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                       side: BorderSide(
//                                           color: Colors.pinkAccent, width: 1)),
//                                   textColor: Colors.white,
//                                   onPressed: () {
//                                     refresh();
//                                   },
//                                   child: Text("Refresh"))
//                             ],
//                           ),
//                         );
//                       }
//                     }
//                   }
//                   return Container();
//                 },
//               ),
//               StreamBuilder<SearchStates>(
//                 stream: _bloc.streamofSearchResults,
//                 builder: (context, snapshot) {
//                   if (snapshot.hasData) {
//                     if (snapshot.data == SearchStates.finished) {
//                       return HomeBodyWidget(
//                         title: "Search results",
//                         screenshots: _bloc.searchResults,
//                       );
//                     }
//                     if (snapshot.data == SearchStates.empty) {
//                       return Material(
//                         child: Center(
//                           child: Text(
//                             "Couldn't find anything. Please trying typing something else",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       );
//                     }
//                   }
//                   return Material(
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Center(
//                         child: Text(
//                           "Looking for a screenshot? Just try searchin what was inside it.",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(fontSize: 18, color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//         // floatingActionButton: Row(
//         //   mainAxisAlignment: MainAxisAlignment.center,
//         //   children: <Widget>[
//         //     FloatingActionButton(
//         //       backgroundColor: Colors.deepPurpleAccent,
//         //       mini: true,
//         //       elevation: 9,
//         //       heroTag: null,
//         //       onPressed: () {
//         //         _bloc.handleManualUpload(_scaffold);
//         //       },
//         //       child: Icon(Icons.file_upload),
//         //     ),
//         //     SizedBox(
//         //       width: 10,
//         //     ),
//         //     FloatingActionButton(
//         //       backgroundColor: Colors.deepPurpleAccent,
//         //       mini: true,
//         //       elevation: 9,
//         //       heroTag: null,
//         //       onPressed: () async {
//         //         handleTextView();
//         //       },
//         //       child: Icon(Icons.text_fields),
//         //     ),
//         //   ],
//         // ),
//         // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//         // bottomNavigationBar: BottomNavigationBar(
//         //     currentIndex: currentTab,
//         //     onTap: (index) {
//         //       _pageController.animateToPage(index,
//         //           duration: Duration(milliseconds: 250), curve: Curves.easeIn);
//         //       setState(() {
//         //         currentTab = index;
//         //       });
//         //     },
//         //     selectedItemColor: Colors.pinkAccent,
//         //     unselectedItemColor: Colors.white,
//         //     items: [
//         //       BottomNavigationBarItem(
//         //           icon: Icon(Icons.grid_on), title: Text("HomePage")),
//         //       BottomNavigationBarItem(
//         //           icon: Icon(Icons.search), title: Text("Search"))
//         //     ]),
//         bottomNavigationBar: BottomAppBar(
//           child: TabBar(
//             controller: _tabController,
//             tabs: <Widget>[
//               Tab(child: Text("Browse")),
//               Tab(child: Text("Search")),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
