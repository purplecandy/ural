import 'package:flutter/material.dart';
import 'package:ural/widgets/buttons.dart';
import 'package:ural/widgets/dialogs/base.dart';

class ConfirmationDialog extends StatefulWidget {
  final String title, buttonText, processingText, optionTitle, optionSubtitle;
  final void Function(BuildContext context, bool confirmed) onConfirm;
  ConfirmationDialog({
    Key key,

    /// Dialog tittle
    this.title,

    /// Initial text of the button
    this.buttonText,

    /// Button text when the widget is processing
    this.processingText,
    this.optionTitle,
    this.optionSubtitle,
    @required this.onConfirm,
  }) : super(key: key);

  @override
  _ConfirmationDialogState createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  bool _confirmed = false;
  bool _processing = false;
  @override
  Widget build(BuildContext context) {
    return BaseDialog(
        title: widget.title,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: CheckboxListTile(
                value: _confirmed,
                onChanged: (v) {
                  setState(() {
                    _confirmed = v;
                  });
                },
                isThreeLine: true,
                title: Text(widget.optionTitle),
                subtitle: Text(widget.optionSubtitle),
              ),
            ),
            RoundedPurpleButton(
              onPressed: () {
                setState(() {
                  _processing = true;
                });
                widget.onConfirm(context, _confirmed);
              },
              child: _processing
                  ? Container(
                      width: 160,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            height: 10,
                            width: 10,
                            child: CircularProgressIndicator(),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(widget.processingText,
                              style: TextStyle(color: Colors.white))
                        ],
                      ),
                    )
                  : Text(
                      widget.buttonText,
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ));
  }
}
