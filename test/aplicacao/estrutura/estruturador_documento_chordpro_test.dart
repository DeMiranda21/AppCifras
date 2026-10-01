import 'package:appcifras/aplicacao/estrutura/estrutura_musica.dart';
import 'package:appcifras/aplicacao/estrutura/reconhecedor_secao_musica.dart';
import 'package:appcifras/dominio/chordpro/documento_chordpro.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();
  final estruturador = EstruturadorDocumentoChordPro();

  EstruturaMusica estruturar(String conteudo) =>
      estruturador.estruturar(parser.interpretar(conteudo));

  group('EstruturadorDocumentoChordPro', () {
    test('reconhece todos os rótulos textuais aprovados sem normalizá-los', () {
      final estrutura = estruturar(
        'Intro\nI\n'
        'VERSO II\nV\n'
        'Pré-Refrão:\nP\n'
        '[Refrão]\nR\n'
        'Ponte\nB\n'
        'Instrumental\nN\n'
        'Solo\nS\n'
        'Final\nF',
      );

      expect(
        estrutura.secoes.map((secao) => secao.tipo),
        orderedEquals([
          TipoSecaoMusica.intro,
          TipoSecaoMusica.verso,
          TipoSecaoMusica.preRefrao,
          TipoSecaoMusica.refrao,
          TipoSecaoMusica.ponte,
          TipoSecaoMusica.instrumental,
          TipoSecaoMusica.solo,
          TipoSecaoMusica.encerramento,
        ]),
      );
      expect(
        estrutura.secoes.map((secao) => secao.rotuloOriginal),
        orderedEquals([
          'Intro',
          'VERSO II',
          'Pré-Refrão:',
          '[Refrão]',
          'Ponte',
          'Instrumental',
          'Solo',
          'Final',
        ]),
      );
      expect(
        estrutura.secoes.map((secao) => _conteudo(secao)),
        orderedEquals(['I', 'V', 'P', 'R', 'B', 'N', 'S', 'F']),
      );
    });

    test('reconhece verso numerado, parte e coro com caixa e acento', () {
      final estrutura = estruturar(
        'Verso 1\nA\nSegunda Parte\nB\nCORO\nC\nIntrodução\nD',
      );

      expect(
        estrutura.secoes.map((secao) => secao.tipo),
        orderedEquals([
          TipoSecaoMusica.verso,
          TipoSecaoMusica.verso,
          TipoSecaoMusica.refrao,
          TipoSecaoMusica.intro,
        ]),
      );
      expect(estrutura.secoes[0].rotuloOriginal, 'Verso 1');
      expect(estrutura.secoes[1].rotuloOriginal, 'Segunda Parte');
    });

    test('deriva seção de diretivas ChordPro sem mudar o documento', () {
      const conteudo =
          '{start_of_chorus: Refrão}\n[C]Grande é o Senhor\n{end_of_chorus}';
      final estrutura = estruturar(conteudo);

      expect(estrutura.documento.conteudoOriginal, conteudo);
      expect(estrutura.secoes, hasLength(1));
      final secao = estrutura.secoes.single;
      expect(secao.tipo, TipoSecaoMusica.refrao);
      expect(secao.rotuloOriginal, 'Refrão');
      expect(secao.indiceMarcador, 0);
      expect(secao.inicioConteudo, 1);
      expect(secao.fimConteudoExclusivo, 2);
      expect(_conteudo(secao), '[C]Grande é o Senhor');
    });

    test(
      'reconhece diretiva estrutural conhecida ainda tolerada pelo parser',
      () {
        final estrutura = estruturar(
          '{start_of_bridge: Ponte}\n[D]Texto\n{end_of_bridge}',
        );

        expect(estrutura.secoes.single.tipo, TipoSecaoMusica.ponte);
        expect(estrutura.secoes.single.rotuloOriginal, 'Ponte');
        expect(_conteudo(estrutura.secoes.single), '[D]Texto');
      },
    );

    test('mantém marcador estrutural desconhecido como outro', () {
      final estrutura = estruturar(
        '{start_of_interlude: Interlúdio}\n[C]Passagem\n{end_of_interlude}',
      );

      expect(estrutura.secoes.single.tipo, TipoSecaoMusica.outro);
      expect(estrutura.secoes.single.rotuloOriginal, 'Interlúdio');
      expect(_conteudo(estrutura.secoes.single), '[C]Passagem');
    });

    test('não transforma texto comum ou rótulo desconhecido em seção', () {
      final estrutura = estruturar('Volta ao refrão\nInterlúdio\n[C]Letra');

      expect(estrutura.secoes, hasLength(1));
      expect(estrutura.secoes.single.ehImplicita, isTrue);
      expect(estrutura.secoes.single.tipo, TipoSecaoMusica.outro);
      expect(
        _conteudo(estrutura.secoes.single),
        'Volta ao refrão\nInterlúdio\n[C]Letra',
      );
    });

    test('mantém conteúdo anterior à primeira seção em faixa implícita', () {
      final estrutura = estruturar(
        '{title: Música}\n{artist: Artista}\n{key: G}\n[G]Abertura\nVerso 1\n[D]Letra',
      );

      expect(estrutura.secoes, hasLength(2));
      final abertura = estrutura.secoes.first;
      expect(abertura.ehImplicita, isTrue);
      expect(abertura.indiceMarcador, isNull);
      expect(abertura.inicioConteudo, 0);
      expect(abertura.fimConteudoExclusivo, 4);
      expect(_conteudo(abertura), contains('[G]Abertura'));
      expect(estrutura.secoes.last.tipo, TipoSecaoMusica.verso);
      expect(_conteudo(estrutura.secoes.last), '[D]Letra');
    });

    test('mantém seções consecutivas como seções vazias válidas', () {
      final estrutura = estruturar('Intro\nRefrão\n[C]Letra');

      expect(estrutura.secoes, hasLength(2));
      expect(estrutura.secoes.first.tipo, TipoSecaoMusica.intro);
      expect(estrutura.secoes.first.elementos, isEmpty);
      expect(estrutura.secoes.last.tipo, TipoSecaoMusica.refrao);
      expect(_conteudo(estrutura.secoes.last), '[C]Letra');
    });

    test('preserva acordes, diretivas desconhecidas e linhas toleradas', () {
      const conteudo =
          'Verso 2\n[C]Acorde [H7]não interpretável\n{tempo: 72}\n[ sem fechamento';
      final documento = parser.interpretar(conteudo);
      final estrutura = estruturador.estruturar(documento);

      expect(estrutura.documento, same(documento));
      expect(estrutura.documento.conteudoOriginal, conteudo);
      expect(estrutura.secoes.single.tipo, TipoSecaoMusica.verso);
      expect(estrutura.secoes.single.elementos[0], isA<LinhaChordPro>());
      expect(
        estrutura.secoes.single.elementos.last,
        isA<LinhaNaoInterpretadaChordPro>(),
      );
      expect(_conteudo(estrutura.secoes.single), contains('[H7]'));
    });
  });
}

String _conteudo(SecaoMusica secao) =>
    secao.elementos.map((elemento) => elemento.conteudoOriginal).join('\n');
