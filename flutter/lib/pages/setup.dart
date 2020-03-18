import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/controllers/permission_handler.dart';
import 'package:ural/utils/async.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:folder_picker/folder_picker.dart';

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
    final pref = await SharedPreferences.getInstance();
    await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => FolderPickerPage(
                action: (context, directory) async {
                  pref.setString("ural_default_folder", directory.path);
                  Navigator.pop(context);
                  setState(() {
                    defaultDirectoryPath = directory.path;
                    defaultDirectory = true;
                  });
                },
                rootDirectory: Directory("/storage/emulated/0/"))));
    if (defaultDirectoryPath.length > 0) {
      scaffoldSuccessMessage("Default directory set");

      return AsyncResponse(ResponseStatus.success, null);
    }

    scaffoldErrorMessage("No directory specified");
    return AsyncResponse(ResponseStatus.failed, null);
  }

  Future<AsyncResponse> handleStepThree() async {
    ScreenBloc.startBackGroundJob();
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
      appBar: AppBar(
        title: Text(
          "Setup Ural",
        ),
      ),
      body: Material(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Card(
              child: Stepper(
                currentStep: currentStep,
                steps: setupSteps,
                onStepTapped: (index) {
                  setState(() {
                    currentStep = index;
                  });
                },
                controlsBuilder: (BuildContext context,
                        {VoidCallback onStepContinue,
                        VoidCallback onStepCancel}) =>
                    Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 170,
                    height: 40,
                    child: Material(
                      borderRadius: BorderRadius.circular(6),
                      child: FlatButton(
                          // color: Colors.black.withOpacity(0.8),
                          onPressed: onStepContinue,
                          textColor: Colors.white,
                          child: Text(currentControlTitle())),
                    ),
                  ),
                ),
                onStepContinue: () {
                  if ((currentStep + 1) <= setupSteps.length) {
                    if (currentStep == 0) {
                      handleStepOne().then((resp) {
                        incrementStep(resp);
                      });
                    }
                    if (currentStep == 1) {
                      handleStepTwo(context).then((resp) {
                        incrementStep(resp);
                      });
                    }
                    if (currentStep == 2) {
                      handleStepThree().then((resp) {
                        incrementStep(resp);
                      });
                    }
                    if (currentStep == 3) {
                      Navigator.pop(context);
                      handleFinalStep();
                    }
                  }
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
            FlatButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.pinkAccent, width: 1)),
                textColor: Colors.white,
                onPressed: () async {
                  const url = "https://youtu.be/a-diWDZX2vM";
                  if (await canLaunch(url)) {
                    launch(url);
                  }
                },
                child: Text("Watch Demo on YT")),
          ],
        ),
      ),
    );
  }
}
