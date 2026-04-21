extension PreciseNumberFormatting on num {
  String formatPrecise({int maxDecimals = 4}) {
    if (this is double) {
      final value = this as double;
      if (value.isNaN || value.isInfinite) return '0';
    }

    if (this == 0) return '0';

    var text = toString();
    if (text.contains('e') || text.contains('E')) {
      text = toStringAsFixed(maxDecimals);
    } else if (this is double) {
      text = (this as double).toStringAsFixed(maxDecimals);
    }

    if (!text.contains('.')) return text;

    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }
}
