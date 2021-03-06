import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ural/blocs/search_bloc.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/widgets/filter_tag.dart';

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
        factor = MediaQuery.of(context).size.width - 10;
      });
    } else {
      setState(() {
        factor = MediaQuery.of(context).size.width * 0.8;
      });
    }
    return Material(
      elevation: 4,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        height: 40,
        width: factor,
        curve: Curves.easeInSine,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(radius)),
        child: TextField(
          controller: widget.controller,
          textInputAction: TextInputAction.search,
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
              hintText: widget.hintText,
              suffixIcon: Consumer<FilterTagsBloc>(
                builder: (c, filterBloc, _) =>
                    BlocBuilder<FilterState, Set<int>>(
                  bloc: filterBloc,
                  onSuccess: (c, e) => Material(
                      color: Colors.transparent,
                      child: IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: e.object.isEmpty
                                ? Colors.grey
                                : Colors.pinkAccent,
                          ),
                          onPressed: () {
                            widget.focusNode.unfocus(
                                disposition:
                                    UnfocusDisposition.previouslyFocusedChild);
                            showModalBottomSheet(
                                isScrollControlled: true,
                                context: context,
                                builder: (context) =>
                                    FilterByTagsWidget<FilterTagsBloc>(
                                      bloc: filterBloc,
                                      onApply: () {
                                        Navigator.pop(context);
                                        widget.onSubmitted(
                                            widget.controller.text);
                                      },
                                    ));
                          })),
                ),
              )),
        ),
      ),
    );
  }
}
