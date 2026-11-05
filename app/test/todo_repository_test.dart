import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/todo_demo/data/api/todo_api.dart';
import 'package:named/features/todo_demo/data/repositories/todo_repository.dart';

void main() {
  test('maps API json to Todo domain model', () async {
    const repository = TodoRepository(
      _FakeTodoApi({
        'userId': 1,
        'id': 1,
        'title': 'delectus aut autem',
        'completed': false,
      }),
    );

    final todo = await repository.fetchTodo(1);

    expect(todo?.id, 1);
    expect(todo?.userId, 1);
    expect(todo?.title, 'delectus aut autem');
    expect(todo?.completed, isFalse);
  });

  test('returns null for empty mock payloads', () async {
    const repository = TodoRepository(_FakeTodoApi({}));

    expect(await repository.fetchTodo(0), isNull);
  });
}

class _FakeTodoApi implements TodoApi {
  const _FakeTodoApi(this.response);

  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> fetchTodo(int id) async {
    return response;
  }
}
