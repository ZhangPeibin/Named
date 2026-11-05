import '../../domain/todo.dart';
import '../api/todo_api.dart';

class TodoRepository {
  const TodoRepository(this._api);

  final TodoApi _api;

  Future<Todo?> fetchTodo(int id) async {
    final json = await _api.fetchTodo(id);
    if (json.isEmpty) {
      return null;
    }
    return Todo.fromJson(json);
  }
}
