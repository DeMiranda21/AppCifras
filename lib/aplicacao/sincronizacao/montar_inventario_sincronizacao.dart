import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import 'modelos_sincronizacao.dart';
import 'validar_arquivo_sincronizacao.dart';

class MontarInventarioSincronizacao {
  MontarInventarioSincronizacao({ValidarArquivoSincronizacao? validador})
    : _validador = validador ?? ValidarArquivoSincronizacao();

  final ValidarArquivoSincronizacao _validador;

  InventarioSincronizacao executar(
    Iterable<ArquivoSincronizacaoCandidato> candidatos,
  ) {
    final ordenados = candidatos.toList()
      ..sort((a, b) => a.localizador.compareTo(b.localizador));
    final resultados = ordenados.map(_validador.executar).toList();
    final validos = resultados
        .whereType<ArquivoSincronizacaoValidado>()
        .toList();
    final invalidos = resultados
        .whereType<ArquivoSincronizacaoInvalido>()
        .toList();

    final porMusica = <IdMusica, List<ArquivoSincronizacaoValidado>>{};
    final porVersao = <IdVersaoMusica, List<ArquivoSincronizacaoValidado>>{};
    for (final arquivo in validos) {
      porMusica.putIfAbsent(arquivo.idMusica, () => []).add(arquivo);
      porVersao.putIfAbsent(arquivo.idVersaoMusica, () => []).add(arquivo);
    }

    final errosPorMusica = <IdMusica, List<ErroGrupoSincronizacao>>{};
    void registrarErro(
      IdMusica idMusica,
      CodigoErroGrupoSincronizacao codigo,
      Iterable<ArquivoSincronizacaoValidado> arquivos,
    ) {
      final localizadores =
          arquivos.map((a) => a.candidato.localizador).toList()..sort();
      errosPorMusica
          .putIfAbsent(idMusica, () => [])
          .add(
            ErroGrupoSincronizacao(
              codigo: codigo,
              localizadores: localizadores,
            ),
          );
    }

    for (final arquivos in porVersao.values.where(
      (itens) => itens.length > 1,
    )) {
      final idsMusica = arquivos.map((a) => a.idMusica).toSet();
      final codigo = idsMusica.length == 1
          ? CodigoErroGrupoSincronizacao.idVersaoDuplicado
          : CodigoErroGrupoSincronizacao.idVersaoAssociadoAMusicasDiferentes;
      for (final idMusica in idsMusica) {
        registrarErro(idMusica, codigo, arquivos);
      }
    }

    for (final entrada in porMusica.entries) {
      final arquivos = entrada.value;
      if (arquivos.map((a) => a.titulo).toSet().length > 1) {
        registrarErro(
          entrada.key,
          CodigoErroGrupoSincronizacao.tituloMusicaDivergente,
          arquivos,
        );
      }
      if (arquivos.map((a) => a.artista).toSet().length > 1) {
        registrarErro(
          entrada.key,
          CodigoErroGrupoSincronizacao.artistaMusicaDivergente,
          arquivos,
        );
      }
    }

    final gruposValidos = <GrupoMusicaSincronizacaoValido>[];
    final gruposRejeitados = <GrupoMusicaSincronizacaoRejeitado>[];
    final idsMusicaOrdenados = porMusica.keys.toList()
      ..sort((a, b) => a.valor.compareTo(b.valor));
    for (final idMusica in idsMusicaOrdenados) {
      final arquivos = porMusica[idMusica]!
        ..sort((a, b) {
          final porId = a.idVersaoMusica.valor.compareTo(
            b.idVersaoMusica.valor,
          );
          return porId != 0
              ? porId
              : a.candidato.localizador.compareTo(b.candidato.localizador);
        });
      final erros = errosPorMusica[idMusica] ?? const [];
      if (erros.isNotEmpty) {
        gruposRejeitados.add(
          GrupoMusicaSincronizacaoRejeitado(
            idMusica: idMusica,
            arquivos: arquivos,
            erros: erros,
          ),
        );
        continue;
      }

      final principais = arquivos
          .where((arquivo) => arquivo.principalDeclarada)
          .toList();
      final avaliacaoCriacao = principais.length == 1
          ? AvaliacaoCriacaoMusicaNova.apta(principais.single.idVersaoMusica)
          : AvaliacaoCriacaoMusicaNova.inapta(principais.length);
      gruposValidos.add(
        GrupoMusicaSincronizacaoValido(
          idMusica: idMusica,
          titulo: arquivos.first.titulo,
          artista: arquivos.first.artista,
          arquivos: arquivos,
          avaliacaoCriacao: avaliacaoCriacao,
        ),
      );
    }

    return InventarioSincronizacao(
      arquivosValidos: validos,
      arquivosInvalidos: invalidos,
      gruposValidos: gruposValidos,
      gruposRejeitados: gruposRejeitados,
    );
  }
}
