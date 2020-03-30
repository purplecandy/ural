import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

typedef VoidCallback = void Function();

/// These bloc implementation are based on my own understanding
/// The goal of this implementation is to give flexiblity to user with Blocs
/// while keeping this simple and easy to adopt

///
/// Methodology:
///
/// One Bloc will only manage one stream
///
/// Anything that can cause a change in the stream/state has to go through `dispatch()`
///
/// Methods that modify the stream should be kept private
///
/// Anyother helper function that doesn't cause change in the state/stream
/// Exaple - An input validation
/// should begin with `handle` keyword

/// ActionReciver or ActionHandler
/// provides a method to handle incoming events that can cause change in the stream
/// hence the resultant change can cause views to rebuild
/// T - ActionState tells the dispatch function what kind of actions it will receive
/// and what to do when a specific action is received
abstract class ActionReceiver<T> {
  /// T - actionState - represents the type of actions it will receive
  /// dispatch will invoke methods depending on the actionState
  /// data - it's used to pass extra arguments
  void dispatch(T actionState, [Map<String, dynamic> data]);
}

/// A subState is the actual state that get's passed through the stream
/// T - The object which represents the data that's beind passed along with the stream
/// S - State represents the state of data that View Models will youse to rebuild themself
/// I have decided to use both along as it's easier to build depending on one
/// Example - A [State.Loading] will represed data object when it's null, empty
/// A [State.Done] will repsent data object when it's non-null, not-empty, modified
class SubState<S, T> {
  // An enum what represents the State of the object value at an instance
  S state;
  // Object which will carry the data
  T object;
  SubState(this.state, this.object);
}

class StreamState<S, T> {
  //Decalration of subState
  final SubState<S, T> _subState;

  BehaviorSubject<SubState<S, T>> _subject;

  //The value pass will be considered as initial state and value
  StreamState(this._subState) {
    //Initializing the stream
    _subject = BehaviorSubject.seeded(_subState);
  }

  /// Returs the stream of the subject
  Observable<SubState<S, T>> get stream => _subject.stream;

  /// Since the subState are nothing more than events for the StreamController
  /// It can also be called as event
  SubState<S, T> get event => _subState;

  /// getters and setters for (subState/event)
  /// These are the actual representative of subState
  T get data => _subState.object;
  S get currentState => _subState.state;

  set data(T value) => _subState.object = value;
  set currentState(S newState) => _subState.state = newState;

  /// The subject is called controller
  BehaviorSubject<SubState<S, T>> get controller => _subject;

  /// A handy function which adds the event to StreamController
  /// which will automatically update listeners
  void notifyListeners() {
    _subject.add(event);
  }

  void dispose() {
    _subject.close();
  }
}

/// Repositories are like centralized data store for widget in the tree
/// Repositories will never cause any change of state in widget tree
/// It only holds data objects so multiple resources can use it
abstract class Repository {
  Set<VoidCallback> _listeners = Set<VoidCallback>();

  void addListeners(VoidCallback listener) => _listeners.add(listener);

  void removeListeners(VoidCallback listener) =>
      print("REMOVED" + _listeners.remove(listener).toString());

  void notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

class RepositoryProvider<T> extends StatelessWidget {
  const RepositoryProvider({Key key, T repository, Widget child})
      : this.repository = repository,
        this.child = child,
        super(key: key);
  final T repository;
  final Widget child;

  /// Returs the nearest Repository extending from [Repository] from the widget tree
  static T of<T extends Repository>(BuildContext context) {
    final provider =
        context.findAncestorWidgetOfExactType<RepositoryProvider<T>>();
    return provider.repository;
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class MultiRepositoryProvider extends StatelessWidget {
  const MultiRepositoryProvider(
      {Key key, List<dynamic> repositories, Widget child})
      : this.repositories = repositories,
        this.child = child,
        super(key: key);
  final List<dynamic> repositories;
  final Widget child;

  /// Returs the first instance nearest of Bloc extending from [BlocBase] from the widget tree
  static T of<T extends Repository>(BuildContext context) {
    final provider =
        context.findAncestorWidgetOfExactType<MultiRepositoryProvider>();
    for (var bloc in provider.repositories) {
      if (bloc.runtimeType == T) return bloc;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    print(context.widget);
    return child;
  }
}
// This is my own implementation of Bloc
// I perosnally don't like to use any state management library
// you lose the flexibilty of just Streams and States

/// [BlocBase] abstract class is supposed to be inherited by all the Blocs
abstract class BlocBase {
  void dispose();
}

/// [SingleBlocProvider] provides only one Bloc to the child widgets
class SingleBlocProvider<T> extends StatefulWidget {
  const SingleBlocProvider(
      {Key key,
      @required T bloc,
      @required Widget child,
      this.attachToNotifier = false,
      this.unqiueKey})
      : this.bloc = bloc,
        this.child = child,
        super(key: key);

  final String unqiueKey;
  final bool attachToNotifier;
  final T bloc;
  final Widget child;

  /// Returs the nearest Bloc extending from [BlocBase] from the widget tree
  static T of<T extends BlocBase>(BuildContext context) {
    final provider =
        context.findAncestorWidgetOfExactType<SingleBlocProvider<T>>();
    return provider.bloc;
  }

  @override
  _SingleBlocProviderState createState() => _SingleBlocProviderState();
}

class _SingleBlocProviderState<T> extends State<SingleBlocProvider<T>> {
  @override
  void initState() {
    super.initState();
    _attachKey();
  }

  void _attachKey() {
    if (widget.attachToNotifier) {
      CrossAccessBlocNotifier.addKey(context, widget.unqiueKey, widget.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    // print(context.widget);
    return widget.child;
  }
}

/// A CrossAccessedBloc represents a bloc which can be accessed by widget from different routes
/// Meaning if there are two routes
///
/// Home()
/// Details()
///
/// Usually if the Bloc is declared inside the Home route and needs to accessed by other routes
/// you either need to pass the bloc as paramenter or when you're using named Route then you
/// have to declare the BlocProvider before the routes are generated usually as a parent of MaterialApp
/// which is fine as it works but it's similar to a `global` your Bloc is generated and is available even if it's
/// corresponding widget isn't built
///
///
/// A CrossAccessedBloc takes a `String uniqueKey` this represent the specifc bloc and it sohuld always be unique for
/// all the blocs. Nice thing about CrossAccessedBloc is the widgets under the same tree can access the bloc
/// by the standard `SingleBlocProvider.of<T>()` as it's internally implementing a SingleBlocProvider but with a GlobalKey
/// which holds the refernce to it's state
class CrossAccessBloc<T> extends StatelessWidget {
  CrossAccessBloc(
      {@required this.uniqueKey,
      @required this.bloc,
      @required this.child,
      Key key})
      : super(key: key);
  final Widget child;
  final T bloc;
  final String uniqueKey;
  final GlobalKey<_SingleBlocProviderState<T>> globalKey =
      GlobalKey<_SingleBlocProviderState<T>>();

  @override
  Widget build(BuildContext context) {
    return SingleBlocProvider(
      bloc: bloc,
      key: globalKey,
      attachToNotifier: true,
      child: child,
      unqiueKey: uniqueKey,
    );
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

/// CrossAccessedBlocNotifier holds references to all the blocs that can cross-accessed
/// with the help of these references the bloc can be obtained anywhere in the widget tree
class CrossAccessBlocNotifier extends StatelessWidget {
  CrossAccessBlocNotifier({Key key, this.child}) : super(key: key);
  //A hashmap of SingleBlocProviders state references
  //The key is a unique string provided by the `CrossedAccessedBloc` the time of creation
  final Map<String, GlobalKey<dynamic>> _keys = {};
  final Widget child;

  /// This will notify the bloc with help of uniqueKey provided
  ///
  /// data - it should have Keys
  ///
  /// `data["action_state"]` and `data["data"]` since all the blocs have `dispatch()` to change the state
  /// and it takes to argument the Action and Data
  static notifyWidgetWithKey<T>(BuildContext context, String uniqueKey,
      [Map<String, dynamic> data]) {
    // Get the instance of notifier from the widget tree
    final notifier =
        context.findAncestorWidgetOfExactType<CrossAccessBlocNotifier>();

    // Check if the uniqueKey provided is valid
    if (notifier._keys.containsKey(uniqueKey)) {
      //Get the SingleBlocProvider widget from the notifier
      final SingleBlocProvider widget = notifier._keys[uniqueKey].currentWidget;
      //Execute the bloc's dispatch method
      widget.bloc.dispatch(data["action_state"], data["data"]);
    }
  }

  // Adds the global key to the hashmap
  static addKey(BuildContext context, String uniqueKey, GlobalKey key) {
    final notifier =
        context.findAncestorWidgetOfExactType<CrossAccessBlocNotifier>();
    notifier._keys[uniqueKey] = key;
    // print(notifier._keys);
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
