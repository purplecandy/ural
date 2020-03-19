import 'package:flutter/material.dart';

// This is my own implementation of Bloc
// I perosnally don't like to use any state management library
// you lose the flexibilty of just Streams and States

/// [BlocBase] abstract class is supposed to be inherited by all the Blocs
abstract class BlocBase {
  void dispose();
}

/// [SingleBlocProvider] provides only one Bloc to the child widgets
class SingleBlocProvider<T> extends StatelessWidget {
  const SingleBlocProvider({Key key, T bloc, Widget child})
      : this.bloc = bloc,
        this.child = child,
        super(key: key);

  final T bloc;
  final Widget child;

  /// Returs the nearest Bloc extending from [BlocBase] from the widget tree
  static T of<T extends BlocBase>(BuildContext context) {
    final provider =
        context.findAncestorWidgetOfExactType<SingleBlocProvider<T>>();
    return provider.bloc;
  }

  @override
  Widget build(BuildContext context) {
    // print(context.widget);
    return child;
  }
}

/// MultiBlocProvider gives access to multiple/list blocs to child widgets from one provider
/// It's very handy in reducing the boiler plate
/// NOTE: MultiBlocProvider expects you to have all different Blocs of different types
/// you can't have two Blocs of same class
/// As it will only return the first instance of Bloc
class MultiBlocProvider extends StatelessWidget {
  const MultiBlocProvider({Key key, List<dynamic> blocs, Widget child})
      : this.blocs = blocs,
        this.child = child,
        super(key: key);
  final List<dynamic> blocs;
  final Widget child;

  /// Returs the first instance nearest of Bloc extending from [BlocBase] from the widget tree
  static T of<T extends BlocBase>(BuildContext context) {
    final provider = context.findAncestorWidgetOfExactType<MultiBlocProvider>();
    for (var bloc in provider.blocs) {
      if (bloc.runtimeType == T) return bloc;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // print(context.widget);
    return child;
  }
}
