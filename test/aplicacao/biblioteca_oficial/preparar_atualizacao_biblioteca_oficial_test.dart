import 'dart:convert';
import 'dart:typed_data';

import 'package:appcifras/aplicacao/biblioteca_oficial/falha_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/biblioteca_oficial/preparar_atualizacao_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/portas/fonte_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/portas/repositorio_sincronizacao.dart';
import 'package:appcifras/aplicacao/publicacao/manifesto_biblioteca_oficial.dart';
import 'package:appcifras/dominio/entidades/origem_sincronizada_versao.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uint8List bytes(String texto) => Uint8List.fromList(utf8.encode(texto));

  EntradaManifestoBibliotecaOficial entrada(String id, Uint8List conteudo) =>
      EntradaManifestoBibliotecaOficial(
        idMusica: IdMusica('musica-$id'),
        idVersaoMusica: IdVersaoMusica(id),
        sha256: sha256.convert(conteudo).toString(),
        tamanhoBytes: conteudo.length,
        caminho: 'musicas/$id.cho',
      );

  ManifestoBibliotecaOficial manifesto(
    Iterable<EntradaManifestoBibliotecaOficial> entradas,
  ) => ManifestoBibliotecaOficial(
    schema: 1,
    geracao: 'geracao-m3',
    publicadoEm: DateTime.utc(2026, 10, 25),
    arquivos: entradas,
  );

  OrigemSincronizadaVersao origem(
    String id,
    String hash, {
    EstadoOrigemSincronizada estado = EstadoOrigemSincronizada.presente,
  }) => OrigemSincronizadaVersao(
    idVersaoMusica: IdVersaoMusica(id),
    localizadorExterno: 'content://legado/$id',
    hashSha256: hash,
    estado: estado,
  );

  test(
    'classifica nova, atualizada, inalterada e ausente e baixa só necessárias',
    () async {
      final novo = bytes('novo');
      final alterado = bytes('alterado');
      final igual = bytes('igual');
      final remoto = manifesto([
        entrada('nova', novo),
        entrada('alterada', alterado),
        entrada('igual', igual),
      ]);
      final fonte = _FonteFake(remoto, {
        'musicas/nova.cho': novo,
        'musicas/alterada.cho': alterado,
      });
      final repositorio = _RepositorioFake([
        origem('alterada', '0' * 64),
        origem('igual', sha256.convert(igual).toString()),
        origem('ausente', 'f' * 64),
      ]);

      final resultado = await PrepararAtualizacaoBibliotecaOficial(
        fonte,
        repositorio,
      ).executar();

      expect(resultado.geracao, 'geracao-m3');
      expect(resultado.novas.single.remoto.idVersaoMusica.valor, 'nova');
      expect(
        resultado.atualizadas.single.remoto.idVersaoMusica.valor,
        'alterada',
      );
      expect(resultado.inalteradas.single.remoto.idVersaoMusica.valor, 'igual');
      expect(resultado.ausentes.single.idVersaoMusica.valor, 'ausente');
      expect(fonte.downloads, ['musicas/nova.cho', 'musicas/alterada.cho']);
      expect(resultado.arquivosBaixados, hasLength(2));
      expect(resultado.erros, isEmpty);
      expect(repositorio.listagens, 1);
    },
  );

  test(
    'origem ausente com mesmo hash também não exige novo download',
    () async {
      final conteudo = bytes('preservado-localmente');
      final remoto = manifesto([entrada('versao', conteudo)]);
      final fonte = _FonteFake(remoto, const {});
      final repositorio = _RepositorioFake([
        origem(
          'versao',
          sha256.convert(conteudo).toString(),
          estado: EstadoOrigemSincronizada.ausente,
        ),
      ]);

      final resultado = await PrepararAtualizacaoBibliotecaOficial(
        fonte,
        repositorio,
      ).executar();

      expect(resultado.inalteradas, hasLength(1));
      expect(fonte.downloads, isEmpty);
    },
  );

  test('SHA-256 divergente rejeita bytes sem entregá-los', () async {
    final esperado = bytes('esperado');
    final recebido = bytes('recebido');
    expect(recebido.length, esperado.length);
    final remoto = manifesto([entrada('versao', esperado)]);
    final fonte = _FonteFake(remoto, {'musicas/versao.cho': recebido});

    final resultado = await PrepararAtualizacaoBibliotecaOficial(
      fonte,
      _RepositorioFake(const []),
    ).executar();

    expect(resultado.arquivosBaixados, isEmpty);
    expect(
      resultado.erros.single.falha.tipo,
      TipoFalhaBibliotecaOficial.sha256Divergente,
    );
  });

  test('tamanho divergente rejeita bytes sem entregá-los', () async {
    final esperado = bytes('esperado');
    final remoto = manifesto([entrada('versao', esperado)]);
    final fonte = _FonteFake(remoto, {'musicas/versao.cho': bytes('curto')});

    final resultado = await PrepararAtualizacaoBibliotecaOficial(
      fonte,
      _RepositorioFake(const []),
    ).executar();

    expect(resultado.arquivosBaixados, isEmpty);
    expect(
      resultado.erros.single.falha.tipo,
      TipoFalhaBibliotecaOficial.tamanhoDivergente,
    );
  });

  test('segunda preparação equivalente baixa zero arquivos', () async {
    final conteudo = bytes('conteudo');
    final item = entrada('versao', conteudo);
    final remoto = manifesto([item]);
    final primeiraFonte = _FonteFake(remoto, {item.caminho: conteudo});
    final primeira = await PrepararAtualizacaoBibliotecaOficial(
      primeiraFonte,
      _RepositorioFake(const []),
    ).executar();
    expect(primeira.arquivosBaixados, hasLength(1));

    final segundaFonte = _FonteFake(remoto, const {});
    final segunda = await PrepararAtualizacaoBibliotecaOficial(
      segundaFonte,
      _RepositorioFake([origem('versao', item.sha256)]),
    ).executar();

    expect(segunda.inalteradas, hasLength(1));
    expect(segunda.arquivosBaixados, isEmpty);
    expect(segundaFonte.downloads, isEmpty);
  });

  test('milhares de entradas são comparadas sem truncamento ou N+1', () async {
    final entradas = <EntradaManifestoBibliotecaOficial>[];
    final origens = <OrigemSincronizadaVersao>[];
    for (var i = 0; i < 4000; i++) {
      final conteudo = bytes('conteudo-$i');
      final item = entrada('versao-$i', conteudo);
      entradas.add(item);
      origens.add(origem('versao-$i', item.sha256));
    }
    final fonte = _FonteFake(manifesto(entradas), const {});
    final repositorio = _RepositorioFake(origens);

    final resultado = await PrepararAtualizacaoBibliotecaOficial(
      fonte,
      repositorio,
    ).executar();

    expect(resultado.inalteradas, hasLength(4000));
    expect(resultado.arquivosBaixados, isEmpty);
    expect(fonte.downloads, isEmpty);
    expect(repositorio.listagens, 1);
  });

  test('falha ao obter manifesto não permite inferir ausências', () async {
    final fonte = _FonteFake(
      manifesto(const []),
      const {},
      falhaManifesto: const FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.manifestoNaoEncontrado,
        'não encontrado',
      ),
    );
    final repositorio = _RepositorioFake([origem('existente', 'a' * 64)]);

    await expectLater(
      PrepararAtualizacaoBibliotecaOficial(fonte, repositorio).executar(),
      throwsA(
        isA<FalhaBibliotecaOficial>().having(
          (erro) => erro.tipo,
          'tipo',
          TipoFalhaBibliotecaOficial.manifestoNaoEncontrado,
        ),
      ),
    );
    expect(repositorio.listagens, 0);
  });
}

class _FonteFake implements FonteBibliotecaOficial {
  _FonteFake(this.manifesto, this.arquivos, {this.falhaManifesto});

  final ManifestoBibliotecaOficial manifesto;
  final Map<String, Uint8List> arquivos;
  final FalhaBibliotecaOficial? falhaManifesto;
  final List<String> downloads = [];

  @override
  Future<ManifestoBibliotecaOficial> obterManifesto() async {
    if (falhaManifesto case final falha?) throw falha;
    return manifesto;
  }

  @override
  Future<Uint8List> baixarArquivo(
    String caminho, {
    required int tamanhoEsperado,
  }) async {
    downloads.add(caminho);
    final resultado = arquivos[caminho];
    if (resultado == null) {
      throw const FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.arquivoNaoEncontrado,
        'não encontrado',
      );
    }
    return resultado;
  }

  @override
  void fechar() {}
}

class _RepositorioFake implements RepositorioOrigensSincronizadas {
  _RepositorioFake(this.origens);

  final List<OrigemSincronizadaVersao> origens;
  var listagens = 0;

  @override
  Future<List<OrigemSincronizadaVersao>> listar() async {
    listagens++;
    return List.of(origens);
  }

  @override
  Future<OrigemSincronizadaVersao?> obterPorVersao(IdVersaoMusica id) async =>
      null;

  @override
  Future<void> salvarOrigem(OrigemSincronizadaVersao origem) async {}

  @override
  Future<void> marcarAusente(IdVersaoMusica id) async {}

  @override
  Future<void> marcarPresente(
    IdVersaoMusica id, {
    required String localizadorExterno,
    required String hashSha256,
  }) async {}

  @override
  Future<void> remover(IdVersaoMusica id) async {}
}
