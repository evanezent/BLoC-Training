import 'dart:async';

import 'package:fire/bloc/filtered/filtered_event.dart';
import 'package:fire/bloc/filtered/filtered_state.dart';
import 'package:fire/bloc/todos/todos.dart';
import 'package:fire/models/visibility_filter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:todos_repository/todos_repository.dart';

class FilteredTodosBloc extends Bloc<FilteredTodosEvent, FilteredTodosState> {
  final TodosBloc _todosBloc;
  StreamSubscription _todosSubscription;

  FilteredTodosBloc({@required TodosBloc todosBloc})
      : assert(todosBloc != null),
        _todosBloc = todosBloc,
        super(todosBloc.state is TodosLoaded
            ? FilteredTodosLoaded(
                (todosBloc.state as TodosLoaded).todos,
                VisibilityFilter.all,
              )
            : FilteredTodosLoading()) {
    _todosSubscription = todosBloc.listen((state) {
      if (state is TodosLoaded) {
        add(UpdateTodos((todosBloc.state as TodosLoaded).todos));
      }
    });
  }

  @override
  Stream<FilteredTodosState> mapEventToState(FilteredTodosEvent event) async* {
    if (event is UpdateFilter) {
      yield* _mapUpdateFilterToState(event);
    } else if (event is UpdateTodos) {
      yield* _mapTodosUpdatedToState(event);
    }
  }

  Stream<FilteredTodosState> _mapUpdateFilterToState(
    UpdateFilter event,
  ) async* {
    final currentState = _todosBloc.state;
    if (currentState is TodosLoaded) {
      yield FilteredTodosLoaded(
        _mapTodosToFilteredTodos(currentState.todos, event.filter),
        event.filter,
      );
    }
  }

  Stream<FilteredTodosState> _mapTodosUpdatedToState(
    UpdateTodos event,
  ) async* {
    final visibilityFilter = state is FilteredTodosLoaded
        ? (state as FilteredTodosLoaded).activeFilter
        : VisibilityFilter.all;
    yield FilteredTodosLoaded(
      _mapTodosToFilteredTodos(
        (_todosBloc.state as TodosLoaded).todos,
        visibilityFilter,
      ),
      visibilityFilter,
    );
  }

  List<Todo> _mapTodosToFilteredTodos(
      List<Todo> todos, VisibilityFilter filter) {
    return todos.where((todo) {
      if (filter == VisibilityFilter.all) {
        return true;
      } else if (filter == VisibilityFilter.active) {
        return !todo.complete;
      } else {
        return todo.complete;
      }
    }).toList();
  }

  @override
  Future<void> close() {
    _todosSubscription?.cancel();
    return super.close();
  }
}
