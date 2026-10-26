import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:appcifras/aplicacao/biblioteca_oficial/atualizar_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/biblioteca_oficial/falha_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/biblioteca_oficial/preparar_atualizacao_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/portas/fonte_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/publicacao/manifesto_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/sincronizacao/aplicar_grupo_sincronizacao.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_sincronizacao_local.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory diretorio;
  late BancoBiblioteca banco;
  late _ArmazenamentoContado armazenamento;
  late RepositorioMusicasLocal musicas;
  late RepositorioSincronizacaoLocal sincronizacao;
  late _FonteFake fonte;
  late AtualizarBibliotecaOficial casoDeUso;

  setUp(() async {
    diretorio = await Directory.systemTemp.createTemp('appcifras_m4_');
    banco = BancoBiblioteca(NativeDatabase.memory());
    armazenamento = _ArmazenamentoContado(diretorio);
    musicas = RepositorioMusicasLocal(
      banco: banco,
      armazenamentoArquivos: armazenamento,
    );
    sincronizacao = RepositorioSincronizacaoLocal(banco);
    fonte = _FonteFake();
    casoDeUso = _criarCasoDeUso(
      fonte: fonte,
      musicas: musicas,
      sincronizacao: sincronizacao,
    );
  });

  tearDown(() async {
    await banco.close();
    await diretorio.delete(recursive: true);
  });

  test(
    'primeira aplicação cria múltiplas músicas e versões com principal correta',
    () async {
      fonte.publicar([
        _remoto('m1', 'v1', principal: true),
        _remoto('m1', 'v2', nome: 'Acústica'),
        _remoto('m2', 'v3', principal: true),
      ]);

      final resultado = await casoDeUso.executar();

      expect(resultado.adicionadas, 3);
      expect(resultado.erros, isEmpty);
      expect(resultado.geracaoRegistrada, isTrue);
      expect(await musicas.listarPorMusica(IdMusica('m1')), hasLength(2));
      expect(
        (await musicas.obterPrincipalPorMusica(IdMusica('m1')))!.id,
        IdVersaoMusica('v1'),
      );
      final estado = await sincronizacao.obterEstadoBibliotecaOficial();
      expect(estado?.ultimaGeracao, 'geracao-1');
    },
  );

  test(
    'segunda execução não duplica nem regrava e migra origem SAF para HTTPS',
    () async {
      final remoto = _remoto('m1', 'v1', principal: true);
      fonte.publicar([remoto]);
      await casoDeUso.executar();
      await _adicionarItemLista(banco, 'm1', 'v1');
      await banco.salvarTomExecucao(
        idVersaoMusica: 'v1',
        nomeNota: 'g',
        alteracao: 'natural',
        modo: 'maior',
      );
      await sincronizacao.marcarPresente(
        IdVersaoMusica('v1'),
        localizadorExterno: 'content://saf/antigo.cho',
        hashSha256: remoto.sha,
      );
      armazenamento.zerar();
      fonte.downloads = 0;

      final resultado = await casoDeUso.executar();

      expect(resultado.inalteradas, 1);
      expect(fonte.downloads, 0);
      expect(armazenamento.gravacoes, 0);
      expect(await musicas.listarPorMusica(IdMusica('m1')), hasLength(1));
      expect(
        (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))!
            .localizadorExterno,
        remoto.caminho,
      );
      expect(await banco.obterTomExecucaoPorVersao('v1'), isNotNull);
      expect(
        (await banco.listarItensListaCulto('lista')).single.idVersaoMusica,
        'v1',
      );
    },
  );

  test('migração SAF com SHA diferente atualiza sem duplicar', () async {
    final inicial = _remoto('m1', 'v1', principal: true, letra: '[C]Antiga');
    fonte.publicar([inicial]);
    await casoDeUso.executar();
    await sincronizacao.marcarPresente(
      IdVersaoMusica('v1'),
      localizadorExterno: 'content://saf/antigo.cho',
      hashSha256: inicial.sha,
    );
    final nova = _remoto('m1', 'v1', principal: true, letra: '[D]Nova');
    fonte.publicar([nova], geracao: 'geracao-2');

    final resultado = await casoDeUso.executar();

    expect(resultado.atualizadas, 1);
    expect(await musicas.listarPorMusica(IdMusica('m1')), hasLength(1));
    expect(
      (await musicas.obterVersaoPorId(IdVersaoMusica('v1')))!
          .documento
          .conteudoOriginal,
      contains('[D]Nova'),
    );
    expect(
      (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))!
          .localizadorExterno,
      nova.caminho,
    );
  });

  test(
    'ausência e reaparecimento preservam arquivo, Lista e último tom',
    () async {
      final remoto = _remoto('m1', 'v1', principal: true);
      fonte.publicar([remoto]);
      await casoDeUso.executar();
      await _adicionarItemLista(banco, 'm1', 'v1');
      await banco.salvarTomExecucao(
        idVersaoMusica: 'v1',
        nomeNota: 'f',
        alteracao: 'sustenido',
        modo: 'maior',
      );
      final arquivoAntes = await armazenamento.obter(IdVersaoMusica('v1'));
      fonte.publicar(const [], geracao: 'geracao-2');

      final ausente = await casoDeUso.executar();
      expect(ausente.origensAusentes, 1);
      expect(
        (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))!.presente,
        isFalse,
      );
      expect(await armazenamento.obter(IdVersaoMusica('v1')), arquivoAntes);
      expect(await banco.obterTomExecucaoPorVersao('v1'), isNotNull);
      expect(await banco.listarItensListaCulto('lista'), hasLength(1));

      fonte.publicar([remoto], geracao: 'geracao-3');
      final reapareceu = await casoDeUso.executar();
      expect(reapareceu.inalteradas, 1);
      expect(
        (await sincronizacao.obterPorVersao(IdVersaoMusica('v1')))!.presente,
        isTrue,
      );
    },
  );

  test(
    'falha de alternativa usada não derruba outro grupo nem fecha geração',
    () async {
      fonte.publicar([
        _remoto('m1', 'v1', principal: true),
        _remoto('m1', 'v2', nome: 'Alt'),
      ]);
      await casoDeUso.executar();
      await _adicionarItemLista(banco, 'm1', 'v2');
      final altAntes = (await musicas.obterVersaoPorId(IdVersaoMusica('v2')))!
          .documento
          .conteudoOriginal;
      fonte.publicar([
        _remoto('m1', 'v1', principal: true),
        _remoto('m1', 'v2', nome: 'Alt', letra: '[D]Bloqueada'),
        _remoto('m2', 'v3', principal: true),
      ], geracao: 'geracao-2');

      final resultado = await casoDeUso.executar();

      expect(resultado.geracaoRegistrada, isFalse);
      expect(
        resultado.erros.map((erro) => erro.etapa),
        contains(EtapaErroAtualizacaoBibliotecaOficial.aplicacao),
      );
      expect(await musicas.obterPorId(IdMusica('m2')), isNotNull);
      expect(
        (await musicas.obterVersaoPorId(IdVersaoMusica('v2')))!
            .documento
            .conteudoOriginal,
        altAntes,
      );
      expect(
        (await sincronizacao.obterEstadoBibliotecaOficial())!.ultimaGeracao,
        'geracao-1',
      );

      fonte.publicar([
        _remoto('m1', 'v1', principal: true),
        _remoto('m1', 'v2', nome: 'Alt'),
        _remoto('m1', 'v4', nome: 'Alt nova', letra: '[D]Permitida'),
        _remoto('m2', 'v3', principal: true),
      ], geracao: 'geracao-2');
      final retry = await casoDeUso.executar();
      expect(retry.erros, isEmpty);
      expect(retry.geracaoRegistrada, isTrue);
      expect(await musicas.listarPorMusica(IdMusica('m1')), hasLength(3));
    },
  );

  test(
    'erro de download não cria grupo parcial e preserva grupo independente',
    () async {
      fonte.publicar([
        _remoto('m1', 'v1', principal: true),
        _remoto('m1', 'v2', nome: 'Alt'),
        _remoto('m2', 'v3', principal: true),
      ]);
      fonte.falhas.add('musicas/v2.cho');

      final resultado = await casoDeUso.executar();

      expect(resultado.geracaoRegistrada, isFalse);
      expect(
        resultado.erros.map((erro) => erro.etapa),
        contains(EtapaErroAtualizacaoBibliotecaOficial.download),
      );
      expect(await musicas.obterPorId(IdMusica('m1')), isNull);
      expect(await musicas.obterPorId(IdMusica('m2')), isNotNull);
    },
  );

  test(
    'rejeita identidade ChordPro divergente da entrada do manifesto',
    () async {
      final conteudoDeOutraMusica = _remoto('m2', 'v2', principal: true);
      fonte.publicar([
        _Remoto(
          idMusica: 'm1',
          idVersao: 'v1',
          caminho: 'musicas/v1.cho',
          conteudo: conteudoDeOutraMusica.conteudo,
          sha: conteudoDeOutraMusica.sha,
        ),
      ]);

      final resultado = await casoDeUso.executar();

      expect(resultado.geracaoRegistrada, isFalse);
      expect(
        resultado.erros.map((erro) => erro.etapa),
        contains(EtapaErroAtualizacaoBibliotecaOficial.validacaoArquivo),
      );
      expect(await musicas.obterPorId(IdMusica('m1')), isNull);
      expect(await musicas.obterPorId(IdMusica('m2')), isNull);
    },
  );

  test(
    'título e artista atualizam sem alterar Energia, Tags ou principal',
    () async {
      fonte.publicar([
        _remoto('m1', 'v1', principal: true),
        _remoto('m1', 'v2', nome: 'Alt'),
      ]);
      await casoDeUso.executar();
      await musicas.definirComoPrincipal(IdVersaoMusica('v2'));
      await banco.definirEnergiaMusica('m1', 'animada');
      await banco.substituirTagsMusica('m1', const [
        (chave: 'culto', valor: 'Culto'),
      ]);
      fonte.publicar([
        _remoto(
          'm1',
          'v1',
          principal: true,
          titulo: 'Título novo',
          artista: 'Artista novo',
        ),
        _remoto(
          'm1',
          'v2',
          nome: 'Alt',
          titulo: 'Título novo',
          artista: 'Artista novo',
        ),
      ], geracao: 'geracao-2');

      final resultado = await casoDeUso.executar();

      expect(resultado.erros, isEmpty);
      final musica = await musicas.obterPorId(IdMusica('m1'));
      expect(
        (musica?.titulo, musica?.artista),
        ('Título novo', 'Artista novo'),
      );
      expect(
        (await musicas.obterPrincipalPorMusica(IdMusica('m1')))!.id,
        IdVersaoMusica('v2'),
      );
      expect((await banco.obterEnergiaMusica('m1'))?.energia, 'animada');
      expect((await banco.listarTagsMusica('m1')).single.valor, 'Culto');
    },
  );
}

AtualizarBibliotecaOficial _criarCasoDeUso({
  required _FonteFake fonte,
  required RepositorioMusicasLocal musicas,
  required RepositorioSincronizacaoLocal sincronizacao,
}) => AtualizarBibliotecaOficial(
  preparar: PrepararAtualizacaoBibliotecaOficial(fonte, sincronizacao),
  aplicarGrupo: AplicarGrupoSincronizacao(
    repositorioOrigens: sincronizacao,
    repositorioMusicas: musicas,
    repositorioVersoes: musicas,
    aplicador: musicas,
  ),
  repositorioOrigens: sincronizacao,
  repositorioEstado: sincronizacao,
  agora: () => DateTime.utc(2026, 10, 25, 15),
);

class _Remoto {
  const _Remoto({
    required this.idMusica,
    required this.idVersao,
    required this.caminho,
    required this.conteudo,
    required this.sha,
  });

  final String idMusica;
  final String idVersao;
  final String caminho;
  final String conteudo;
  final String sha;
}

_Remoto _remoto(
  String idMusica,
  String idVersao, {
  String nome = 'Principal',
  bool principal = false,
  String titulo = 'Título',
  String artista = 'Artista',
  String letra = '[C]Letra',
}) {
  final conteudo =
      '{appcifras_schema:2}\n'
      '{appcifras_id:$idMusica}\n'
      '{appcifras_version_id:$idVersao}\n'
      '{appcifras_version_name:$nome}\n'
      '${principal ? '{appcifras_primary:true}\n' : ''}'
      '{title:$titulo}\n'
      '{artist:$artista}\n'
      '{key:C}\n'
      '$letra\n';
  final bytes = utf8.encode(conteudo);
  return _Remoto(
    idMusica: idMusica,
    idVersao: idVersao,
    caminho: 'musicas/$idVersao.cho',
    conteudo: conteudo,
    sha: sha256.convert(bytes).toString(),
  );
}

class _FonteFake implements FonteBibliotecaOficial {
  late ManifestoBibliotecaOficial _manifesto;
  final Map<String, Uint8List> _arquivos = {};
  int downloads = 0;
  final Set<String> falhas = {};

  void publicar(List<_Remoto> arquivos, {String geracao = 'geracao-1'}) {
    _arquivos
      ..clear()
      ..addEntries(
        arquivos.map(
          (arquivo) => MapEntry(
            arquivo.caminho,
            Uint8List.fromList(utf8.encode(arquivo.conteudo)),
          ),
        ),
      );
    _manifesto = ManifestoBibliotecaOficial(
      schema: 1,
      geracao: geracao,
      publicadoEm: DateTime.utc(2026, 10, 25),
      arquivos: arquivos.map((arquivo) {
        final bytes = _arquivos[arquivo.caminho]!;
        return EntradaManifestoBibliotecaOficial(
          idMusica: IdMusica(arquivo.idMusica),
          idVersaoMusica: IdVersaoMusica(arquivo.idVersao),
          sha256: arquivo.sha,
          tamanhoBytes: bytes.length,
          caminho: arquivo.caminho,
        );
      }),
    );
  }

  @override
  Future<ManifestoBibliotecaOficial> obterManifesto() async => _manifesto;

  @override
  Future<Uint8List> baixarArquivo(
    String caminhoRelativo, {
    int? tamanhoEsperado,
  }) async {
    downloads++;
    if (falhas.contains(caminhoRelativo)) {
      throw const FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.semConexao,
        'falha de download injetada',
      );
    }
    return _arquivos[caminhoRelativo]!;
  }

  @override
  void fechar() {}
}

class _ArmazenamentoContado extends ArmazenamentoArquivosChordPro {
  _ArmazenamentoContado(super.diretorio);

  int gravacoes = 0;
  void zerar() => gravacoes = 0;

  @override
  Future<void> salvar(IdVersaoMusica id, String conteudo) async {
    gravacoes++;
    await super.salvar(id, conteudo);
  }

  @override
  Future<void> substituir(IdVersaoMusica id, String conteudo) async {
    gravacoes++;
    await super.substituir(id, conteudo);
  }
}

Future<void> _adicionarItemLista(
  BancoBiblioteca banco,
  String idMusica,
  String idVersao,
) async {
  await banco.inserirListaCulto(id: 'lista', nome: 'Culto');
  await banco.inserirItemListaCulto(
    id: 'item',
    idLista: 'lista',
    idMusica: idMusica,
    idVersaoMusica: idVersao,
    posicao: 0,
  );
}
