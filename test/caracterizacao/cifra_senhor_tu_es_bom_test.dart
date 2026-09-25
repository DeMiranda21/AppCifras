import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_musica.dart';
import 'package:appcifras/dominio/chordpro/documento_chordpro.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_acorde.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

const _conteudoReal = '''{title: Senhor, Tu És Bom}

{key: E}


[E5]Senhor, Tu és bom
Tua [B11/D#]misericórdia é pra [D2(6)]sempre [A9/C#]


[E5]Senhor, Tu és bom
Tua [B11/D#]misericórdia é pra [D2(6)]sempre [A9/C#]


{start_of_chorus: Pré-Refrão}
[A2]Todos os povos te [B4]exaltarão
[C7M]De geração em [D2(6)]geração
{end_of_chorus}


{start_of_chorus: Refrão}
Te [E]adorarei, [B4]Aleluia! [D2(6)]Aleluia! [A9]
Te [E]adorarei, [B4]por tudo que [D2(6)]és [A9]
Te [E]adorarei, [B4]Aleluia! [D2(6)]Aleluia! [A9]
Te [E/G#]adora__rei, [Bm7]por tudo que [C7M]és [D2(6)]
Deus é [E]bom [G6] [A9]
{end_of_chorus}


[E5] [D2(6)] [A9/C#]


{start_of_verse: Primeira Parte}
[E5]Senhor, Tu és bom
Tua [B11/D#]misericórdia é pra [D2(6)]sempre [A9/C#]


[E5]Senhor, Tu és bom
Tua [B11/D#]misericórdia é pra [D2(6)]sempre [A9/C#]
{end_of_verse}


{start_of_chorus: Pré-Refrão}
[A2]Todos os povos te [B4]exaltarão
[C7M]De geração em [D2(6)]geração
{end_of_chorus}


{start_of_chorus: Refrão}
Te [E]adorarei, [B4]Aleluia! [D2(6)]Aleluia! [A9]
Te [E]adorarei, [B4]por tudo que [D2(6)]és [A9]
Te [E]adorarei, [B4]Aleluia! [D2(6)]Aleluia! [A9]
Te [E/G#]adora__rei, [Bm7]por tudo que [C7M]és [D2(6)]
Deus é [E]bom [G6] [A9]
{end_of_chorus}


[E5] [D2(6)] [A9/C#]
[E] [G6] [A9]
[E5] [D2(6)] [A9/C#]


{start_of_bridge: Ponte}
[C7M]Deus [B4]é [E5]bom [G6]o tempo [A9]todo
O tempo [E5]todo, [D2(6)]Deus é [A9/C#]bom


Deus é [E5]bom [G6]o tempo [A9]todo
O tempo [E5]todo, [D2(6)]Deus é [A9/C#]bom


[C7M]Deus [B4]é [E5]bom [G6]o tempo [A9]todo
O tempo [E5]todo, [D2(6)]Deus é [A9/C#]bom


Deus é [E5]bom [G6]o tempo [A9]todo
O tempo [E5]todo, [D2(6)]Deus é [A9/C#]bom [C7M] [D2(6)]
{end_of_bridge}


[C#5] [D5] [C#5] [D5]
[C#5] [D5] [C#5] [D5] [E5]
[C#5] [D5] [C#5] [D5]
[C#5] [D5] [C#5] [D5] [G5] [E5]


[C#5] [D5] [C#5] [D5]
[C#5] [D5] [C#5] [D5] [E5]
[C#5] [D5] [C#5] [D5]
[C#5] [D5] [C#5] [D5] [G5] [E5]


{comment: Tab - Passagem}


{start_of_tab}
E|------------------------------------------|
B|------------------------------------------|
G|------------------------------------------|
D|------------------------------------------|
A|-4-5-4-5--4-5-4-5--7-7--------------------|
E|------------------------------------------|


E|------------------------------------------|
B|------------------------------------------|
G|------------------------------------------|
D|------------------------------------------|
A|-4-5-4-5--4-5-4-5--10-7-------------------|
E|------------------------------------------|
{end_of_tab}


{comment: Solo}
[C#5] [D5] [C#5] [D5]
[C#5] [D5] [C#5] [D5] [E5]
[C#5] [D5] [C#5] [D5]
[C#5] [D5] [C#5] [D5] [G5] [E5]
[C#5] [D5] [C#5] [D5]
[C#5] [D5] [C#5] [D5] [E5]
[C#5] [D5] [C#5] [D5]
[C#5] [D5] [C#5] [D5] [G5] [E5]
[E] [B4] [C7M] [D2(6)]


{start_of_chorus: Refrão}


{comment: Tab - Riff 1}


{start_of_tab}
E|------------------------------------------|
B|------------------------------------------|
G|------------------------------------------|
D|------------------------------------------|
A|-2---0-----0-2-5-4-0----------------------|
E|---3---0-3-----------3--------------------|
{end_of_tab}


Te [E]adorarei, [B4]Aleluia! [D2(6)]Aleluia! [A9]
Te [E]adorarei, [B4]por tudo que [D2(6)]és [A9] (Riff 1)
Te [E]adorarei, [B4]Aleluia! [D2(6)]Aleluia! [A9]
Te [E/G#]adora__rei, [Bm7]por tudo que [C7M]és [D2(6)]
Por tudo que [C7M]és [D2(6)]
Por tudo que [C7M]és [D2(6)]
Deus é [E]bom
{end_of_chorus}''';

void main() {
  final parser = ParserDocumentoChordPro();

  group('Caracterização da cifra Senhor, Tu És Bom', () {
    test('preserva a estrutura, diretivas desconhecidas e tablatura', () {
      final documento = parser.interpretar(_conteudoReal);
      final desconhecidas = documento.elementos
          .whereType<DiretivaDesconhecidaChordPro>()
          .toList();

      expect(documento.conteudoOriginal, _conteudoReal);
      expect(
        documento.elementos.whereType<DiretivaTituloChordPro>(),
        hasLength(1),
      );
      expect(
        documento.elementos.whereType<DiretivaTomChordPro>(),
        hasLength(1),
      );
      expect(
        documento.elementos.whereType<InicioRefraoChordPro>(),
        hasLength(5),
      );
      expect(documento.elementos.whereType<FimRefraoChordPro>(), hasLength(5));
      expect(
        desconhecidas.map((diretiva) => diretiva.nome),
        containsAll([
          'start_of_verse',
          'end_of_verse',
          'start_of_bridge',
          'end_of_bridge',
          'comment',
          'start_of_tab',
          'end_of_tab',
        ]),
      );
      expect(
        documento.elementos.whereType<LinhaChordPro>().map(
          (linha) => linha.conteudoOriginal,
        ),
        containsAll([
          'E|------------------------------------------|',
          'A|-4-5-4-5--4-5-4-5--7-7--------------------|',
          'A|-2---0-----0-2-5-4-0----------------------|',
        ]),
      );
    });

    test('interpreta os acordes pertencentes ao subconjunto atual', () {
      final acordes = parser
          .interpretar(_conteudoReal)
          .elementos
          .whereType<LinhaChordPro>()
          .expand((linha) => linha.elementos)
          .whereType<AcordeLinhaChordPro>();

      for (final acorde in [
        'E',
        'E5',
        'B11/D#',
        'A9/C#',
        'B4',
        'C7M',
        'E/G#',
        'Bm7',
        'G6',
        'C#5',
        'D5',
        'G5',
        'D2(6)',
        'A2',
      ]) {
        expect(
          acordes.where((elemento) => elemento.conteudoOriginal == acorde),
          isNotEmpty,
          reason: 'acorde $acorde não foi encontrado',
        );
        expect(
          acordes
              .where((elemento) => elemento.conteudoOriginal == acorde)
              .every((elemento) => elemento.resultado is AcordeInterpretado),
          isTrue,
          reason: 'acorde $acorde deveria ser interpretável',
        );
      }
    });

    test(
      'rejeita o cadastro apenas pelos metadados duplicados do documento final',
      () async {
        final repositorio = _RepositorioFake();
        final cadastro = CadastrarMusica(
          repositorio: repositorio,
          parserDocumento: parser,
          geradorId: _GeradorIdFake(IdMusica('musica-gerada')),
        );
        const cabecalhoFormulario =
            '{title: Senhor, Tu És Bom}\n'
            '{artist: Artista}\n'
            '{key: E}\n';
        final documentoGerado = parser.interpretar(
          '$cabecalhoFormulario$_conteudoReal',
        );

        expect(
          documentoGerado.elementos.whereType<DiretivaTituloChordPro>(),
          hasLength(2),
        );
        expect(
          documentoGerado.elementos.whereType<DiretivaTomChordPro>(),
          hasLength(2),
        );
        expect(
          () =>
              Musica(id: IdMusica('musica-gerada'), documento: documentoGerado),
          throwsArgumentError,
        );
        await expectLater(
          cadastro.executar(
            const DadosCadastroMusica(
              titulo: 'Senhor, Tu És Bom',
              artista: 'Artista',
              tomOriginal: 'E',
              conteudoChordPro: _conteudoReal,
            ),
          ),
          throwsA(
            isA<CadastroMusicaInvalido>().having(
              (erro) => erro.campo,
              'campo',
              CampoCadastroMusica.conteudo,
            ),
          ),
        );
        expect(await repositorio.listar(), isEmpty);
      },
    );
  });
}

class _RepositorioFake implements RepositorioMusicas {
  final List<Musica> _musicas = [];

  @override
  Future<void> excluir(IdMusica id) async {
    _musicas.removeWhere((musica) => musica.id == id);
  }

  @override
  Future<List<Musica>> listar() async => List.unmodifiable(_musicas);

  @override
  Future<Musica?> obterPorId(IdMusica id) async {
    for (final musica in _musicas) {
      if (musica.id == id) {
        return musica;
      }
    }
    return null;
  }

  @override
  Future<void> salvar(Musica musica) async {
    _musicas.add(musica);
  }

  @override
  Future<void> atualizar(Musica musica) async {
    final indice = _musicas.indexWhere((atual) => atual.id == musica.id);
    if (indice < 0) {
      throw StateError('Música não encontrada.');
    }
    _musicas[indice] = musica;
  }
}

class _GeradorIdFake implements GeradorIdMusica {
  const _GeradorIdFake(this._id);

  final IdMusica _id;

  @override
  IdMusica gerar() => _id;
}
