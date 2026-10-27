import 'dart:io';

import 'package:appcifras/aplicacao/casos_de_uso/listas_culto.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_item_lista_culto.dart';
import 'package:appcifras/dominio/entidades/item_lista_culto.dart';
import 'package:appcifras/dominio/entidades/lista_culto.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_item_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:appcifras/aplicacao/portas/aplicador_grupo_sincronizacao.dart';
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
  var bancoFechado = false;

  Musica musica(String id, String titulo) => Musica(
    id: IdMusica(id),
    documento: parser.interpretar(
      '{title: $titulo}\n{artist: Artista $id}\n{key: C}\n[C]Letra',
    ),
  );

  setUp(() async {
    bancoFechado = false;
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
    if (!bancoFechado) await banco.close();
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

  test(
    'carrega lista mista com versão sincronizada schema 2 persistida pela S4',
    () async {
      final local = musica('musica-local', 'Local');
      await musicas.salvar(local);

      final idMusicaSincronizada = IdMusica('musica-sincronizada');
      final idVersaoSincronizada = IdVersaoMusica('versao-sincronizada');
      await musicas.aplicar(
        PlanoAplicacaoGrupoSincronizacao(
          idMusica: idMusicaSincronizada,
          criarMusica: true,
          titulo: 'Sincronizada',
          artista: 'Drive',
          versoesNovas: [
            VersaoNovaSincronizacao(
              id: idVersaoSincronizada,
              nome: 'Principal',
              conteudoChordPro:
                  '{appcifras_schema:2}\n'
                  '{appcifras_id:musica-sincronizada}\n'
                  '{appcifras_version_id:versao-sincronizada}\n'
                  '{appcifras_version_name:Principal}\n'
                  '{appcifras_primary:true}\n'
                  '{title:Sincronizada}\n'
                  '{artist:Drive}\n'
                  '{key:D}\n'
                  '[D]Letra sincronizada\n',
              principal: true,
              localizadorExterno: 'sincronizada.cho',
              hashSha256: 'hash-sincronizada',
            ),
          ],
          versoesExistentes: const [],
        ),
      );

      final idLista = IdListaCulto('lista-mista');
      await listas.salvar(ListaCulto(id: idLista, nome: 'Culto'));
      await listas.adicionarItem(
        ItemListaCulto(
          id: IdItemListaCulto('item-local'),
          idLista: idLista,
          idMusica: local.id,
          idVersaoMusica: local.versaoPrincipal.id,
          posicao: 0,
        ),
      );
      await listas.adicionarItem(
        ItemListaCulto(
          id: IdItemListaCulto('item-sincronizado'),
          idLista: idLista,
          idMusica: idMusicaSincronizada,
          idVersaoMusica: idVersaoSincronizada,
          posicao: 1,
        ),
      );

      final consulta = ConsultaDetalheListaCultoLocal(
        repositorioListas: listas,
        banco: banco,
        armazenamentoArquivos: arquivos,
        parserDocumento: parser,
      );

      final detalhes = await consulta.carregar(idLista);

      expect(detalhes.map((item) => item.titulo), ['Local', 'Sincronizada']);
      expect(detalhes.last.item.idMusica, idMusicaSincronizada);
      expect(detalhes.last.item.idVersaoMusica, idVersaoSincronizada);
      expect(detalhes.last.versao?.id, idVersaoSincronizada);
      expect(
        detalhes.last.versao?.documento.conteudoOriginal,
        contains('[D]Letra sincronizada'),
      );
    },
  );

  test(
    'mantém operações da lista com principal e alternativa sincronizadas',
    () async {
      final local = musica('musica-local-operacoes', 'Local');
      await musicas.salvar(local);
      final idMusica = IdMusica('musica-drive');
      final principal = IdVersaoMusica('drive-principal');
      final alternativa = IdVersaoMusica('drive-alternativa');
      await musicas.aplicar(
        PlanoAplicacaoGrupoSincronizacao(
          idMusica: idMusica,
          criarMusica: true,
          titulo: 'Do Drive',
          artista: 'Equipe',
          versoesNovas: [
            _versaoSincronizada(
              idMusica: idMusica,
              idVersao: principal,
              nome: 'Principal',
              principal: true,
            ),
            _versaoSincronizada(
              idMusica: idMusica,
              idVersao: alternativa,
              nome: 'Acústica',
            ),
          ],
          versoesExistentes: const [],
        ),
      );
      final idLista = IdListaCulto('lista-operacoes');
      await listas.salvar(ListaCulto(id: idLista, nome: 'Culto'));
      final adicionar = AdicionarMusicaAListaCulto(
        listas,
        _GeradorItemSequencial(),
        repositorioVersoes: musicas,
      );
      final itemLocal = await adicionar.executar(idLista, local.id);
      final itemSincronizado = await adicionar.executar(idLista, idMusica);
      expect(itemSincronizado.idVersaoMusica, principal);

      await TrocarVersaoItemListaCulto(
        listas,
        musicas,
      ).executar(idLista, itemSincronizado.id, alternativa);
      await ReordenarItensListaCulto(listas)
          .executar(idLista, [itemSincronizado.id, itemLocal.id]);

      final consulta = _consulta(
        listas: listas,
        banco: banco,
        arquivos: arquivos,
        parser: parser,
      );
      final reordenados = await consulta.carregar(idLista);
      expect(reordenados.map((item) => item.item.id), [
        itemSincronizado.id,
        itemLocal.id,
      ]);
      expect(reordenados.first.versao?.id, alternativa);

      await RemoverItemListaCulto(listas)
          .executar(idLista, itemSincronizado.id);
      final restantes = await consulta.carregar(idLista);
      expect(restantes.single.item.id, itemLocal.id);
    },
  );

  test(
    'nova aplicação sincronizada preserva item e detalhe da Lista existente',
    () async {
      final idMusica = IdMusica('musica-atualizada');
      final idVersao = IdVersaoMusica('versao-atualizada');
      await musicas.aplicar(
        PlanoAplicacaoGrupoSincronizacao(
          idMusica: idMusica,
          criarMusica: true,
          titulo: 'Antes',
          artista: 'Drive',
          versoesNovas: [
            _versaoSincronizada(
              idMusica: idMusica,
              idVersao: idVersao,
              nome: 'Principal',
              principal: true,
              letra: '[C]Antes',
            ),
          ],
          versoesExistentes: const [],
        ),
      );
      final idLista = IdListaCulto('lista-atualizada');
      await listas.salvar(ListaCulto(id: idLista, nome: 'Culto'));
      final item = await AdicionarMusicaAListaCulto(
        listas,
        _GeradorItemSequencial(),
        repositorioVersoes: musicas,
      ).executar(idLista, idMusica);

      await musicas.aplicar(
        PlanoAplicacaoGrupoSincronizacao(
          idMusica: idMusica,
          criarMusica: false,
          titulo: 'Depois',
          artista: 'Drive',
          versoesNovas: const [],
          versoesExistentes: [
            VersaoExistenteSincronizacao(
              id: idVersao,
              nome: 'Principal',
              localizadorExterno: 'versao-atualizada.cho',
              hashSha256: 'hash-novo',
              conteudoChordProAtualizado: _conteudoSincronizado(
                idMusica: idMusica,
                idVersao: idVersao,
                nome: 'Principal',
                principal: true,
                titulo: 'Depois',
                letra: '[D]Depois',
              ),
            ),
          ],
        ),
      );

      final detalhe = (await _consulta(
        listas: listas,
        banco: banco,
        arquivos: arquivos,
        parser: parser,
      ).carregar(idLista)).single;
      expect(detalhe.item.id, item.id);
      expect(detalhe.item.idVersaoMusica, idVersao);
      expect(detalhe.titulo, 'Depois');
      expect(detalhe.versao?.documento.conteudoOriginal, contains('[D]Depois'));
    },
  );

  test(
    'mantém demais itens quando uma versão individual está inconsistente',
    () async {
      final valida = musica('musica-valida', 'Válida');
      final inconsistente = musica('musica-inconsistente', 'Inconsistente');
      await musicas.salvar(valida);
      await musicas.salvar(inconsistente);
      await arquivos.excluir(inconsistente.versaoPrincipal.id);
      final idLista = IdListaCulto('lista-inconsistente');
      await listas.salvar(ListaCulto(id: idLista, nome: 'Culto'));
      await listas.adicionarItem(
        ItemListaCulto(
          id: IdItemListaCulto('item-valido'),
          idLista: idLista,
          idMusica: valida.id,
          idVersaoMusica: valida.versaoPrincipal.id,
          posicao: 0,
        ),
      );
      await listas.adicionarItem(
        ItemListaCulto(
          id: IdItemListaCulto('item-inconsistente'),
          idLista: idLista,
          idMusica: inconsistente.id,
          idVersaoMusica: inconsistente.versaoPrincipal.id,
          posicao: 1,
        ),
      );

      final detalhes = await _consulta(
        listas: listas,
        banco: banco,
        arquivos: arquivos,
        parser: parser,
      ).carregar(idLista);

      expect(detalhes, hasLength(2));
      expect(detalhes.first.versao?.id, valida.versaoPrincipal.id);
      expect(detalhes.last.titulo, 'Inconsistente');
      expect(detalhes.last.versao, isNull);
    },
  );

  test(
    'lista sincronizada reabre offline com origem ausente no mesmo SQLite',
    () async {
      await banco.close();
      bancoFechado = true;
      final raiz = await Directory.systemTemp.createTemp(
        'appcifras_lista_sincronizada_reaberta_',
      );
      final arquivoBanco = File(
        '${raiz.path}${Platform.pathSeparator}biblioteca.sqlite',
      );
      final diretorioMusicas = Directory(
        '${raiz.path}${Platform.pathSeparator}musicas',
      );
      BancoBiblioteca? bancoPersistente;
      addTearDown(() async {
        await bancoPersistente?.close();
        if (await raiz.exists()) await raiz.delete(recursive: true);
      });

      bancoPersistente = BancoBiblioteca(NativeDatabase(arquivoBanco));
      await bancoPersistente.inicializar();
      final armazenamentoPersistente = ArmazenamentoArquivosChordPro(
        diretorioMusicas,
      );
      final musicasPersistentes = RepositorioMusicasLocal(
        banco: bancoPersistente,
        armazenamentoArquivos: armazenamentoPersistente,
        parserDocumento: parser,
      );
      final idMusica = IdMusica('musica-offline');
      final idVersao = IdVersaoMusica('versao-offline');
      await musicasPersistentes.aplicar(
        PlanoAplicacaoGrupoSincronizacao(
          idMusica: idMusica,
          criarMusica: true,
          titulo: 'Offline',
          artista: 'Drive',
          versoesNovas: [
            _versaoSincronizada(
              idMusica: idMusica,
              idVersao: idVersao,
              nome: 'Principal',
              principal: true,
            ),
          ],
          versoesExistentes: const [],
        ),
      );
      final listasPersistentes = RepositorioListasCultoLocal(bancoPersistente);
      final idLista = IdListaCulto('lista-offline');
      await listasPersistentes.salvar(ListaCulto(id: idLista, nome: 'Culto'));
      await listasPersistentes.adicionarItem(
        ItemListaCulto(
          id: IdItemListaCulto('item-offline'),
          idLista: idLista,
          idMusica: idMusica,
          idVersaoMusica: idVersao,
          posicao: 0,
        ),
      );
      await bancoPersistente.marcarOrigemSincronizadaAusente(idVersao.valor);
      await bancoPersistente.close();

      bancoPersistente = BancoBiblioteca(NativeDatabase(arquivoBanco));
      await bancoPersistente.inicializar();
      final detalhe = (await _consulta(
        listas: RepositorioListasCultoLocal(bancoPersistente),
        banco: bancoPersistente,
        arquivos: armazenamentoPersistente,
        parser: parser,
      ).carregar(idLista)).single;

      expect(detalhe.titulo, 'Offline');
      expect(detalhe.item.idVersaoMusica, idVersao);
      expect(detalhe.versao?.id, idVersao);
      expect(await armazenamentoPersistente.existe(idVersao), isTrue);
    },
  );
}

ConsultaDetalheListaCultoLocal _consulta({
  required RepositorioListasCultoLocal listas,
  required BancoBiblioteca banco,
  required ArmazenamentoArquivosChordPro arquivos,
  required ParserDocumentoChordPro parser,
}) => ConsultaDetalheListaCultoLocal(
  repositorioListas: listas,
  banco: banco,
  armazenamentoArquivos: arquivos,
  parserDocumento: parser,
);

VersaoNovaSincronizacao _versaoSincronizada({
  required IdMusica idMusica,
  required IdVersaoMusica idVersao,
  required String nome,
  bool principal = false,
  String letra = '[C]Letra',
}) => VersaoNovaSincronizacao(
  id: idVersao,
  nome: nome,
  conteudoChordPro: _conteudoSincronizado(
    idMusica: idMusica,
    idVersao: idVersao,
    nome: nome,
    principal: principal,
    letra: letra,
  ),
  principal: principal,
  localizadorExterno: '${idVersao.valor}.cho',
  hashSha256: 'hash-${idVersao.valor}',
);

String _conteudoSincronizado({
  required IdMusica idMusica,
  required IdVersaoMusica idVersao,
  required String nome,
  required bool principal,
  String titulo = 'Do Drive',
  String letra = '[C]Letra',
}) =>
    '{appcifras_schema:2}\n'
    '{appcifras_id:${idMusica.valor}}\n'
    '{appcifras_version_id:${idVersao.valor}}\n'
    '{appcifras_version_name:$nome}\n'
    '${principal ? '{appcifras_primary:true}\n' : ''}'
    '{title:$titulo}\n'
    '{artist:Drive}\n'
    '{key:C}\n'
    '$letra\n';

class _GeradorItemSequencial implements GeradorIdItemListaCulto {
  var _proximo = 0;

  @override
  IdItemListaCulto gerar() => IdItemListaCulto('item-${_proximo++}');
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
