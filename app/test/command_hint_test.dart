import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/assistant/domain/command_hint.dart';

void main() {
  test('ordinary learning content skips the intent route', () {
    expect(mightBeAppCommand('tree'), isFalse);
    expect(mightBeAppCommand('我喜欢你'), isFalse);
    expect(mightBeAppCommand('I saw a tree in the park.'), isFalse);
    expect(
      mightBeAppCommand(
        'This is a long sentence about a challenge I watched on television yesterday.',
      ),
      isFalse,
    );
  });

  test('short command-like input is routed', () {
    expect(mightBeAppCommand('my words'), isTrue);
    expect(mightBeAppCommand('review vocabulary'), isTrue);
    expect(mightBeAppCommand('start a challenge'), isTrue);
    expect(mightBeAppCommand('看看我的单词'), isTrue);
    expect(mightBeAppCommand('我要复习一下词语'), isTrue);
  });
}
