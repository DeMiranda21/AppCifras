import 'package:appcifras/aplicacao/pesquisa/servico_pesquisa_musicas.dart';
import 'package:appcifras/aplicacao/portas/repositorio_classificacao_musica.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/energia_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/tag_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();
  const servico = ServicoPesquisaMusicas();

  Musica musica(String id, String titulo, String artista, String conteudo) =>
      Musica(
        id: IdMusica(id),
        documento: parser.interpretar(
          '{title: $titulo}\n{artist: $artista}\n{key: C}\n$conteudo',
        ),
      );

  test(
    'pesquisa título, artista e letra preservando a ordem da Biblioteca',
    () {
      final titulo = musica('1', 'Graça Suprema', 'Artista', '[C]Letra');
      final artista = musica('2', 'Outra', 'Ministério da Graça', '[C]Letra');
      final letra = musica(
        '3',
        'Terceira',
        'Artista',
        '[C]Tua graça me alcançou',
      );
      final fora = musica('4', 'Quarta', 'Artista', '[C]Outro conteúdo');

      final indice = servico.criarIndice([titulo, artista, letra, fora]);

      expect(indice.filtrar(ConsultaPesquisaMusicas(texto: 'graca')), [
        titulo,
        artista,
        letra,
      ]);
    },
  );

  test('normaliza caixa, acentos, espaços e expressão completa', () {
    final musicaComLetra = musica(
      'musica-1',
      'Nome',
      'Artista',
      '[C]O Espírito Santo está aqui',
    );
    final indice = servico.criarIndice([musicaComLetra]);

    expect(
      indice.filtrar(ConsultaPesquisaMusicas(texto: '  ESPIRITO   SANTO  ')),
      [musicaComLetra],
    );
  });

  test('consulta vazia restaura todas as músicas e inexistente não retorna nenhuma', () {
    final primeira = musica('1', 'Primeira', 'Artista', '[C]Letra');
    final segunda = musica('2', 'Segunda', 'Artista', '[D]Letra');
    final indice = servico.criarIndice([primeira, segunda]);

    expect(indice.filtrar(ConsultaPesquisaMusicas()), [primeira, segunda]);
    expect(
      indice.filtrar(ConsultaPesquisaMusicas(texto: 'inexistente')),
      isEmpty,
    );
  });

  test('não indexa acordes nem diretivas técnicas', () {
    final musicaComAcorde = musica(
      'musica-1',
      'Nome',
      'Artista',
      '{appcifras_schema: 1}\n'
          '{appcifras_id: musica-1}\n'
          '{appcifras_block_break}\n'
          '{comment: comentário técnico}\n'
          '[C#m7]Grande é o Senhor',
    );
    final indice = servico.criarIndice([musicaComAcorde]);

    expect(
      indice.filtrar(ConsultaPesquisaMusicas(texto: 'grande e o senhor')),
      [musicaComAcorde],
    );
    expect(indice.filtrar(ConsultaPesquisaMusicas(texto: 'c#m7')), isEmpty);
    expect(
      indice.filtrar(ConsultaPesquisaMusicas(texto: 'appcifras')),
      isEmpty,
    );
    expect(indice.filtrar(ConsultaPesquisaMusicas(texto: 'musica-1')), isEmpty);
    expect(
      indice.filtrar(ConsultaPesquisaMusicas(texto: 'block_break')),
      isEmpty,
    );
    expect(
      indice.filtrar(ConsultaPesquisaMusicas(texto: 'comentario tecnico')),
      isEmpty,
    );
  });

  test('mantém conteúdo malformado visível pesquisável', () {
    final musicaMalformada = musica(
      '1',
      'Nome',
      'Artista',
      'Texto [sem fechamento com esperança',
    );
    final indice = servico.criarIndice([musicaMalformada]);

    expect(indice.filtrar(ConsultaPesquisaMusicas(texto: 'esperanca')), [
      musicaMalformada,
    ]);
  });

  test('filtra por energia, inclusive músicas sem classificação', () {
    final calma = musica('1', 'Calma', 'Artista', '[C]Letra');
    final moderada = musica('2', 'Moderada', 'Artista', '[C]Letra');
    final animada = musica('3', 'Animada', 'Artista', '[C]Letra');
    final semEnergia = musica('4', 'Sem energia', 'Artista', '[C]Letra');
    final indice = servico.criarIndice(
      [calma, moderada, animada, semEnergia],
      classificacoes: {
        calma.id: const ClassificacaoMusica(energia: EnergiaMusica.calma),
        moderada.id: const ClassificacaoMusica(energia: EnergiaMusica.moderada),
        animada.id: const ClassificacaoMusica(energia: EnergiaMusica.animada),
      },
    );

    expect(indice.filtrar(ConsultaPesquisaMusicas()), [
      calma,
      moderada,
      animada,
      semEnergia,
    ]);
    expect(
      indice.filtrar(ConsultaPesquisaMusicas(energia: EnergiaMusica.calma)),
      [calma],
    );
    expect(
      indice.filtrar(ConsultaPesquisaMusicas(energia: EnergiaMusica.moderada)),
      [moderada],
    );
    expect(
      indice.filtrar(ConsultaPesquisaMusicas(energia: EnergiaMusica.animada)),
      [animada],
    );
  });

  test('filtra tags com AND respeitando identidade sem diferença de caixa', () {
    final ceia = musica('1', 'Ceia', 'Artista', '[C]Letra');
    final ambas = musica('2', 'Ambas', 'Artista', '[C]Letra');
    final semTags = musica('3', 'Sem tags', 'Artista', '[C]Letra');
    final indice = servico.criarIndice(
      [ceia, ambas, semTags],
      classificacoes: {
        ceia.id: ClassificacaoMusica(tags: [TagMusica('Ceia')]),
        ambas.id: ClassificacaoMusica(
          tags: [TagMusica('ceia'), TagMusica('Congregacional')],
        ),
      },
    );

    expect(indice.filtrar(ConsultaPesquisaMusicas(tags: [TagMusica('CEIA')])), [
      ceia,
      ambas,
    ]);
    expect(
      indice.filtrar(
        ConsultaPesquisaMusicas(
          tags: [TagMusica('ceia'), TagMusica('congregacional')],
        ),
      ),
      [ambas],
    );
    expect(indice.tagsDisponiveis, [
      TagMusica('Ceia'),
      TagMusica('Congregacional'),
    ]);
  });

  test('combina texto, energia e tags preservando a ordem da Biblioteca', () {
    final primeira = musica('1', 'Graça', 'Artista', '[C]Letra');
    final segunda = musica('2', 'Graça', 'Artista', '[C]Letra');
    final terceira = musica('3', 'Outra', 'Artista', '[C]Letra');
    final indice = servico.criarIndice(
      [primeira, segunda, terceira],
      classificacoes: {
        primeira.id: ClassificacaoMusica(
          energia: EnergiaMusica.calma,
          tags: [TagMusica('Ceia'), TagMusica('Congregacional')],
        ),
        segunda.id: ClassificacaoMusica(
          energia: EnergiaMusica.animada,
          tags: [TagMusica('Ceia')],
        ),
        terceira.id: ClassificacaoMusica(
          energia: EnergiaMusica.calma,
          tags: [TagMusica('Ceia')],
        ),
      },
    );

    expect(
      indice.filtrar(
        ConsultaPesquisaMusicas(
          texto: 'graca',
          energia: EnergiaMusica.calma,
          tags: [TagMusica('ceia'), TagMusica('congregacional')],
        ),
      ),
      [primeira],
    );
  });

  test('retorna a primeira linha visível correspondente sem acordes', () {
    final musicaComLetra = musica(
      'musica-1',
      'Nome',
      'Artista',
      '[C]Primeira graça\n[G]Segunda Graça para cantar',
    );
    final indice = servico.criarIndice([musicaComLetra]);

    final resultado = indice
        .pesquisar(ConsultaPesquisaMusicas(texto: 'graca'))
        .single;

    expect(resultado.musica, musicaComLetra);
    expect(resultado.trechoLetra, 'Primeira graça');
  });

  test('não mostra trecho quando a correspondência é somente metadado', () {
    final porTitulo = musica(
      'titulo',
      'Graça no título',
      'Artista',
      '[C]Letra sem correspondência',
    );
    final porArtista = musica(
      'artista',
      'Título',
      'Ministério da Graça',
      '[C]Outra letra',
    );
    final indice = servico.criarIndice([porTitulo, porArtista]);

    final resultados = indice.pesquisar(
      ConsultaPesquisaMusicas(texto: 'graca'),
    );

    expect(resultados.map((resultado) => resultado.musica), [
      porTitulo,
      porArtista,
    ]);
    expect(resultados.map((resultado) => resultado.trechoLetra), [null, null]);
  });

  test('não usa diretiva ou combinação entre linhas como trecho da letra', () {
    final musicaComDiretiva = musica(
      'musica-1',
      'Nome',
      'Artista',
      '{comment: graça técnica}\n'
          '[C]Graça visível\n'
          'O Espírito\n'
          'Santo está aqui',
    );
    final indice = servico.criarIndice(
      [musicaComDiretiva],
      classificacoes: {
        musicaComDiretiva.id: const ClassificacaoMusica(
          energia: EnergiaMusica.calma,
        ),
      },
    );

    expect(
      indice
          .pesquisar(ConsultaPesquisaMusicas(texto: 'graca'))
          .single
          .trechoLetra,
      'Graça visível',
    );
    expect(
      indice
          .pesquisar(ConsultaPesquisaMusicas(texto: 'espirito santo'))
          .single
          .trechoLetra,
      isNull,
    );
    expect(
      indice
          .pesquisar(ConsultaPesquisaMusicas(energia: EnergiaMusica.calma))
          .single
          .trechoLetra,
      isNull,
    );
  });
}
