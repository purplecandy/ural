import 'package:flutter/material.dart';

class QA {
  final String question, answer;
  QA(this.question, this.answer);
}

class FaqsWidget extends StatelessWidget {
  final List<QA> faqs = [
    QA("I can't see my images?",
        "First make sure your default directory contains screenshots.\n\nIt takes sometimes to automatically sync.\n\nTry re-configuring Ural from settings."),
    QA("I'm unable to grant permission?",
        "Please close the app and re-try. If it still doesn't work give permissions manually from settings."),
    QA("How frequent are background syncs?", "Every 2 hours"),
    QA("I can't manually upload an image?",
        "Make sure you have configured Ural properly. Incase you're getting an error then the image already exist."),
    QA("It won't recognize text properly",
        "It depends on things like quality of image, what fonts are used etc."),
    QA("What languages are currently supported?",
        "English but you can try if it works"),
    QA("My search results are empty", "Try different search queries."),
    QA("Is Ural making copies of my screenshots?",
        "No, Ural only links your screenshots available on your device")
  ];
  FaqsWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: ListView.builder(
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          itemCount: faqs.length,
          itemBuilder: (context, index) => ExpansionTile(
            title: Text(faqs[index].question),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(faqs[index].answer),
              )
            ],
          ),
        ),
      ),
    );
  }
}
