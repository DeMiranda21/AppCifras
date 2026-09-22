import 'package:appcifras/aplicacao/entrada/analisador_entrada_musica.dart';
import 'package:appcifras/aplicacao/entrada/resultado_analise_entrada_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final analisador = AnalisadorEntradaMusica();

  bool temAviso(
    ResultadoAnaliseEntradaMusica resultado,
    TipoAvisoAnaliseEntrada tipo, [
    CampoMetadadoEntrada? campo,
  ]) => resultado.avisos.any(
    (aviso) => aviso.tipo == tipo && (campo == null || aviso.campo == campo),
  );

  group('AnalisadorEntradaMusica', () {
    test('classifica ChordPro completo e extrai metadados únicos', () {
      const conteudo =
          '{title: Grande é o Senhor}\n'
          '{artist: Exemplo}\n'
          '{key: F#m}\n'
          '[F#m]Grande é o Senhor';

      final resultado = analisador.analisar(conteudo);

      expect(
        resultado.classificacao,
        ClassificacaoEntradaMusica.chordProConfirmado,
      );
      expect(resultado.conteudoOriginal, conteudo);
      expect(resultado.titulo, 'Grande é o Senhor');
      expect(resultado.artista, 'Exemplo');
      expect(
        resultado.tom,
        const Tom(
          notaFundamental: Nota(
            nome: NomeNota.f,
            alteracao: AlteracaoNota.sustenido,
          ),
          modo: ModoTom.menor,
        ),
      );
      expect(resultado.requerConversao, isFalse);
      expect(resultado.camposObrigatoriosPendentes, isEmpty);
    });

    test('confirma ChordPro por acorde delimitado e preserva pendências', () {
      final resultado = analisador.analisar('[G]Grande é o Senhor');

      expect(
        resultado.classificacao,
        ClassificacaoEntradaMusica.chordProConfirmado,
      );
      expect(resultado.camposObrigatoriosPendentes, [
        CampoMetadadoEntrada.titulo,
        CampoMetadadoEntrada.artista,
        CampoMetadadoEntrada.tom,
      ]);
      expect(
        temAviso(
          resultado,
          TipoAvisoAnaliseEntrada.metadadoAusente,
          CampoMetadadoEntrada.titulo,
        ),
        isTrue,
      );
    });

    test('reconhece Tom explícito e cifra textual sem converter', () {
      const conteudo = 'Tom: E\n\nE5 B11/D# D2(6) A9/C#\nSenhor, Tu és bom';

      final resultado = analisador.analisar(conteudo);

      expect(
        resultado.classificacao,
        ClassificacaoEntradaMusica.cifraTextualProvavel,
      );
      expect(
        resultado.tom,
        const Tom(
          notaFundamental: Nota(nome: NomeNota.e),
          modo: ModoTom.maior,
        ),
      );
      expect(resultado.possuiLinhaDeAcordesProvavel, isTrue);
      expect(resultado.requerConversao, isTrue);
      expect(resultado.titulo, isNull);
      expect(resultado.artista, isNull);
    });

    test(
      'reconhece linha de acordes sobre letra como cifra textual provável',
      () {
        final resultado = analisador.analisar(
          '     B11/D#             D2(6) A9/C#\n'
          'Tua misericórdia é pra sempre',
        );

        expect(
          resultado.classificacao,
          ClassificacaoEntradaMusica.cifraTextualProvavel,
        );
        expect(resultado.possuiLinhaDeAcordesProvavel, isTrue);
      },
    );

    test('mantém texto comum como entrada ambígua', () {
      final resultado = analisador.analisar('Uma letra comum sem acordes.');

      expect(resultado.classificacao, ClassificacaoEntradaMusica.ambigua);
      expect(
        temAviso(resultado, TipoAvisoAnaliseEntrada.formatoAmbiguo),
        isTrue,
      );
    });

    for (final rotulo in [
      'Intro',
      'Primeira Parte',
      'Verso',
      'Pré-Refrão',
      'Refrão',
      'Ponte',
      'Final',
    ]) {
      test('reconhece rótulo de seção textual: $rotulo', () {
        final resultado = analisador.analisar('[$rotulo]');

        expect(
          resultado.classificacao,
          ClassificacaoEntradaMusica.cifraTextualProvavel,
        );
        expect(resultado.possuiRotulosDeSecao, isTrue);
      });
    }

    test('classifica ChordPro parcial e aponta metadado ausente', () {
      final resultado = analisador.analisar(
        '{title: Título}\n{key: Bb}\n[G]Letra',
      );

      expect(
        resultado.classificacao,
        ClassificacaoEntradaMusica.chordProConfirmado,
      );
      expect(resultado.titulo, 'Título');
      expect(resultado.artista, isNull);
      expect(
        resultado.tom,
        const Tom(
          notaFundamental: Nota(
            nome: NomeNota.b,
            alteracao: AlteracaoNota.bemol,
          ),
          modo: ModoTom.maior,
        ),
      );
      expect(
        temAviso(
          resultado,
          TipoAvisoAnaliseEntrada.metadadoAusente,
          CampoMetadadoEntrada.artista,
        ),
        isTrue,
      );
    });

    test('preserva diretiva desconhecida como entrada ambígua', () {
      final resultado = analisador.analisar('{comment: ensaio}\nLetra');

      expect(resultado.classificacao, ClassificacaoEntradaMusica.ambigua);
      expect(
        resultado.avisos.any(
          (aviso) =>
              aviso.tipo == TipoAvisoAnaliseEntrada.diretivaDesconhecida &&
              aviso.detalhe == 'comment',
        ),
        isTrue,
      );
    });

    test('não confirma ChordPro por colchete que não é acorde', () {
      final resultado = analisador.analisar('[Observação] Letra');

      expect(resultado.classificacao, ClassificacaoEntradaMusica.ambigua);
      expect(
        resultado.avisos.any(
          (aviso) =>
              aviso.tipo == TipoAvisoAnaliseEntrada.acordeNaoInterpretavel &&
              aviso.detalhe == 'Observação',
        ),
        isTrue,
      );
    });

    test('não escolhe metadados ChordPro duplicados', () {
      final resultado = analisador.analisar(
        '{title: Primeiro}\n'
        '{title: Segundo}\n'
        '{artist: Artista}\n'
        '{key: C}\n'
        '{key: D}',
      );

      expect(
        resultado.classificacao,
        ClassificacaoEntradaMusica.chordProConfirmado,
      );
      expect(resultado.titulo, isNull);
      expect(resultado.tom, isNull);
      expect(
        temAviso(
          resultado,
          TipoAvisoAnaliseEntrada.metadadoDuplicado,
          CampoMetadadoEntrada.titulo,
        ),
        isTrue,
      );
      expect(
        temAviso(
          resultado,
          TipoAvisoAnaliseEntrada.metadadoDuplicado,
          CampoMetadadoEntrada.tom,
        ),
        isTrue,
      );
    });

    test('classifica entrada vazia como ambígua sem converter', () {
      final resultado = analisador.analisar('');

      expect(resultado.classificacao, ClassificacaoEntradaMusica.ambigua);
      expect(temAviso(resultado, TipoAvisoAnaliseEntrada.entradaVazia), isTrue);
      expect(resultado.requerConversao, isTrue);
    });
  });
}
