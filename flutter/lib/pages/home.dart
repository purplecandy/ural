import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

import 'package:ural/pages/screens_view.dart';
import 'package:ural/widgets/all.dart';
import 'package:ural/widgets/dialogs/menu.dart';
import 'package:ural/widgets/dialogs/image_upload.dart';
import 'package:ural/widgets/dialogs/text_scan.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Handles Settings button events
  void handleSettings() async {
    showModalBottomSheet(
        context: context,
        builder: (context) => SingleChildScrollView(
              child: SettingsModalWidget(),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenView(
      bottomButtons: BottomButtons(),
    );
  }
}

class BottomButtons extends StatelessWidget {
  const BottomButtons({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width * 0.25,
      bottom: 40,
      child: Material(
        elevation: 10,
        color: Colors.transparent,
        child: Container(
            height: 40,
            width: MediaQuery.of(context).size.width * 0.5,
            decoration: BoxDecoration(
                color: Theme.of(context).backgroundColor,
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RoundedSplashButton(dialog: ImageDialog(), icon: Feather.image),
                Separator(),
                RoundedSplashButton(
                    dialog: TextScan(), icon: Feather.file_text),
                Separator(),
                SizedBox(
                  width: 40,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    onPressed: () {
                      Navigator.pushNamed(context, '/tags');
                    },
                    child: Icon(
                      Feather.tag,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                Separator(),
                RoundedSplashButton(dialog: MenuDialog(), icon: Feather.menu),
              ],
            )),
      ),
    );
  }
}

class Separator extends StatelessWidget {
  const Separator({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      width: 1,
      color: Colors.white.withOpacity(0.8),
    );
  }
}

class RoundedSplashButton extends StatelessWidget {
  final Widget dialog;
  final IconData icon;
  const RoundedSplashButton({Key key, this.dialog, this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: RawMaterialButton(
        shape: CircleBorder(),
        onPressed: () {
          showDialog(context: context, builder: (context) => dialog);
        },
        child: Icon(
          icon,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
