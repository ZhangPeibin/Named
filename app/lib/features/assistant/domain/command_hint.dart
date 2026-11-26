/// Fast local check for inputs that may be app commands. Ordinary learning
/// content skips the extra `/assistant/route` model call on the critical path.
const _commandHints = <String>[
  'my words',
  'word list',
  'vocabulary',
  'my vocabulary',
  'review',
  'challenge',
  '单词',
  '词汇',
  '词语',
  '复习',
  '练词',
  '背词',
  '挑战',
];

bool mightBeAppCommand(String text) {
  final trimmed = text.trim().toLowerCase();
  if (trimmed.isEmpty || trimmed.length > 48) {
    return false;
  }
  return _commandHints.any(trimmed.contains);
}
