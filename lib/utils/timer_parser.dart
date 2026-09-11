int? detectTimerSeconds(String text) {
  final lower = text.toLowerCase();
  final patterns = [
    RegExp(r'(\d+)\s*hour[s]?'),
    RegExp(r'(\d+)\s*hr[s]?'),
    RegExp(r'(\d+)\s*minute[s]?'),
    RegExp(r'(\d+)\s*min[s]?(?!\w)'),
    RegExp(r'(\d+)\s*second[s]?'),
    RegExp(r'(\d+)\s*sec[s]?(?!\w)'),
    RegExp(r'(\d+)\s*hora[s]?'),
    RegExp(r'(\d+)\s*minuto[s]?'),
    RegExp(r'(\d+)\s*segundo[s]?'),
  ];
  int total = 0;
  final hourMatch =
      patterns[0].firstMatch(lower) ?? patterns[1].firstMatch(lower);
  if (hourMatch != null) total += int.parse(hourMatch.group(1)!) * 3600;
  final minMatch =
      patterns[2].firstMatch(lower) ?? patterns[3].firstMatch(lower);
  if (minMatch != null) total += int.parse(minMatch.group(1)!) * 60;
  final secMatch =
      patterns[4].firstMatch(lower) ?? patterns[5].firstMatch(lower);
  if (secMatch != null) total += int.parse(secMatch.group(1)!);
  final horaMatch = patterns[6].firstMatch(lower);
  if (horaMatch != null) total += int.parse(horaMatch.group(1)!) * 3600;
  final minutoMatch = patterns[7].firstMatch(lower);
  if (minutoMatch != null && minMatch == null)
    total += int.parse(minutoMatch.group(1)!) * 60;
  final segundoMatch = patterns[8].firstMatch(lower);
  if (segundoMatch != null && secMatch == null)
    total += int.parse(segundoMatch.group(1)!);
  return total > 0 ? total : null;
}

String formatTime(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
