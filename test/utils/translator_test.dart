import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/utils/translator.dart';

void main() {
  group('Translator local dictionary', () {
    test('category translation', () {
      expect(Translator.category('Beef'), 'Ternera');
      expect(Translator.category('Chicken'), 'Pollo');
      expect(Translator.category('UnknownCat'), 'UnknownCat');
    });

    test('area translation', () {
      expect(Translator.area('Mexican'), 'Mexicana');
      expect(Translator.area('Japanese'), 'Japonesa');
      expect(Translator.area('Martian'), 'Martian');
    });

    test('ingredient local lookup via translate', () async {
      expect(await Translator.translate('chicken'), 'pollo');
      expect(await Translator.translate('olive oil'), 'aceite de oliva');
      expect(await Translator.translate('salt'), 'sal');
    });

    test('measure translation', () async {
      expect(await Translator.translate('cup'), 'taza');
      expect(await Translator.translate('tablespoon'), 'cucharada');
    });

    test('empty returns empty', () async {
      expect(await Translator.translate(''), '');
    });

    test('cache works', () async {
      Translator.clearCache();
      final first = await Translator.translate('chicken');
      final second = await Translator.translate('chicken');
      expect(first, second);
    });
  });
}
