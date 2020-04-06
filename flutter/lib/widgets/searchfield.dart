import 'package:flutter/material.dart';

typedef void VoidCallBack(String val);
typedef bool FocusCallBack();

class SearchFieldWidget extends StatefulWidget {
  final String hintText;
  final FocusNode focusNode;
  final TextEditingController controller;
  final VoidCallBack onChanged;
  final VoidCallBack onSubmitted;
  final FocusCallBack hasFocus;
  const SearchFieldWidget(
      {Key key,
      this.controller,
      this.onChanged,
      this.onSubmitted,
      this.hintText,
      this.focusNode,
      this.hasFocus})
      : super(key: key);

  @override
  _SearchFieldWidgetState createState() => _SearchFieldWidgetState();
}

class _SearchFieldWidgetState extends State<SearchFieldWidget> {
  double factor;
  double radius = 20;

  @override
  void initState() {
    super.initState();
    // startup();
  }

  void startup() {}

  @override
  Widget build(BuildContext context) {
    factor = MediaQuery.of(context).size.width * 0.8;
    if (widget.hasFocus()) {
      setState(() {
        factor = MediaQuery.of(context).size.width;
        radius = 0;
      });
    } else {
      setState(() {
        factor = MediaQuery.of(context).size.width * 0.8;
        radius = 20;
      });
    }
    return Material(
      elevation: 20,
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        height: 40,
        width: factor,
        curve: Curves.easeInSine,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(radius)),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
              hintStyle: TextStyle(color: Colors.black),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.black,
              ),
              border: InputBorder.none,
              hintText: widget.hintText),
        ),
      ),
    );
  }
}
