import 'package:appcifras/aplicacao/casos_de_uso/ciclo_vida_versoes_musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/editar_versao_musica.dart';
import 'package:appcifras/aplicacao/casos_de_uso/listas_culto.dart';
import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/versoes_musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/tom_execucao.dart';
import 'package:appcifras/aplicacao/portas/consulta_detalhe_lista_culto.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_item_lista_culto.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_lista_culto.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_versao_musica.dart';
import 'package:appcifras/aplicacao/portas/repositorio_tom_execucao.dart';
import 'package:appcifras/apresentacao/listas_culto/tela_listas_culto.dart';
import 'package:appcifras/dominio/entidades/item_lista_culto.dart';
import 'package:appcifras/dominio/entidades/lista_culto.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_item_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/repositorios/repositorio_listas_culto.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/repositorios/repositorio_versoes_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

RenderPointerListener _listenerDaCifra(WidgetTester tester) {
  final areaDaCifra = find.byKey(const ValueKey('conteudo-cifra'));
  expect(areaDaCifra, findsOneWidget);
  final listener = tester.renderObject<RenderPointerListener>(areaDaCifra);
  expect(listener.hasSize, isTrue);
  expect(listener.size.isEmpty, isFalse);
  return listener;
}

Rect _retanguloInterativoDaCifra(WidgetTester tester) {
  final listener = _listenerDaCifra(tester);
  final retangulo = listener.localToGlobal(Offset.zero) & listener.size;
  expect(retangulo.width, greaterThan(0));
  expect(retangulo.height, greaterThan(0));
  return retangulo;
}

void _confirmarPontoInterativoDaCifra(WidgetTester tester, Offset ponto) {
  final listener = _listenerDaCifra(tester);
  final cadeia = tester.hitTestOnBinding(ponto).path;
  final cadeiaFormatada = cadeia
      .map((entrada) => entrada.target.runtimeType)
      .join(' -> ');
  expect(
    cadeia.any((entrada) => identical(entrada.target, listener)),
    isTrue,
    reason:
        'O ponto $ponto não atingiu o Listener da cifra. '
        'Retângulo: ${_retanguloInterativoDaCifra(tester)}. '
        'Cadeia: $cadeiaFormatada',
  );
}

void main() {
  Future<void> tocarFabEstendidoInterativo(
    WidgetTester tester,
    String texto,
  ) async {
    await tester.pump();
    final fab = find.widgetWithText(FloatingActionButton, texto);
    expect(fab, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.ensureVisible(fab);
    expect(fab.hitTestable(), findsOneWidget);
    await tester.tap(fab);
  }

  Future<void> arrastarCifra(WidgetTester tester, Offset deslocamento) async {
    final pontoInicial = _retanguloInterativoDaCifra(tester).center;
    _confirmarPontoInterativoDaCifra(tester, pontoInicial);
    final gesto = await tester.startGesture(pontoInicial);
    await tester.pump();
    await gesto.moveBy(deslocamento);
    await gesto.up();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('cria, renomeia e exclui uma lista pela interface', (
    tester,
  ) async {
    final cenario = _Cenario();
    await cenario.montar(tester);

    expect(find.text('Nenhuma lista de culto criada'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Criar lista'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Culto de domingo');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Culto de domingo'), findsOneWidget);
    await tester.tap(find.byTooltip('Ações da lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Culto da noite');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Culto da noite'), findsOneWidget);

    await tester.tap(find.byTooltip('Ações da lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir "Culto da noite"?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma lista de culto criada'), findsOneWidget);
  });

  testWidgets('cancelar exclusão mantém a lista intacta', (tester) async {
    final cenario = _Cenario()..criarLista('Culto');
    await cenario.montar(tester);

    await tester.tap(find.byTooltip('Ações da lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Culto'), findsOneWidget);
    expect(cenario.listas.listas, hasLength(1));
  });

  testWidgets('monta detalhe sem listar a Biblioteca inteira', (tester) async {
    final cenario = _Cenario()..criarLista('Culto');
    cenario
      ..adicionarItem('item-1', 'musica-1', 0)
      ..adicionarItem('item-2', 'musica-2', 1);
    await cenario.montar(tester);

    await tester.tap(find.byKey(const ValueKey('lista-lista-1')));
    await tester.pumpAndSettle();

    expect(find.text('Caminho'), findsOneWidget);
    expect(find.text('Esperança'), findsOneWidget);
    expect(cenario.musicas.listagensCompletas, 0);
  });

  testWidgets('adiciona várias músicas, remove uma e preserva as demais', (
    tester,
  ) async {
    final cenario = _Cenario()..criarLista('Culto');
    final observador = _ObservadorNavegacao();
    await cenario.montar(tester, observador: observador);
    await tester.tap(find.byKey(const ValueKey('lista-lista-1')));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma música nesta lista'), findsOneWidget);

    await tester.tap(find.byTooltip('Adicionar músicas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('selecionar-musica-1')));
    await tester.tap(find.byKey(const ValueKey('selecionar-musica-2')));
    await tocarFabEstendidoInterativo(tester, 'Adicionar (2)');
    await tester.pump();
    expect(observador.rotasEncerradas, hasLength(1));
    expect(observador.rotasEncerradas.single.isCurrent, isFalse);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(cenario.listas.adicoes.map((item) => item.idMusica.valor), [
      'musica-1',
      'musica-2',
    ]);

    final itemCaminho = find.byKey(const ValueKey('item-lista-item-1'));
    final itemEsperanca = find.byKey(const ValueKey('item-lista-item-2'));
    expect(itemCaminho, findsOneWidget);
    expect(itemEsperanca, findsOneWidget);
    expect(
      find.descendant(of: itemCaminho, matching: find.text('Caminho')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: itemEsperanca, matching: find.text('Esperança')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: itemCaminho,
        matching: find.byTooltip('Remover da lista'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Remover "Caminho"?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    expect(itemCaminho, findsOneWidget);

    await tester.tap(
      find.descendant(
        of: itemCaminho,
        matching: find.byTooltip('Remover da lista'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();
    expect(itemCaminho, findsNothing);
    expect(itemEsperanca, findsOneWidget);
    expect(await cenario.musicas.obterPorId(IdMusica('musica-1')), isNotNull);
  });

  testWidgets('marca músicas já presentes e impede nova seleção no seletor', (
    tester,
  ) async {
    final cenario = _Cenario()
      ..criarLista('Culto')
      ..adicionarItem('item-1', 'musica-1', 0);
    final quantidadeAdicoesAntes = cenario.listas.adicoes.length;
    await cenario.montar(tester);
    await tester.tap(find.byKey(const ValueKey('lista-lista-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar músicas'));
    await tester.pumpAndSettle();

    final caminho = find.byKey(const ValueKey('selecionar-musica-1'));
    final esperanca = find.byKey(const ValueKey('selecionar-musica-2'));
    final seletorCaminho = tester.widget<CheckboxListTile>(caminho);
    expect(seletorCaminho.value, isTrue);
    expect(seletorCaminho.onChanged, isNull);
    expect(
      find.descendant(
        of: caminho,
        matching: find.textContaining('Já adicionada'),
      ),
      findsOneWidget,
    );

    await tester.tap(esperanca);
    await tocarFabEstendidoInterativo(tester, 'Adicionar (1)');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    final adicoesNovas = cenario.listas.adicoes
        .skip(quantidadeAdicoesAntes)
        .toList();
    expect(adicoesNovas, hasLength(1));
    expect(adicoesNovas.single.idMusica, IdMusica('musica-2'));
    expect(
      adicoesNovas.map((item) => item.idMusica),
      isNot(contains(IdMusica('musica-1'))),
    );
    final itensFinais = await cenario.listas.listarItens(
      IdListaCulto('lista-1'),
    );
    expect(itensFinais.map((item) => item.id.valor), ['item-1', 'item-2']);
    expect(itensFinais.map((item) => item.idMusica.valor), [
      'musica-1',
      'musica-2',
    ]);
  });

  testWidgets('navega entre itens da lista sem sair da visualização', (
    tester,
  ) async {
    final cenario = _Cenario()
      ..criarLista('Culto')
      ..adicionarItem('item-1', 'musica-1', 0)
      ..adicionarItem('item-2', 'musica-2', 1)
      ..adicionarItem('item-3', 'musica-3', 2);
    await cenario.toms.salvarUltimoTom(
      IdVersaoMusica('musica-2'),
      const Tom(
        notaFundamental: Nota(
          nome: NomeNota.f,
          alteracao: AlteracaoNota.sustenido,
        ),
        modo: ModoTom.maior,
      ),
    );
    await cenario.montar(tester);
    await tester.tap(find.byKey(const ValueKey('lista-lista-1')));
    await tester.pumpAndSettle();
    final primeiroItem = find.byKey(const ValueKey('item-lista-item-1'));
    await tester.ensureVisible(primeiroItem);
    expect(primeiroItem.hitTestable(), findsOneWidget);
    await tester.tap(primeiroItem);
    await tester.pumpAndSettle();

    expect(find.text('Caminho'), findsOneWidget);
    expect(find.text('Tom: C'), findsOneWidget);
    expect(find.text('1 de 3'), findsOneWidget);

    await arrastarCifra(tester, const Offset(-160, 0));
    expect(find.text('Esperança'), findsOneWidget);
    expect(find.text('Tom: F#'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);

    await arrastarCifra(tester, const Offset(-160, 0));
    expect(find.text('Coração'), findsOneWidget);
    expect(find.text('Tom: C'), findsOneWidget);
    expect(find.text('3 de 3'), findsOneWidget);

    await arrastarCifra(tester, const Offset(-160, 0));
    expect(find.text('Coração'), findsOneWidget);
    expect(find.text('3 de 3'), findsOneWidget);

    await arrastarCifra(tester, const Offset(160, 0));
    expect(find.text('Esperança'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);
  });

  testWidgets('seletor pesquisa por título e artista sem diferenciar acentos', (
    tester,
  ) async {
    final cenario = _Cenario()..criarLista('Culto');
    await cenario.montar(tester);
    await tester.tap(find.byKey(const ValueKey('lista-lista-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar músicas'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'coracao');
    await tester.pump();
    expect(find.text('Coração'), findsOneWidget);
    expect(find.text('Caminho'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ministerio luz');
    await tester.pump();
    expect(find.text('Esperança'), findsOneWidget);
  });

  testWidgets(
    'troca versão do item, omite arquivadas e abre a referência concreta',
    (tester) async {
      final cenario = _Cenario()..criarLista('Culto');
      final musica = (await cenario.musicas.obterPorId(IdMusica('musica-1')))!;
      final arquivada = VersaoMusica(
        id: IdVersaoMusica('arquivada'),
        idMusica: musica.id,
        nome: 'Arquivada',
        documento: ParserDocumentoChordPro().interpretar(
          '{title: Caminho}\n{artist: Banda}\n{key: C}\n[C]Arranjo arquivado',
        ),
        principal: false,
        arquivada: true,
      );
      final alternativa = VersaoMusica(
        id: IdVersaoMusica('alternativa'),
        idMusica: musica.id,
        nome: 'Acústica',
        documento: ParserDocumentoChordPro().interpretar(
          '{title: Caminho}\n{artist: Banda}\n{key: D}\n[D]Arranjo acústico',
        ),
        principal: false,
        arquivada: false,
      );
      cenario.versoes
        ..adicionar(arquivada)
        ..adicionar(alternativa);
      cenario.adicionarItem('item-1', 'musica-1', 0, idVersao: 'arquivada');
      await cenario.montar(tester);
      await tester.tap(find.byKey(const ValueKey('lista-lista-1')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Arquivada'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('item-lista-item-1')));
      await tester.pumpAndSettle();
      expect(find.text('Arranjo arquivado'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Trocar versão'));
      await tester.pumpAndSettle();
      expect(find.text('Arquivada'), findsNothing);
      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('Acústica'), findsOneWidget);
      await tester.tap(find.text('Acústica'));
      await tester.pumpAndSettle();

      final item = (await cenario.listas.listarItens(IdListaCulto('lista-1')))
          .single;
      expect(item.id, IdItemListaCulto('item-1'));
      expect(item.idVersaoMusica, alternativa.id);
      expect(item.posicao, 0);
      await tester.tap(find.byKey(const ValueKey('item-lista-item-1')));
      await tester.pumpAndSettle();
      expect(find.text('Arranjo acústico'), findsOneWidget);
    },
  );

  testWidgets('reordena itens usando seus IDs próprios', (tester) async {
    final cenario = _Cenario()
      ..criarLista('Culto')
      ..adicionarItem('item-1', 'musica-1', 0)
      ..adicionarItem('item-2', 'musica-2', 1);
    await cenario.montar(tester);
    await tester.tap(find.byKey(const ValueKey('lista-lista-1')));
    await tester.pumpAndSettle();

    final handles = find.byType(ReorderableDragStartListener);
    expect(handles, findsNWidgets(2));
    expect(tester.widget<ReorderableDragStartListener>(handles.first).index, 0);
    expect(tester.widget<ReorderableDragStartListener>(handles.at(1)).index, 1);
    final listaReordenavel = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    listaReordenavel.onReorderItem!(0, 1);
    await tester.pump();

    final itens = await cenario.listas.listarItens(IdListaCulto('lista-1'));
    expect(cenario.listas.ordensReordenadas, hasLength(1));
    expect(cenario.listas.ordensReordenadas.single.map((id) => id.valor), [
      'item-2',
      'item-1',
    ]);
    expect(itens.map((item) => item.idMusica.valor), ['musica-2', 'musica-1']);
  });
}

class _Cenario {
  _Cenario()
    : musicas = _RepositorioMusicasFake([
        _musica('musica-1', 'Caminho', 'Banda'),
        _musica('musica-2', 'Esperança', 'Ministério Luz'),
        _musica('musica-3', 'Coração', 'Outra Banda'),
      ]) {
    versoes = _RepositorioVersoesVazio(musicas.musicas);
  }

  final _RepositorioListasFake listas = _RepositorioListasFake();
  final _RepositorioMusicasFake musicas;
  late final _RepositorioVersoesVazio versoes;
  final _RepositorioTomExecucaoFake toms = _RepositorioTomExecucaoFake();
  var _proximoIdItem = 1;

  void criarLista(String nome) {
    listas.salvar(ListaCulto(id: IdListaCulto('lista-1'), nome: nome));
  }

  void adicionarItem(
    String idItem,
    String idMusica,
    int posicao, {
    String? idVersao,
  }) {
    listas.adicionarItem(
      ItemListaCulto(
        id: IdItemListaCulto(idItem),
        idLista: IdListaCulto('lista-1'),
        idMusica: IdMusica(idMusica),
        idVersaoMusica: IdVersaoMusica(idVersao ?? idMusica),
        posicao: posicao,
      ),
    );
  }

  IdItemListaCulto _gerarIdItem() {
    late IdItemListaCulto id;
    do {
      id = IdItemListaCulto('item-${_proximoIdItem++}');
    } while (listas.contemIdItem(id));
    return id;
  }

  Future<void> montar(
    WidgetTester tester, {
    NavigatorObserver? observador,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [?observador],
        home: TelaListasCulto(
          listarListasCulto: ListarListasCulto(listas),
          criarListaCulto: CriarListaCulto(
            listas,
            _GeradorListaFake(IdListaCulto('lista-1')),
          ),
          renomearListaCulto: RenomearListaCulto(listas),
          excluirListaCulto: ExcluirListaCulto(listas),
          carregarDetalheListaCulto: CarregarDetalheListaCulto(
            _ConsultaDetalheListaCultoFake(listas, musicas, versoes),
          ),
          adicionarMusicaAListaCulto: AdicionarMusicaAListaCulto(
            listas,
            _GeradorItemFake(_gerarIdItem),
          ),
          removerItemListaCulto: RemoverItemListaCulto(listas),
          trocarVersaoItemListaCulto: TrocarVersaoItemListaCulto(
            listas,
            versoes,
          ),
          listarVersoesMusica: ListarVersoesMusica(versoes),
          reordenarItensListaCulto: ReordenarItensListaCulto(listas),
          listarMusicas: ListarMusicas(musicas),
          obterMusicaPorId: ObterMusicaPorId(musicas),
          atualizarMusica: AtualizarMusica(
            repositorio: musicas,
            parserDocumento: ParserDocumentoChordPro(),
          ),
          editarVersaoMusica: EditarVersaoMusica(
            repositorio: versoes,
            repositorioMusicas: musicas,
            criarVersao: CriarVersaoMusica(
              repositorio: versoes,
              geradorId: _GeradorVersaoVazio(),
            ),
            avaliarPolitica: AvaliarPoliticaEdicaoVersao(versoes),
          ),
          excluirMusica: ExcluirMusica(musicas),
          obterUltimoTomExecucao: ObterUltimoTomExecucao(toms),
          salvarUltimoTomExecucao: SalvarUltimoTomExecucao(toms),
          removerUltimoTomExecucao: RemoverUltimoTomExecucao(toms),
          obterVersaoMusicaPorId: ObterVersaoMusicaPorId(versoes),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Musica _musica(String id, String titulo, String artista) => Musica(
  id: IdMusica(id),
  documento: ParserDocumentoChordPro().interpretar(
    '{title: $titulo}\n{artist: $artista}\n{key: C}\n[C]Letra',
  ),
);

class _GeradorListaFake implements GeradorIdListaCulto {
  const _GeradorListaFake(this._id);

  final IdListaCulto _id;

  @override
  IdListaCulto gerar() => _id;
}

class _GeradorItemFake implements GeradorIdItemListaCulto {
  const _GeradorItemFake(this._gerar);

  final IdItemListaCulto Function() _gerar;

  @override
  IdItemListaCulto gerar() => _gerar();
}

class _RepositorioListasFake implements RepositorioListasCulto {
  final Map<IdListaCulto, ListaCulto> _porId = {};
  final Map<IdListaCulto, List<ItemListaCulto>> _itens = {};
  final List<ItemListaCulto> adicoes = [];
  final List<List<IdItemListaCulto>> ordensReordenadas = [];

  List<ListaCulto> get listas => _porId.values.toList();

  bool contemIdItem(IdItemListaCulto idItem) =>
      _itens.values.any((itens) => itens.any((item) => item.id == idItem));

  @override
  Future<void> adicionarItem(ItemListaCulto item) async {
    adicoes.add(item);
    _itens.putIfAbsent(item.idLista, () => []).add(item);
  }

  @override
  Future<void> excluir(IdListaCulto id) async {
    _porId.remove(id);
    _itens.remove(id);
  }

  @override
  Future<List<ListaCulto>> listar() async => _porId.values.toList();

  @override
  Future<List<ItemListaCulto>> listarItens(IdListaCulto idLista) async {
    final itens = List<ItemListaCulto>.from(_itens[idLista] ?? [])
      ..sort((a, b) => a.posicao.compareTo(b.posicao));
    return itens;
  }

  @override
  Future<ListaCulto?> obterPorId(IdListaCulto id) async => _porId[id];

  @override
  Future<void> removerItem(
    IdListaCulto idLista,
    IdItemListaCulto idItem,
  ) async {
    final restantes = (_itens[idLista] ?? [])
        .where((item) => item.id != idItem)
        .toList();
    _itens[idLista] = _reposicionar(idLista, restantes);
  }

  @override
  Future<void> renomear(IdListaCulto id, String nome) async {
    _porId[id] = ListaCulto(id: id, nome: nome);
  }

  @override
  Future<void> atualizarVersaoItem(
    IdListaCulto idLista,
    IdItemListaCulto idItem,
    IdVersaoMusica idVersaoMusica,
  ) async {
    final itens = _itens[idLista]!;
    final indice = itens.indexWhere((item) => item.id == idItem);
    final item = itens[indice];
    itens[indice] = ItemListaCulto(
      id: item.id,
      idLista: item.idLista,
      idMusica: item.idMusica,
      idVersaoMusica: idVersaoMusica,
      posicao: item.posicao,
    );
  }

  @override
  Future<void> reordenarItens(
    IdListaCulto idLista,
    List<IdItemListaCulto> ordem,
  ) async {
    ordensReordenadas.add(List<IdItemListaCulto>.from(ordem));
    final porId = {for (final item in _itens[idLista] ?? []) item.id: item};
    _itens[idLista] = _reposicionar(idLista, [
      for (final id in ordem) porId[id]!,
    ]);
  }

  @override
  Future<void> salvar(ListaCulto lista) async {
    _porId[lista.id] = lista;
  }

  List<ItemListaCulto> _reposicionar(
    IdListaCulto idLista,
    List<ItemListaCulto> itens,
  ) => [
    for (var indice = 0; indice < itens.length; indice++)
      ItemListaCulto(
        id: itens[indice].id,
        idLista: idLista,
        idMusica: itens[indice].idMusica,
        idVersaoMusica: itens[indice].idVersaoMusica,
        posicao: indice,
      ),
  ];
}

class _ObservadorNavegacao extends NavigatorObserver {
  final List<Route<dynamic>> rotasEncerradas = [];

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    rotasEncerradas.add(route);
    super.didPop(route, previousRoute);
  }
}

class _ConsultaDetalheListaCultoFake implements ConsultaDetalheListaCulto {
  const _ConsultaDetalheListaCultoFake(
    this._listas,
    this._musicas,
    this._versoes,
  );

  final _RepositorioListasFake _listas;
  final _RepositorioMusicasFake _musicas;
  final _RepositorioVersoesVazio _versoes;

  @override
  Future<List<ItemDetalheListaCulto>> carregar(IdListaCulto idLista) async {
    final itens = await _listas.listarItens(idLista);
    return Future.wait([for (final item in itens) _carregarItem(item)]);
  }

  Future<ItemDetalheListaCulto> _carregarItem(ItemListaCulto item) async {
    final musica = await _musicas.obterPorId(item.idMusica);
    if (musica == null) throw StateError('Música ausente no cenário.');
    return ItemDetalheListaCulto(
      item: item,
      titulo: musica.titulo,
      artista: musica.artista,
      versao: await _versoes.obterVersaoPorId(item.idVersaoMusica),
    );
  }
}

class _RepositorioMusicasFake implements RepositorioMusicas {
  _RepositorioMusicasFake(List<Musica> musicas)
    : _porId = {for (final musica in musicas) musica.id: musica};

  final Map<IdMusica, Musica> _porId;

  Iterable<Musica> get musicas => _porId.values;

  @override
  Future<void> atualizar(Musica musica) async {
    _porId[musica.id] = musica;
  }

  @override
  Future<void> excluir(IdMusica id) async {
    _porId.remove(id);
  }

  var listagensCompletas = 0;

  @override
  Future<List<Musica>> listar() async {
    listagensCompletas++;
    return _porId.values.toList();
  }

  @override
  Future<Musica?> obterPorId(IdMusica id) async => _porId[id];

  @override
  Future<void> salvar(Musica musica) async {
    _porId[musica.id] = musica;
  }
}

class _RepositorioVersoesVazio implements RepositorioVersoesMusicas {
  _RepositorioVersoesVazio(Iterable<Musica> musicas)
    : _versoes = {
        for (final musica in musicas)
          musica.versaoPrincipal.id: musica.versaoPrincipal,
      };

  final Map<IdVersaoMusica, VersaoMusica> _versoes;

  void adicionar(VersaoMusica versao) => _versoes[versao.id] = versao;

  @override
  Future<List<VersaoMusica>> listarPorMusica(IdMusica idMusica) async =>
      _versoes.values.where((versao) => versao.idMusica == idMusica).toList();

  @override
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica idMusica) async {
    for (final versao in _versoes.values) {
      if (versao.idMusica == idMusica && versao.principal) return versao;
    }
    return null;
  }

  @override
  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id) async =>
      _versoes[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GeradorVersaoVazio implements GeradorIdVersaoMusica {
  @override
  IdVersaoMusica gerar() => IdVersaoMusica('versao-vazia');
}

class _RepositorioTomExecucaoFake implements RepositorioTomExecucao {
  final Map<IdVersaoMusica, Tom> _tons = {};

  @override
  Future<Tom?> obterUltimoTom(IdVersaoMusica idVersaoMusica) async =>
      _tons[idVersaoMusica];

  @override
  Future<void> removerUltimoTom(IdVersaoMusica idVersaoMusica) async {
    _tons.remove(idVersaoMusica);
  }

  @override
  Future<void> salvarUltimoTom(IdVersaoMusica idVersaoMusica, Tom tom) async {
    _tons[idVersaoMusica] = tom;
  }
}
