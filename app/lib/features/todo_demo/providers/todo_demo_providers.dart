import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/todo_api.dart';
import '../data/repositories/todo_repository.dart';
import '../domain/todo.dart';

/// Demo scenario ids used by [TodoDemoPage].
class TodoDemoScenario {
  const TodoDemoScenario._();

  static const successId = 1;
  static const emptyId = 0;
  static const errorId = -1;
}

class TodoDemoScenarioNotifier extends Notifier<int> {
  @override
  int build() => TodoDemoScenario.successId;

  void setScenario(int scenarioId) {
    state = scenarioId;
  }
}

final todoDemoScenarioProvider =
    NotifierProvider<TodoDemoScenarioNotifier, int>(
      TodoDemoScenarioNotifier.new,
    );

final todoApiProvider = Provider<TodoApi>((ref) {
  final dio = ref.watch(dioProvider);
  final config = ref.watch(appConfigProvider);
  final scenarioId = ref.watch(todoDemoScenarioProvider);

  // Empty / error scenarios always use the local mock so the demo works
  // offline and can exercise the global error toast path.
  if (config.useMockApi || scenarioId != TodoDemoScenario.successId) {
    return MockTodoApi(dio);
  }
  return RemoteTodoApi(dio);
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository(ref.watch(todoApiProvider));
});

final demoTodoProvider = FutureProvider.autoDispose<Todo?>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  final scenarioId = ref.watch(todoDemoScenarioProvider);
  return repository.fetchTodo(scenarioId);
});
