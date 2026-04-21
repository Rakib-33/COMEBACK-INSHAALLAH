void main() {
  final text = '''
Running Courses
Filter:
CSE-213
Computer Architecture
Theory, 3 Credit

CSE-215
Data Structures and Algorithms-II
Theory, 3 Credit
''';
  final regex = RegExp(r'([A-Z]{2,4}[-\s]?\d{3})\s+([\s\S]{2,100}?)\s+(Theory|Sessional)\s*,\s*([\d.]+)\s*Credit', caseSensitive: false);
  final matches = regex.allMatches(text);
  for (final m in matches) {
    print('Matched: ${m.group(1)} | ${m.group(2)}');
  }
}
