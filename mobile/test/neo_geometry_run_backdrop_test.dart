import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaijunto/core/theme/neo_brutal_theme.dart';
import 'package:vaijunto/core/ui/neo_geometry_run_backdrop.dart';

Widget _host({bool disableAnimations = false}) => MaterialApp(
      theme: buildNeoBrutalTheme(Brightness.dark),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: const Scaffold(
          body: SizedBox(
            width: 900,
            height: 320,
            child: NeoGeometryRunBackdrop(),
          ),
        ),
      ),
    );

void main() {
  tearDown(() => debugGeometryRunDistance = null);

  testWidgets('percorre trechos distantes sem quebrar o desenho',
      (tester) async {
    // Cobre bem mais que 15 min de percurso (104 px/s ≈ 93 km de mundo em
    // 15 min): se algum slot gerasse índice inválido, o paint estouraria.
    for (final distance in [0.0, 240.0, 96000.0, 4000000.0]) {
      debugGeometryRunDistance = distance;
      await tester.pumpWidget(_host());
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('congela em uma pose quando a animação está desligada',
      (tester) async {
    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    // Sem ticker ativo não há frame pendente para a próxima janela.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
