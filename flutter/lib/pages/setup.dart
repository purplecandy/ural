import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ural/background_tasks.dart';
import 'package:ural/utils/async.dart';
import 'package:ural/controllers/permission_handler.dart';

class Setup extends StatefulWidget {
  Setup({Key key}) : super(key: key);

  @override
  _SetupState createState() => _SetupState();
}

class _SetupState extends State<Setup> {
  GlobalKey<ScaffoldState> _scaffold = GlobalKey<ScaffoldState>();
  List<Step> setupSteps = [];
  int currentStep = 0;
  String defaultDirectoryPath = "";
  bool permissionStatus = false;
  bool defaultDirectory = false;
  bool backgroundSync = false;

  void buildSteps() {
    setupSteps = [
      Step(
        isActive: true,
        state:
            permissionStatus == true ? StepState.complete : StepState.indexed,
        title: Text("Grant Permission"),
        content: Text("Ural needs your permission to access your storage"),
      ),
      Step(
          isActive: true,
          state:
              defaultDirectory == true ? StepState.complete : StepState.indexed,
          title: Text("Set your default directory"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                  "This directory will be used to sync your screenshots automatically"),
              Text("Directroy: " +
                  (defaultDirectoryPath.length == 0
                      ? "NOT SET"
                      : defaultDirectoryPath))
            ],
          )),
      Step(
          isActive: true,
          title: Text("Background Sync"),
          state:
              backgroundSync == true ? StepState.complete : StepState.indexed,
          content: Text("Ural can now start syncing in the background.")),
      Step(
          isActive: true,
          title: Text("Finish"),
          content: Text(
              "Congratulations the setup is complete.\nNow soon your screenshots will start appearning and in case you want to find one just search for what was inside it.\n\nIncase you need any help just click the help icon on home screen.")),
    ];
  }

  Future<AsyncResponse> handleStepOne() async {
    var resp = await getPermissionStatus();
    if (resp.state == ResponseStatus.success) {
      _scaffold.currentState.showSnackBar(SnackBar(
        content: Text("Permission Granted"),
        backgroundColor: Colors.greenAccent,
      ));
      setState(() {
        permissionStatus = true;
      });
      return AsyncResponse(ResponseStatus.success, null);
    } else if (resp.state == ResponseStatus.failed) {
      _scaffold.currentState.showSnackBar(SnackBar(
        content: Text("Permission Denied"),
        backgroundColor: Colors.redAccent,
      ));
    } else {
      _scaffold.currentState.showSnackBar(SnackBar(
        content: Text("Can't request permissions"),
        backgroundColor: Colors.redAccent,
      ));
    }
    return AsyncResponse(ResponseStatus.failed, null);
  }

  Future<AsyncResponse> handleStepTwo(BuildContext context) async {
    // final pref = await SharedPreferences.getInstance();
    // await Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         fullscreenDialog: true,
    //         builder: (context) => FolderPickerPage(
    //             action: (context, directory) async {
    //               pref.setString("ural_default_folder", directory.path);
    //               Navigator.pop(context);
    //               setState(() {
    //                 defaultDirectoryPath = directory.path;
    //                 defaultDirectory = true;
    //               });
    //             },
    //             rootDirectory: Directory("/storage/emulated/0/"))));
    // if (defaultDirectoryPath.length > 0) {
    //   scaffoldSuccessMessage("Default directory set");

    //   return AsyncResponse(ResponseStatus.success, null);
    // }

    // scaffoldErrorMessage("No directory specified");
    // return AsyncResponse(ResponseStatus.failed, null);
  }

  Future<AsyncResponse> handleStepThree() async {
    startBackGroundJob();
    setState(() {
      backgroundSync = true;
    });
    scaffoldSuccessMessage("Background sync initialized");
    return AsyncResponse(ResponseStatus.success, null);
  }

  void handleFinalStep() async {
    final pref = await SharedPreferences.getInstance();
    pref.setBool("ural_initial_setup", true);
  }

  String currentControlTitle() {
    switch (currentStep) {
      case 0:
        return "Grant Permission";
        break;
      case 1:
        return "Set Folder";
        break;
      case 2:
        return "Start Syncing";
        break;
      default:
        return "Finish";
    }
  }

  void incrementStep(AsyncResponse resp) {
    if (resp.state == ResponseStatus.success) {
      setState(() {
        currentStep += 1;
      });
    }
  }

  void scaffoldSuccessMessage(String message) {
    _scaffold.currentState.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.greenAccent,
    ));
  }

  void scaffoldErrorMessage(String message) {
    _scaffold.currentState.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    buildSteps();
    return Scaffold(
      key: _scaffold,
      body: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Column(
            children: <Widget>[
              Text(
                "Welcome to Ural",
                style: TextStyle(fontSize: 24),
              ),
              Text("A screenshot organizer"),
              SizedBox(
                height: 40,
              ),
              Expanded(
                child: PageView(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        elevation: 10,
                        child: Container(
                          child: Text(
                              "Ural needs your permission to access your storage"),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
