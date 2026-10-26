import 'dart:io';
import 'dart:typed_data';

import 'package:appcifras/aplicacao/biblioteca_oficial/atualizar_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/biblioteca_oficial/preparar_atualizacao_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/portas/fonte_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/publicacao/manifesto_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/sincronizacao/aplicar_grupo_sincronizacao.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/http/fonte_biblioteca_oficial_http.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_sincronizacao_local.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseUrl = Platform.environment['APPCIFRAS_LIBRARY_BASE_URL'];

  test(
    'R2 aplica geração real em banco temporário e segunda execução é incremental',
    () async {
      final diretorio = await Directory.systemTemp.createTemp(
        'appcifras_m4_real_',
      );
      final fonteHttp = FonteBibliotecaOficialHttp(baseUrl: baseUrl!);
      final fonte = _FonteContada(fonteHttp);
      final banco = BancoBiblioteca(
        NativeDatabase(
          File('${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite'),
        ),
      );
      try {
        final musicas = RepositorioMusicasLocal(
          banco: banco,
          armazenamentoArquivos: ArmazenamentoArquivosChordPro(
            Directory('${diretorio.path}${Platform.pathSeparator}musicas'),
          ),
        );
        final sincronizacao = RepositorioSincronizacaoLocal(banco);
        final casoDeUso = AtualizarBibliotecaOficial(
          preparar: PrepararAtualizacaoBibliotecaOficial(fonte, sincronizacao),
          aplicarGrupo: AplicarGrupoSincronizacao(
            repositorioOrigens: sincronizacao,
            repositorioMusicas: musicas,
            repositorioVersoes: musicas,
            aplicador: musicas,
          ),
          repositorioOrigens: sincronizacao,
          repositorioEstado: sincronizacao,
        );

        final primeira = await casoDeUso.executar();
        expect(primeira.erros, isEmpty);
        expect(primeira.geracao, '20261025T142427167404Z');
        expect(primeira.adicionadas, 7);
        expect(await sincronizacao.listar(), hasLength(7));

        fonte.downloads = 0;
        final segunda = await casoDeUso.executar();
        expect(segunda.erros, isEmpty);
        expect(segunda.inalteradas, 7);
        expect(fonte.downloads, 0);
        expect(await sincronizacao.listar(), hasLength(7));
      } finally {
        fonte.fechar();
        await banco.close();
        await diretorio.delete(recursive: true);
      }
    },
    skip: baseUrl == null || baseUrl.isEmpty
        ? 'Defina APPCIFRAS_LIBRARY_BASE_URL para o teste real opcional.'
        : false,
  );
}

class _FonteContada implements FonteBibliotecaOficial {
  _FonteContada(this._origem);

  final FonteBibliotecaOficial _origem;
  int downloads = 0;

  @override
  Future<ManifestoBibliotecaOficial> obterManifesto() =>
      _origem.obterManifesto();

  @override
  Future<Uint8List> baixarArquivo(
    String caminhoRelativo, {
    required int tamanhoEsperado,
  }) {
    downloads++;
    return _origem.baixarArquivo(
      caminhoRelativo,
      tamanhoEsperado: tamanhoEsperado,
    );
  }

  @override
  void fechar() => _origem.fechar();
}
