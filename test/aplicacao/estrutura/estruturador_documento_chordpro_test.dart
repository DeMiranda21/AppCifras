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
    test('trata quebra interna como fronteira entre trechos livres', () {
      const conteudo = '{title: T}\nA\nB\n{appcifras_block_break}\nC\nD';
      final estrutura = estruturar(conteudo);

      expect(estrutura.secoes, hasLength(2));
      expect(_conteudo(estrutura.secoes[0]), 'A\nB');
      expect(_conteudo(estrutura.secoes[1]), 'C\nD');
      expect(
        estrutura.secoes.expand((secao) => secao.elementos),
        isNot(
          contains(
            predicate<ElementoDocumentoChordPro>(
              (elemento) =>
                  elemento.conteudoOriginal == '{appcifras_block_break}',
            ),
          ),
        ),
      );
    });

    test('não insere quebra interna ao estruturar documento sem marcador', () {
      const conteudo = 'A\n\nB';
      final estrutura = estruturar(conteudo);

      expect(estrutura.documento.conteudoOriginal, conteudo);
      expect(estrutura.secoes, hasLength(1));
    });

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

    test('extrai label explícito sem normalizar sua grafia', () {
      final estrutura = estruturar(
        '{start_of_verse: label="VERSO II"}\n[C]Letra\n{end_of_verse}',
      );

      expect(estrutura.secoes.single.tipo, TipoSecaoMusica.verso);
      expect(estrutura.secoes.single.rotuloOriginal, 'VERSO II');
      expect(_conteudo(estrutura.secoes.single), '[C]Letra');
    });

    test('aceita label legado preservando o valor exibido', () {
      final estrutura = estruturar(
        '{start_of_verse: Verso 2}\n[D]Letra\n{end_of_verse}',
      );

      expect(estrutura.secoes.single.tipo, TipoSecaoMusica.verso);
      expect(estrutura.secoes.single.rotuloOriginal, 'Verso 2');
    });

    test('reconhece aliases oficiais sem reescrever o documento', () {
      const conteudo =
          '{sov: label="Verso 2"}\n[C]V\n{eov}\n'
          '{soc: label="Refrão"}\n[G]R\n{eoc}\n'
          '{sob: label="Ponte"}\n[Am]P\n{eob}';
      final estrutura = estruturar(conteudo);

      expect(estrutura.documento.conteudoOriginal, conteudo);
      expect(
        estrutura.secoes.map((secao) => secao.tipo),
        orderedEquals([
          TipoSecaoMusica.verso,
          TipoSecaoMusica.refrao,
          TipoSecaoMusica.ponte,
        ]),
      );
      expect(
        estrutura.secoes.map((secao) => secao.rotuloOriginal),
        orderedEquals(['Verso 2', 'Refrão', 'Ponte']),
      );
    });

    test('reconhece os ambientes canônicos escritos pelo AppCifras', () {
      final estrutura = estruturar(
        '{start_of_intro: label="Intro"}\nI\n{end_of_intro}\n'
        '{start_of_pre_chorus: label="Pré-Refrão"}\nP\n{end_of_pre_chorus}\n'
        '{start_of_instrumental: label="Instrumental"}\nN\n{end_of_instrumental}\n'
        '{start_of_solo: label="Solo"}\nS\n{end_of_solo}\n'
        '{start_of_final: label="Final"}\nF\n{end_of_final}',
      );

      expect(
        estrutura.secoes.map((secao) => secao.tipo),
        orderedEquals([
          TipoSecaoMusica.intro,
          TipoSecaoMusica.preRefrao,
          TipoSecaoMusica.instrumental,
          TipoSecaoMusica.solo,
          TipoSecaoMusica.encerramento,
        ]),
      );
    });

    test('dá precedência ao ambiente sobre um label semanticamente conhecido', () {
      final estrutura = estruturar(
        '{start_of_section: label="Verso 3"}\n[C]Ministração\n{end_of_section}',
      );

      expect(estrutura.secoes.single.tipo, TipoSecaoMusica.outro);
      expect(estrutura.secoes.single.rotuloOriginal, 'Verso 3');
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

    test('fecha somente no delimitador correspondente', () {
      final estrutura = estruturar(
        '{start_of_verse: label="Verso 1"}\n[C]A\n'
        '{end_of_bridge}\n[D]B\n{end_of_verse}\n[E]Depois',
      );

      expect(estrutura.secoes, hasLength(2));
      expect(_conteudo(estrutura.secoes.first), '[C]A\n{end_of_bridge}\n[D]B');
      expect(estrutura.secoes.last.ehImplicita, isTrue);
      expect(_conteudo(estrutura.secoes.last), '[E]Depois');
    });

    test('aceita seção vazia e início sem fim sem invalidar o documento', () {
      final vazia = estruturar(
        '{start_of_intro: label="Intro"}\n{end_of_intro}',
      );
      final semFim = estruturar('{start_of_solo: label="Solo"}\n[Am]Improviso');

      expect(vazia.secoes.single.elementos, isEmpty);
      expect(semFim.secoes.single.tipo, TipoSecaoMusica.solo);
      expect(_conteudo(semFim.secoes.single), '[Am]Improviso');
    });

    test('não deriva trecho de diretiva end sem conteúdo musical', () {
      const conteudo = '{end_of_chorus}\n[C]Letra';
      final estrutura = estruturar(conteudo);

      expect(estrutura.documento.conteudoOriginal, conteudo);
      expect(estrutura.secoes.single.ehImplicita, isTrue);
      expect(_conteudo(estrutura.secoes.single), '[C]Letra');
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
      expect(abertura.inicioConteudo, 3);
      expect(abertura.fimConteudoExclusivo, 4);
      expect(_conteudo(abertura), contains('[G]Abertura'));
      expect(estrutura.secoes.last.tipo, TipoSecaoMusica.verso);
      expect(_conteudo(estrutura.secoes.last), '[D]Letra');
    });

    test('deriva trechos livres antes, entre e depois de seções', () {
      final estrutura = estruturar(
        '{title: T}\n{artist: A}\n{key: C}\n\n'
        '[C]Introdução\n\n'
        '{start_of_verse: label="Verso"}\n[D]Letra\n{end_of_verse}\n\n'
        '[G]Passagem\n\n'
        '{start_of_chorus: label="Refrão"}\n[A]Coro\n{end_of_chorus}\n\n'
        '[E]Final',
      );

      expect(estrutura.secoes, hasLength(5));
      expect(estrutura.secoes[0].ehImplicita, isTrue);
      expect(_conteudo(estrutura.secoes[0]), '[C]Introdução');
      expect(estrutura.secoes[1].tipo, TipoSecaoMusica.verso);
      expect(estrutura.secoes[2].ehImplicita, isTrue);
      expect(_conteudo(estrutura.secoes[2]), '[G]Passagem');
      expect(estrutura.secoes[3].tipo, TipoSecaoMusica.refrao);
      expect(estrutura.secoes[4].ehImplicita, isTrue);
      expect(_conteudo(estrutura.secoes[4]), '[E]Final');
    });

    test(
      'não deriva cartão para documento composto só por diretivas e vazios',
      () {
        final estrutura = estruturar('{title: T}\n\n{artist: A}\n{key: C}\n');

        expect(estrutura.secoes, isEmpty);
      },
    );

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
