import 'package:appcifras/aplicacao/edicao/selecionar_token_texto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const selecionar = SelecionarTokenTexto();

  void esperaFaixa(String texto, int offset, String esperado) {
    final faixa = selecionar.localizar(texto: texto, offset: offset);
    expect(faixa, isNotNull);
    expect(texto.substring(faixa!.inicio, faixa.fim), esperado);
  }

  test('localiza acordes sem quebrar componentes musicais', () {
    for (final acorde in const ['C', 'Am7', 'D/F#', 'F#m7', 'Bb', 'G7(9)']) {
      esperaFaixa(acorde, acorde.length ~/ 2, acorde);
    }
  });

  test('localiza palavras inteiras no início, meio e fim do texto', () {
    const texto = 'Senhor Grande Deus';

    esperaFaixa(texto, 0, 'Senhor');
    esperaFaixa(texto, texto.indexOf('Grande') + 3, 'Grande');
    esperaFaixa(texto, texto.length - 1, 'Deus');
  });

  test('respeita espaço, tabulação e quebras de linha', () {
    const texto = 'C\tAm7\nD/F#\rBb';

    expect(selecionar.localizar(texto: texto, offset: 1), isNull);
    expect(selecionar.localizar(texto: texto, offset: 5), isNull);
    expect(selecionar.localizar(texto: texto, offset: 10), isNull);
    esperaFaixa(texto, 2, 'Am7');
    esperaFaixa(texto, 6, 'D/F#');
    esperaFaixa(texto, texto.length - 1, 'Bb');
  });

  test('exclui pontuação periférica simples', () {
    for (final caso in const [
      ('Senhor,', 2, 'Senhor'),
      ('Deus.', 1, 'Deus'),
      ('(Am7)', 2, 'Am7'),
    ]) {
      esperaFaixa(caso.$1, caso.$2, caso.$3);
    }
  });

  test(
    'mantém acordes entre colchetes como unidade e separa letra adjacente',
    () {
      const texto = '[C]Grande';

      esperaFaixa(texto, 1, '[C]');
      esperaFaixa(texto, 2, '[C]');
      esperaFaixa(texto, 3, 'Grande');
      esperaFaixa('[C]', 0, '[C]');
    },
  );

  test('não seleciona offset inválido, texto vazio ou delimitador', () {
    expect(selecionar.localizar(texto: '', offset: 0), isNull);
    expect(selecionar.localizar(texto: 'C', offset: -1), isNull);
    expect(selecionar.localizar(texto: 'C', offset: 1), isNull);
    expect(selecionar.localizar(texto: ' C', offset: 0), isNull);
    expect(selecionar.localizar(texto: 'C ', offset: 1), isNull);
  });
}
