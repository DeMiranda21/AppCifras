import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:appcifras/aplicacao/portas/aplicador_sincronizacao_pasta_curada.dart';
import 'package:appcifras/aplicacao/portas/pasta_curada_externa.dart';
import 'package:appcifras/aplicacao/sincronizacao/configuracao_pasta_sincronizada.dart';
import 'package:appcifras/aplicacao/sincronizacao/sincronizar_pasta_curada.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_sincronizacao_local.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory diretorio;
  late BancoBiblioteca banco;
  late _ArmazenamentoContado armazenamento;
  late RepositorioMusicasLocal musicas;
  late RepositorioSincronizacaoLocal sincronizacao;
  late _PastaFake pasta;
  late SincronizarPastaCurada casoDeUso;

  setUp(() async {
    diretorio = await Directory.systemTemp.createTemp('appcifras_s4_');
    banco = BancoBiblioteca(NativeDatabase.memory());
    armazenamento = _ArmazenamentoContado(diretorio);
    musicas = RepositorioMusicasLocal(
      banco: banco,
      armazenamentoArquivos: armazenamento,
    );
    sincronizacao = RepositorioSincronizacaoLocal(banco);
    pasta = _PastaFake();
    await sincronizacao.salvarConfiguracao(
      ConfiguracaoPastaSincronizada(
        uriArvore: 'content://pasta-curada',
        autorizacaoPersistente: true,
      ),
    );
    casoDeUso = _criarCasoDeUso(
      pasta: pasta,
      sincronizacao: sincronizacao,
      musicas: musicas,
      aplicador: musicas,
    );
  });

  tearDown(() async {
    await banco.close();
    await diretorio.delete(recursive: true);
  });

  test('cria música nova com uma versão, IDs externos e principal', () async {
    final conteudo = _cho('m1', 'v1', principal: true);
    pasta.adicionar('principal.cho', conteudo);

    final resultado = await casoDeUso.executar();

    expect(resultado.adicionadas, 1);
    final musica = await musicas.obterPorId(IdMusica('m1'));
    expect(musica?.versaoPrincipal.id, IdVersaoMusica('v1'));
    expect(
      (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))?.presente,
      isTrue,
    );
    expect(await armazenamento.obter(IdVersaoMusica('v1')), conteudo);
  });

  test('cria todas as versões e respeita a principal declarada', () async {
    pasta
      ..adicionar('acustica.cho', _cho('m1', 'v2', nome: 'Acústica'))
      ..adicionar('banda.cho', _cho('m1', 'v1', principal: true));

    final resultado = await casoDeUso.executar();

    expect(resultado.adicionadas, 2);
    expect(await musicas.listarPorMusica(IdMusica('m1')), hasLength(2));
    expect(
      (await musicas.obterPrincipalPorMusica(IdMusica('m1')))?.id,
      IdVersaoMusica('v1'),
    );
  });

  test('grupo novo sem principal não cria parcialmente', () async {
    pasta
      ..adicionar('a.cho', _cho('m1', 'v1'))
      ..adicionar('b.cho', _cho('m1', 'v2'));

    final resultado = await casoDeUso.executar();

    expect(await musicas.obterPorId(IdMusica('m1')), isNull);
    expect(
      resultado.erros.single.codigo,
      CodigoErroSincronizacao.grupoNovoSemPrincipal,
    );
  });

  test(
    'segunda execução é idempotente e renomeação só muda localizador',
    () async {
      pasta.adicionar('antigo.cho', _cho('m1', 'v1', principal: true));
      await casoDeUso.executar();
      armazenamento.zerarContadores();
      pasta.renomear('antigo.cho', 'novo.cho');

      final resultado = await casoDeUso.executar();

      expect(resultado.inalteradas, 1);
      expect(resultado.adicionadas, 0);
      expect(armazenamento.salvamentos, 0);
      expect(armazenamento.substituicoes, 0);
      expect(await musicas.listarPorMusica(IdMusica('m1')), hasLength(1));
      expect(
        (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))
            ?.localizadorExterno,
        'doc:novo.cho',
      );
    },
  );

  test('adiciona versão a música existente sem trocar a principal', () async {
    pasta.adicionar('principal.cho', _cho('m1', 'v1', principal: true));
    await casoDeUso.executar();
    pasta.adicionar(
      'nova.cho',
      _cho('m1', 'v2', nome: 'Nova', principal: true),
    );

    final resultado = await casoDeUso.executar();

    expect(resultado.adicionadas, 1);
    expect(
      (await musicas.obterPrincipalPorMusica(IdMusica('m1')))?.id,
      IdVersaoMusica('v1'),
    );
    expect(
      resultado.avisos.map((a) => a.codigo),
      contains(CodigoAvisoSincronizacao.principalExternaDivergente),
    );
  });

  test('atualiza principal sincronizada mesmo quando usada em Lista', () async {
    pasta.adicionar('principal.cho', _cho('m1', 'v1', principal: true));
    await casoDeUso.executar();
    await _adicionarItemLista(banco, idMusica: 'm1', idVersao: 'v1');
    pasta.adicionar(
      'principal.cho',
      _cho('m1', 'v1', principal: true, letra: '[D]Nova'),
    );

    final resultado = await casoDeUso.executar();

    expect(resultado.atualizadas, 1);
    expect(
      (await musicas.obterVersaoPorId(IdVersaoMusica('v1')))
          ?.documento
          .conteudoOriginal,
      contains('[D]Nova'),
    );
    expect(
      (await banco.listarItensListaCulto('lista')).single.idVersaoMusica,
      'v1',
    );
  });

  test(
    'atualiza alternativa livre e rejeita alternativa usada em Lista',
    () async {
      pasta
        ..adicionar('principal.cho', _cho('m1', 'v1', principal: true))
        ..adicionar('alternativa.cho', _cho('m1', 'v2', nome: 'Alt'));
      await casoDeUso.executar();
      pasta.adicionar(
        'alternativa.cho',
        _cho('m1', 'v2', nome: 'Alt', letra: '[D]Livre'),
      );
      expect((await casoDeUso.executar()).atualizadas, 1);
      await _adicionarItemLista(banco, idMusica: 'm1', idVersao: 'v2');
      final antes = (await musicas.obterVersaoPorId(IdVersaoMusica('v2')))!
          .documento
          .conteudoOriginal;
      pasta.adicionar(
        'alternativa.cho',
        _cho('m1', 'v2', nome: 'Alt', letra: '[E]Bloqueada'),
      );

      final resultado = await casoDeUso.executar();

      expect(
        resultado.erros.map((e) => e.codigo),
        contains(CodigoErroSincronizacao.alternativaUsadaEmLista),
      );
      expect(
        (await musicas.obterVersaoPorId(IdVersaoMusica('v2')))!
            .documento
            .conteudoOriginal,
        antes,
      );
      expect(
        (await banco.listarItensListaCulto('lista')).single.idVersaoMusica,
        'v2',
      );
    },
  );

  test(
    'colisão local rejeita grupo e não bloqueia música independente',
    () async {
      await musicas.salvar(_musicaLocal('local', 'v-colisao'));
      pasta
        ..adicionar(
          'colisao.cho',
          _cho('externa', 'v-colisao', principal: true),
        )
        ..adicionar('valida.cho', _cho('m2', 'v2', principal: true));

      final resultado = await casoDeUso.executar();

      expect(
        resultado.erros.map((e) => e.codigo),
        contains(CodigoErroSincronizacao.colisaoVersaoLocal),
      );
      expect(await musicas.obterPorId(IdMusica('externa')), isNull);
      expect(await musicas.obterPorId(IdMusica('m2')), isNotNull);
    },
  );

  test(
    'título e artista atualizam catálogo sem alterar Energia ou Tags',
    () async {
      pasta.adicionar('principal.cho', _cho('m1', 'v1', principal: true));
      await casoDeUso.executar();
      await banco.definirEnergiaMusica('m1', 'animada');
      await banco.substituirTagsMusica('m1', const [
        (chave: 'ceia', valor: 'Ceia'),
      ]);
      pasta.adicionar(
        'principal.cho',
        _cho('m1', 'v1', principal: true, titulo: 'Novo', artista: 'Outra'),
      );

      await casoDeUso.executar();

      final musica = await musicas.obterPorId(IdMusica('m1'));
      expect((musica?.titulo, musica?.artista), ('Novo', 'Outra'));
      expect((await banco.obterEnergiaMusica('m1'))?.energia, 'animada');
      expect((await banco.listarTagsMusica('m1')).single.valor, 'Ceia');
    },
  );

  test(
    'desaparecimento e reaparecimento preservam versão, Lista e último tom',
    () async {
      pasta.adicionar('principal.cho', _cho('m1', 'v1', principal: true));
      await casoDeUso.executar();
      await _adicionarItemLista(banco, idMusica: 'm1', idVersao: 'v1');
      await banco.salvarTomExecucao(
        idVersaoMusica: 'v1',
        nomeNota: 'g',
        alteracao: 'natural',
        modo: 'maior',
      );
      pasta.remover('principal.cho');

      final ausente = await casoDeUso.executar();
      expect(ausente.origensAusentes, 1);
      expect(
        (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))?.presente,
        isFalse,
      );
      pasta.adicionar('reapareceu.cho', _cho('m1', 'v1', principal: true));
      await casoDeUso.executar();

      expect(
        (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))?.presente,
        isTrue,
      );
      expect(await musicas.listarPorMusica(IdMusica('m1')), hasLength(1));
      expect(await banco.obterTomExecucaoPorVersao('v1'), isNotNull);
      expect(
        (await banco.listarItensListaCulto('lista')).single.idVersaoMusica,
        'v1',
      );
    },
  );

  test('falha global de enumeração não marca origem ausente', () async {
    pasta.adicionar('principal.cho', _cho('m1', 'v1', principal: true));
    await casoDeUso.executar();
    pasta
      ..remover('principal.cho')
      ..falharEnumeracao = true;

    final resultado = await casoDeUso.executar();

    expect(resultado.enumeracaoCompleta, isFalse);
    expect(resultado.origensAusentes, 0);
    expect(
      (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))?.presente,
      isTrue,
    );
  });

  test(
    'enumeração parcial não autoriza ausência e a completa inclui arquivo novo',
    () async {
      pasta
        ..adicionar('primeira.cho', _cho('m1', 'v1', principal: true))
        ..adicionar('segunda.cho', _cho('m2', 'v2', principal: true));
      await casoDeUso.executar();
      pasta
        ..remover('segunda.cho')
        ..enumeracaoCompleta = false;

      final parcial = await casoDeUso.executar();

      expect(parcial.enumeracaoCompleta, isFalse);
      expect(parcial.origensAusentes, 0);
      expect(
        parcial.erros.map((erro) => erro.codigo),
        contains(CodigoErroSincronizacao.enumeracaoPasta),
      );
      expect(
        (await sincronizacao.obterPorVersao(IdVersaoMusica('v2')))?.presente,
        isTrue,
      );

      pasta
        ..adicionar('segunda.cho', _cho('m2', 'v2', principal: true))
        ..adicionar('nova.cho', _cho('m3', 'v3', principal: true))
        ..enumeracaoCompleta = true;
      final completa = await casoDeUso.executar();

      expect(completa.enumeracaoCompleta, isTrue);
      expect(completa.adicionadas, 1);
      expect(await musicas.obterPorId(IdMusica('m3')), isNotNull);
    },
  );

  test('arquivo inválido reconhecível não vira ausência e não bloqueia outro grupo', () async {
    pasta.adicionar('principal.cho', _cho('m1', 'v1', principal: true));
    await casoDeUso.executar();
    pasta
      ..adicionar(
        'principal.cho',
        _cho('m1', 'v1', principal: true).replaceFirst('{key:C}', '{key:???}'),
      )
      ..adicionar('outra.cho', _cho('m2', 'v2', principal: true));

    final resultado = await casoDeUso.executar();

    expect(
      resultado.erros.map((e) => e.codigo),
      contains(CodigoErroSincronizacao.arquivoInvalido),
    );
    expect(
      (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))?.presente,
      isTrue,
    );
    expect(await musicas.obterPorId(IdMusica('m2')), isNotNull);
  });

  test(
    'arquivo inválido sem identidade preserva origens por segurança',
    () async {
      pasta.adicionar('principal.cho', _cho('m1', 'v1', principal: true));
      await casoDeUso.executar();
      pasta.adicionar('principal.cho', '{title: sem identidade}\n{key: ???}');

      final resultado = await casoDeUso.executar();

      expect(resultado.enumeracaoCompleta, isTrue);
      expect(resultado.origensAusentes, 0);
      expect(
        (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))?.presente,
        isTrue,
      );
    },
  );

  test('leitura incompleta não marca nenhuma origem como ausente', () async {
    pasta.adicionar('principal.cho', _cho('m1', 'v1', principal: true));
    await casoDeUso.executar();
    pasta.falharLeitura.add('principal.cho');

    final resultado = await casoDeUso.executar();

    expect(resultado.enumeracaoCompleta, isFalse);
    expect(resultado.origensAusentes, 0);
    expect(
      (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))?.presente,
      isTrue,
    );
  });

  test(
    'falha no grupo restaura arquivos e retry não duplica versões',
    () async {
      pasta
        ..adicionar('principal.cho', _cho('m1', 'v1', principal: true))
        ..adicionar('alternativa.cho', _cho('m1', 'v2'));
      armazenamento.falharNoProximoSegundoSalvamento = true;

      final falha = await casoDeUso.executar();
      expect(
        falha.erros.map((e) => e.codigo),
        contains(CodigoErroSincronizacao.falhaAplicacao),
      );
      expect(await musicas.obterPorId(IdMusica('m1')), isNull);

      final retry = await casoDeUso.executar();
      expect(retry.adicionadas, 2);
      expect(await musicas.listarPorMusica(IdMusica('m1')), hasLength(2));
    },
  );
}

SincronizarPastaCurada _criarCasoDeUso({
  required _PastaFake pasta,
  required RepositorioSincronizacaoLocal sincronizacao,
  required RepositorioMusicasLocal musicas,
  required AplicadorSincronizacaoPastaCurada aplicador,
}) => SincronizarPastaCurada(
  pastaExterna: pasta,
  repositorioConfiguracao: sincronizacao,
  repositorioOrigens: sincronizacao,
  repositorioMusicas: musicas,
  repositorioVersoes: musicas,
  aplicador: aplicador,
  agora: () => DateTime.utc(2026, 10, 16, 12),
);

String _cho(
  String idMusica,
  String idVersao, {
  String nome = 'Principal',
  bool principal = false,
  String titulo = 'Título',
  String artista = 'Artista',
  String letra = '[C]Letra',
}) =>
    '{appcifras_schema:2}\n'
    '{appcifras_id:$idMusica}\n'
    '{appcifras_version_id:$idVersao}\n'
    '{appcifras_version_name:$nome}\n'
    '${principal ? '{appcifras_primary:true}\n' : ''}'
    '{title:$titulo}\n'
    '{artist:$artista}\n'
    '{key:C}\n'
    '$letra\n';

Musica _musicaLocal(String idMusica, String idVersao) {
  final documento = ParserDocumentoChordPro().interpretar(
    '{title: Local}\n{artist: Pessoa}\n{key: C}\n[C]Letra',
  );
  return Musica(
    id: IdMusica(idMusica),
    titulo: 'Local',
    artista: 'Pessoa',
    versaoPrincipal: VersaoMusica(
      id: IdVersaoMusica(idVersao),
      idMusica: IdMusica(idMusica),
      nome: 'Principal',
      documento: documento,
      principal: true,
      arquivada: false,
    ),
  );
}

Future<void> _adicionarItemLista(
  BancoBiblioteca banco, {
  required String idMusica,
  required String idVersao,
}) async {
  if ((await banco.listarListasCulto()).isEmpty) {
    await banco.inserirListaCulto(id: 'lista', nome: 'Culto');
  }
  final itens = await banco.listarItensListaCulto('lista');
  await banco.inserirItemListaCulto(
    id: 'item-${itens.length}',
    idLista: 'lista',
    idMusica: idMusica,
    idVersaoMusica: idVersao,
    posicao: itens.length,
  );
}

class _PastaFake implements PastaCuradaExterna {
  final Map<String, Uint8List> _arquivos = {};
  final Set<String> falharLeitura = {};
  bool falharEnumeracao = false;
  bool enumeracaoCompleta = true;

  void adicionar(String nome, String conteudo) {
    _arquivos[nome] = Uint8List.fromList(utf8.encode(conteudo));
  }

  void remover(String nome) => _arquivos.remove(nome);

  void renomear(String anterior, String novo) {
    _arquivos[novo] = _arquivos.remove(anterior)!;
  }

  @override
  Future<void> verificarAcesso(String uriArvore) async {}

  @override
  Future<ResultadoEnumeracaoPastaCurada> listarFilhosDiretos(
    String uriArvore,
  ) async {
    if (falharEnumeracao) {
      throw const FalhaPastaCurada(TipoFalhaPastaCurada.leitura, 'falha');
    }
    return ResultadoEnumeracaoPastaCurada(
      completa: enumeracaoCompleta,
      documentos: _arquivos.keys.map(
        (nome) => DocumentoPastaCurada(
          localizador: 'doc:$nome',
          nome: nome,
          ehDiretorio: false,
        ),
      ),
    );
  }

  @override
  Future<Uint8List> lerBytes(DocumentoPastaCurada documento) async {
    if (falharLeitura.contains(documento.nome)) {
      throw const FalhaPastaCurada(TipoFalhaPastaCurada.leitura, 'falha');
    }
    return _arquivos[documento.nome]!;
  }

  @override
  Future<PastaCuradaSelecionada?> selecionarPasta() async => null;
}

class _ArmazenamentoContado extends ArmazenamentoArquivosChordPro {
  _ArmazenamentoContado(super.diretorio);

  int salvamentos = 0;
  int substituicoes = 0;
  bool falharNoProximoSegundoSalvamento = false;
  int _salvamentosDesdeFalhaArmada = 0;

  void zerarContadores() {
    salvamentos = 0;
    substituicoes = 0;
  }

  @override
  Future<void> salvar(IdVersaoMusica id, String conteudo) async {
    salvamentos++;
    if (falharNoProximoSegundoSalvamento) {
      _salvamentosDesdeFalhaArmada++;
      if (_salvamentosDesdeFalhaArmada == 2) {
        falharNoProximoSegundoSalvamento = false;
        throw StateError('falha injetada');
      }
    }
    await super.salvar(id, conteudo);
  }

  @override
  Future<void> substituir(IdVersaoMusica id, String conteudo) async {
    substituicoes++;
    await super.substituir(id, conteudo);
  }
}
