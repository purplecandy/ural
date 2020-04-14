import 'dart:async';
import 'package:rxdart/rxdart.dart';
export 'package:rxdart/transformers.dart';

/// I think this will be the last major iteration of my bloc library

class Event<S, T> {
  final S state;
  final T object;
  Event(this.state, this.object);
}

abstract class BlocBase<S, A, T> {
  BehaviorSubject<Event<S, T>> _controller;

  BlocBase({S state, T object}) {
    _controller =
        BehaviorSubject<Event<S, T>>.seeded(initialState(state, object));
  }

  BehaviorSubject<Event<S, T>> get controller => _controller;
  Stream<Event<S, T>> get stream => _controller.stream;
  Event<S, T> get event => _controller.value;

  void updateState(S state, T data) {
    _controller.add(Event<S, T>(state, data));
  }

  Event<S, T> initialState(S state, T object) => Event<S, T>(state, object);

  void dispose() {
    _controller.close();
  }

  void dispatch(A actionState, [Map<String, dynamic> data]);
}
