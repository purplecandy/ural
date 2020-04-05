import 'package:flutter/material.dart';

typedef void VoidCallBack(String val);

class SearchFieldWidget extends StatelessWidget {
  final String hintText;
  final FocusNode focusNode;
  final TextEditingController controller;
  final VoidCallBack onChanged;
  final VoidCallBack onSubmitted;
  const SearchFieldWidget(
      {Key key,
      this.controller,
      this.onChanged,
      this.onSubmitted,
      this.hintText,
      this.focusNode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      color: Colors.transparent,
      child: Container(
        height: 40,
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
              hintStyle: TextStyle(color: Colors.black),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.black,
              ),
              border: InputBorder.none,
              hintText: hintText),
        ),
      ),
    );
  }
}
