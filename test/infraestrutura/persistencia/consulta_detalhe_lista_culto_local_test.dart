import 'dart:io';

import 'package:appcifras/dominio/entidades/item_lista_culto.dart';
import 'package:appcifras/dominio/entidades/lista_culto.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_item_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/consulta_detalhe_lista_culto_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_listas_culto_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();
  late Directory diretorio;
  late BancoBiblioteca banco;
  late _ArmazenamentoContado arquivos;
  late RepositorioMusicasLocal musicas;
  late RepositorioListasCultoLocal listas;

  Musica musica(String id, String titulo) => Musica(
    id: IdMusica(id),
    documento: parser.interpretar(
      '{title: $titulo}\n{artist: Artista $id}\n{key: C}\n[C]Letra',
    ),
  );

  setUp(() async {
    diretorio = await Directory.systemTemp.createTemp('appcifras_detalhe_');
    banco = BancoBiblioteca(NativeDatabase.memory());
    arquivos = _ArmazenamentoContado(diretorio);
    musicas = RepositorioMusicasLocal(
      banco: banco,
      armazenamentoArquivos: arquivos,
      parserDocumento: parser,
    );
    listas = RepositorioListasCultoLocal(banco);
  });

  tearDown(() async {
    await banco.close();
    await diretorio.delete(recursive: true);
  });

  test(
    'carrega somente catálogo e versões concretas únicas dos itens',
    () async {
      final musicaUm = musica('musica-1', 'Caminho');
      final musicaDois = musica('musica-2', 'Esperança');
      final musicaForaDaLista = musica('musica-3', 'Não usada');
      await musicas.salvar(musicaUm);
      await musicas.salvar(musicaDois);
      await musicas.salvar(musicaForaDaLista);
      final alternativa = VersaoMusica(
        id: IdVersaoMusica('versao-alternativa'),
        idMusica: musicaUm.id,
        nome: 'Acústica',
        documento: parser.interpretar(
          '{title: Caminho}\n{artist: Artista musica-1}\n{key: D}\n[D]Acústica',
        ),
        principal: false,
        arquivada: false,
      );
      await musicas.salvarVersao(alternativa);

      final idLista = IdListaCulto('lista-1');
      await listas.salvar(ListaCulto(id: idLista, nome: 'Culto'));
      await listas.adicionarItem(
        ItemListaCulto(
          id: IdItemListaCulto('item-1'),
          idLista: idLista,
          idMusica: musicaUm.id,
          idVersaoMusica: alternativa.id,
          posicao: 0,
        ),
      );
      await listas.adicionarItem(
        ItemListaCulto(
          id: IdItemListaCulto('item-2'),
          idLista: idLista,
          idMusica: musicaUm.id,
          idVersaoMusica: alternativa.id,
          posicao: 1,
        ),
      );
      await listas.adicionarItem(
        ItemListaCulto(
          id: IdItemListaCulto('item-3'),
          idLista: idLista,
          idMusica: musicaDois.id,
          idVersaoMusica: musicaDois.versaoPrincipal.id,
          posicao: 2,
        ),
      );
      await musicas.arquivar(alternativa.id);
      arquivos.limparContagens();

      final consulta = ConsultaDetalheListaCultoLocal(
        repositorioListas: listas,
        banco: banco,
        armazenamentoArquivos: arquivos,
        parserDocumento: parser,
      );
      final detalhes = await consulta.carregar(idLista);

      expect(detalhes.map((item) => item.titulo), [
        'Caminho',
        'Caminho',
        'Esperança',
      ]);
      expect(detalhes[0].versao?.id, alternativa.id);
      expect(detalhes[0].versao?.arquivada, isTrue);
      expect(detalhes[1].versao?.id, alternativa.id);
      expect(detalhes[2].versao?.id, musicaDois.versaoPrincipal.id);
      expect(arquivos.leituras[alternativa.id], 1);
      expect(arquivos.leituras[musicaDois.versaoPrincipal.id], 1);
      expect(arquivos.leituras[musicaUm.versaoPrincipal.id], isNull);
      expect(arquivos.leituras[musicaForaDaLista.versaoPrincipal.id], isNull);
    },
  );
}

class _ArmazenamentoContado extends ArmazenamentoArquivosChordPro {
  _ArmazenamentoContado(super.diretorio);

  final Map<IdVersaoMusica, int> leituras = {};

  void limparContagens() => leituras.clear();

  @override
  Future<String> obter(IdVersaoMusica id) {
    leituras.update(id, (quantidade) => quantidade + 1, ifAbsent: () => 1);
    return super.obter(id);
  }
}
