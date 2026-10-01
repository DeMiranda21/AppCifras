import 'package:appcifras/aplicacao/edicao/transformar_selecao_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final transformador = TransformarSelecaoChordPro();

  SelecaoTextoChordPro selecaoDe(String texto, String selecionado) {
    final inicio = texto.indexOf(selecionado);
    return SelecaoTextoChordPro(
      inicio: inicio,
      fim: inicio + selecionado.length,
    );
  }

  group('TransformarSelecaoChordPro', () {
    for (final acorde in ['Am7', 'G/B', 'Cadd9']) {
      test('marca $acorde como acorde ChordPro', () {
        final resultado = transformador.marcarComoAcorde(
          'Antes $acorde depois',
          selecaoDe('Antes $acorde depois', acorde),
        );

        expect(resultado.conteudo, 'Antes [$acorde] depois');
        expect(resultado.selecao.inicio, 6);
        expect(resultado.selecao.fim, 6 + acorde.length + 2);
      });
    }

    test('não altera seleção inválida, vazia ou multilinha', () {
      final invalido = transformador.marcarComoAcorde(
        'Antes XYZ depois',
        selecaoDe('Antes XYZ depois', 'XYZ'),
      );
      final vazio = transformador.marcarComoAcorde(
        'Am7',
        const SelecaoTextoChordPro(inicio: 0, fim: 0),
      );
      final multilinha = transformador.marcarComoAcorde(
        'Am7\nG',
        const SelecaoTextoChordPro(inicio: 0, fim: 5),
      );

      expect(invalido.foiTransformado, isFalse);
      expect(vazio.foiTransformado, isFalse);
      expect(multilinha.foiTransformado, isFalse);
      expect(multilinha.conteudo, 'Am7\nG');
    });

    test(
      'trata conteúdo entre colchetes como texto sem duplicar colchetes',
      () {
        const conteudo = 'Antes [XYZ] depois';
        final resultado = transformador.tratarComoTexto(
          conteudo,
          selecaoDe(conteudo, 'XYZ'),
        );

        expect(resultado.conteudo, 'Antes XYZ depois');
        expect(resultado.selecao.inicio, 6);
        expect(resultado.selecao.fim, 9);
        expect(
          transformador.acaoDisponivel(
            'Antes [Am7] depois',
            selecaoDe('Antes [Am7] depois', '[Am7]'),
          ),
          AcaoSelecaoChordPro.tratarComoTexto,
        );
      },
    );

    test('não cria colchetes aninhados para acorde já marcado', () {
      final resultado = transformador.marcarComoAcorde(
        '[Am7]',
        const SelecaoTextoChordPro(inicio: 0, fim: 5),
      );

      expect(resultado.foiTransformado, isFalse);
      expect(resultado.conteudo, '[Am7]');
    });

    test('não marca uma seleção com espaços ou dentro de texto contínuo', () {
      final comEspacos = transformador.marcarComoAcorde(
        ' Am7 ',
        const SelecaoTextoChordPro(inicio: 0, fim: 5),
      );
      final dentroDeTexto = transformador.marcarComoAcorde(
        'xAm7y',
        const SelecaoTextoChordPro(inicio: 1, fim: 4),
      );

      expect(comEspacos.foiTransformado, isFalse);
      expect(dentroDeTexto.foiTransformado, isFalse);
    });

    test('não oferece ação para uma seleção parcial dentro de colchetes', () {
      expect(
        transformador.acaoDisponivel(
          '[Am7]',
          const SelecaoTextoChordPro(inicio: 1, fim: 3),
        ),
        isNull,
      );
    });
  });
}
