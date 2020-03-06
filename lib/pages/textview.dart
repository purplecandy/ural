import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart' show TextBlock;

class TextView extends StatelessWidget {
  final List<TextBlock> textBlocks;
  const TextView({Key key, this.textBlocks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Text View"),
      ),
      body: ListView.builder(
          padding: EdgeInsets.all(8.0),
          itemCount: textBlocks.length,
          itemBuilder: (context, index) => Card(
                child: Container(
                  padding: EdgeInsets.all(14),
                  child: Text(textBlocks[index].text),
                ),
              )),
    );
  }
}
