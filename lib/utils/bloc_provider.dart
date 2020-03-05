import 'package:flutter/material.dart';

abstract class BlocBase extends Widget {
  @override
  Element createElement() {
    return null;
  }

  void dispose();
}

class StaticBloc<T extends BlocBase> extends StatelessWidget {
  const StaticBloc({Key key, T bloc, Widget child})
      : this.bloc = bloc,
        this.child = child,
        super(key: key);

  final T bloc;
  final Widget child;

  static T of<T extends BlocBase>(BuildContext context) {
    final provider = context.findAncestorWidgetOfExactType<StaticBloc<T>>();
    return provider.bloc;
  }

  // static Type _typeOf<T>() => T;

  static Type getType<T extends BlocBase>() => StaticBloc<T>(
        bloc: null,
        child: null,
        key: null,
      ).runtimeType;

  @override
  Widget build(BuildContext context) {
    print(context.widget);
    return child;
  }
}
