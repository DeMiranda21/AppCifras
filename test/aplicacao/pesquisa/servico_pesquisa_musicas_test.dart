import 'package:appcifras/aplicacao/pesquisa/servico_pesquisa_musicas.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
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

      expect(indice.filtrar('graca'), [titulo, artista, letra]);
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

    expect(indice.filtrar('  ESPIRITO   SANTO  '), [musicaComLetra]);
  });

  test('consulta vazia restaura todas as músicas e inexistente não retorna nenhuma', () {
    final primeira = musica('1', 'Primeira', 'Artista', '[C]Letra');
    final segunda = musica('2', 'Segunda', 'Artista', '[D]Letra');
    final indice = servico.criarIndice([primeira, segunda]);

    expect(indice.filtrar('   '), [primeira, segunda]);
    expect(indice.filtrar('inexistente'), isEmpty);
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

    expect(indice.filtrar('grande e o senhor'), [musicaComAcorde]);
    expect(indice.filtrar('c#m7'), isEmpty);
    expect(indice.filtrar('appcifras'), isEmpty);
    expect(indice.filtrar('musica-1'), isEmpty);
    expect(indice.filtrar('block_break'), isEmpty);
    expect(indice.filtrar('comentario tecnico'), isEmpty);
  });

  test('mantém conteúdo malformado visível pesquisável', () {
    final musicaMalformada = musica(
      '1',
      'Nome',
      'Artista',
      'Texto [sem fechamento com esperança',
    );
    final indice = servico.criarIndice([musicaMalformada]);

    expect(indice.filtrar('esperanca'), [musicaMalformada]);
  });
}
