import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/utils/timer_parser.dart';

void main() {
  group('detectTimerSeconds', () {
    test('detect minutes in English', () {
      expect(detectTimerSeconds('Bake for 20 minutes'), 1200);
      expect(detectTimerSeconds('Cook 30 min'), 1800);
      expect(detectTimerSeconds('Wait 45 seconds'), 45);
    });

    test('detect hours', () {
      expect(detectTimerSeconds('Marinate 2 hours'), 7200);
      expect(detectTimerSeconds('Cook for 1 hr'), 3600);
    });

    test('detect Spanish', () {
      expect(detectTimerSeconds('Hornear 15 minutos'), 900);
      expect(detectTimerSeconds('Dejar 1 hora'), 3600);
      expect(detectTimerSeconds('Esperar 30 segundos'), 30);
    });

    test('returns null when no timer', () {
      expect(detectTimerSeconds('Mezclar bien y servir'), isNull);
      expect(detectTimerSeconds(''), isNull);
    });

    test('mixed hours and minutes', () {
      // Solo horas o minutos, el parser actual suma ambos si están presentes
      expect(detectTimerSeconds('Cook for 1 hour 30 minutes'), 5400);
    });
  });

  group('formatTime', () {
    test('formats seconds as mm:ss', () {
      expect(formatTime(90), '01:30');
      expect(formatTime(45), '00:45');
      expect(formatTime(0), '00:00');
    });

    test('formats hours', () {
      expect(formatTime(3600), '1h 00m');
      expect(formatTime(5400), '1h 30m');
      expect(formatTime(3661), '1h 01m');
    });
  });
}
