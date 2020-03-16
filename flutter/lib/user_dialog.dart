import 'package:flutter/material.dart';
import 'package:ural/blocs/auth_bloc.dart';
import 'package:ural/utils/async.dart';

class UserDialog extends StatelessWidget {
  const UserDialog({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.person),
              title: Text(Auth().user.username),
              subtitle: Text("Currently logged user"),
            ),
            Center(
              child: Container(
                width: 80,
                child: FlatButton(
                  onPressed: () async {
                    final Auth auth = Auth();
                    final resp = await auth.logout();
                    if (resp.state == ResponseStatus.success) {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  child: Text("Log out"),
                  color: Colors.redAccent,
                  textColor: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
