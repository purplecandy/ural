import 'package:flutter/material.dart';

import 'package:ural/models/screen_model.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/database.dart';
import 'package:ural/prefrences.dart';

enum SearchStates {
  ///Initial state, no screenshots or error messages are displayed
  idle,

  ///Searching shows an ongoing process
  searching,

  ///The search has been completed
  done,

  ///A special state in-case if the search was performed but couldn't find any match
  empty
}
enum SearchAction {
  /// Performs a search with the specified query on the database
  ///
  /// Requires:  `String:query` and `UralPreferences:ural_pref` and `Set<int>:filters`
  fetch,
  reset
}

class SearchScreenBloc
    extends BlocBase<SearchStates, SearchAction, List<ScreenshotModel>> {
  ScreenshotListDatabase _slDB;
  SearchScreenBloc()
      : super(state: SearchStates.idle, object: List<ScreenshotModel>());

  /// Initialize database
  void initializeDatabase(ScreenshotListDatabase db) {
    _slDB = db;
  }

  @override
  void dispose() {
    super.dispose();
  }

  int count = 0;
  @override
  void dispatch(SearchAction actionState, [Map<String, dynamic> data]) {
    count++;
    print(count);
    switch (actionState) {
      case SearchAction.fetch:
        _find(data["query"], data["ural_pref"], data["filters"] ?? Set<int>());
        break;
      case SearchAction.reset:
        // state.currentState = SearchStates.idle;
        // updateState(SearchStates.idle, event.object);
        break;
      default:
    }
  }

  void _find(String query, UralPrefrences prefrences,
      [Set<int> filters]) async {
    updateState(SearchStates.searching, event.object);
    var newState;
    _slDB.find(query, filter: filters).then((screenshots) {
      if (screenshots.length > 0) {
        newState = SearchStates.done;
        prefrences.updateRecentSearches(query);
      } else {
        newState = SearchStates.empty;
      }
      updateState(newState, screenshots);
    });
  }
}

/// Representative of Searchfield states and actions
enum SearchFieldState {
  ///Everytime there change in textfield it doesn't counts empty changes
  change,

  ///Reset is the initial state and it's also active when the textfield goes blank
  reset,

  ///This state is active when the user taps on any previours searched values. The textfield value gets updated with the recent query.
  ///
  ///Requries:`String:recent_query`
  recent
}

class SearchFieldBloc
    extends BlocBase<SearchFieldState, SearchFieldState, String> {
  TextEditingController _fieldController;
  String _previousValue = "";

  SearchFieldBloc() : super(state: SearchFieldState.reset, object: "");

  void initialize(TextEditingController controller) {
    _fieldController = controller;
    _fieldController.addListener(handleTextField);
  }

  @override
  void dispatch(SearchFieldState actionState, [Map<String, dynamic> data]) {
    switch (actionState) {
      case SearchFieldState.change:
        updateState(SearchFieldState.change, _fieldController.text);
        break;
      case SearchFieldState.reset:
        updateState(SearchFieldState.reset, _fieldController.text);
        break;
      case SearchFieldState.recent:
        _recentSearch(data["recent_query"]);
        break;
      default:
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void handleTextField() {
    if (_fieldController.text.length == 0) {
      dispatch(SearchFieldState.reset);
    } else {
      if (_previousValue != _fieldController.text) {
        dispatch(SearchFieldState.change);
        _previousValue = _fieldController.text;
      }
    }
  }

  void _recentSearch(String query) {
    //this updates the current value displayed in the textfield
    _fieldController.text = query;
    updateState(SearchFieldState.change, query);
  }

  String getText() => _fieldController.text;
}

enum FilterState { contains, empty }
enum FilterAction {
  ///Requires: `int:id`
  add,

  ///Requires: `int:id`
  del,

  reset
}

class FilterTagsBloc extends BlocBase<FilterState, FilterAction, Set<int>> {
  FilterTagsBloc() : super(state: FilterState.empty, object: Set());

  @override
  void dispatch(FilterAction actionState, [Map<String, dynamic> data]) {
    switch (actionState) {
      case FilterAction.add:
        event.object.add(data["id"]);
        updateState(FilterState.contains, event.object);
        break;
      case FilterAction.del:
        event.object.remove(data["id"]);
        updateState(
            event.object.isEmpty ? FilterState.empty : FilterState.contains,
            event.object);
        break;
      case FilterAction.reset:
        updateState(FilterState.empty, Set<int>());
        break;
      default:
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
