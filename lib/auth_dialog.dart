import 'package:flutter/material.dart';
import 'utils/async.dart';
import 'auth_bloc.dart';

class AuthenticationDialog extends StatefulWidget {
  AuthenticationDialog({Key key}) : super(key: key);

  @override
  _AuthenticationDialogState createState() => _AuthenticationDialogState();
}

class _AuthenticationDialogState extends State<AuthenticationDialog> {
  final _form = GlobalKey<FormState>();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  final PageController pageController = PageController();
  final authBloc = Auth();

  Widget button;
  bool isSignIn = true;
  Widget errorMessage = Container();

  String emptyValidator(String val) =>
      val.length > 0 ? null : "You can't keep it blank";

  void handleSignIn() async {
    String username = this.username.text;
    String password = this.password.text;
    final resp = await authBloc.signIn(username: username, password: password);
    if (resp.state == ResponseStatus.success) {
      Navigator.pop(context);
    }
    if (resp.state == ResponseStatus.error) {
      setState(() {
        errorMessage = Text(
          resp.object,
          style: TextStyle(color: Colors.redAccent),
        );
      });
    }
  }

  void handleSignUp() async {
    String username = this.username.text;
    String password = this.password.text;
    final resp = await authBloc.signup(username: username, password: password);
    if (resp.state == ResponseStatus.success) {
      Navigator.pop(context);
    }
    if (resp.state == ResponseStatus.error) {
      setState(() {
        errorMessage = Text(
          resp.object,
          style: TextStyle(color: Colors.redAccent),
        );
      });
    }
  }

  void changePage(bool forward) {
    if (forward) {
      pageController.nextPage(
          duration: Duration(milliseconds: 200), curve: Curves.easeIn);
    } else {
      pageController.previousPage(
          duration: Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {},
      child: Dialog(
        child: Container(
          height: 210,
          child: Form(
            key: _form,
            child: PageView(
              controller: pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                //Page 1
                Container(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Authentication",
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 24),
                        ),
                        Container(
                          width: double.infinity,
                          child: FlatButton(
                            onPressed: () {
                              setState(() {
                                isSignIn = true;
                              });
                              changePage(true);
                            },
                            child: Text("Sign In"),
                            textColor: Colors.white,
                            color: Colors.blue,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          child: FlatButton(
                            onPressed: () {
                              setState(() {
                                isSignIn = false;
                              });
                              changePage(true);
                            },
                            child: Text("Sign Up"),
                            textColor: Colors.white,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                //Page 2
                Container(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        //Upper Section
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            errorMessage,
                            Container(
                              height: 40,
                              child: TextFormField(
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "Username"),
                                controller: username,
                                validator: emptyValidator,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Container(
                              height: 40,
                              child: TextFormField(
                                obscureText: true,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "Password"),
                                controller: password,
                                validator: emptyValidator,
                              ),
                            )
                          ],
                        ),
                        //Bottom Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            OutlineButton(
                              onPressed: () {
                                changePage(false);
                                setState(() {
                                  errorMessage = Container();
                                  _form.currentState.reset();
                                });
                              },
                              child: Text("Back"),
                            ),
                            FlatButton(
                              onPressed: () {
                                if (_form.currentState.validate()) {
                                  if (isSignIn) {
                                    handleSignIn();
                                  } else {
                                    handleSignUp();
                                  }
                                }
                              },
                              child: Text(isSignIn ? "Sign In" : "Sign Up"),
                              textColor: Colors.white,
                              color: isSignIn ? Colors.blue : Colors.red,
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
