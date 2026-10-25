import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../dominio/entidades/origem_sincronizada_versao.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../portas/fonte_biblioteca_oficial.dart';
import '../portas/repositorio_sincronizacao.dart';
import '../publicacao/manifesto_biblioteca_oficial.dart';
import 'falha_biblioteca_oficial.dart';

class ItemPreparacaoBibliotecaOficial {
  const ItemPreparacaoBibliotecaOficial({
    required this.remoto,
    this.origemLocal,
  });

  final EntradaManifestoBibliotecaOficial remoto;
  final OrigemSincronizadaVersao? origemLocal;
}

class ArquivoBibliotecaOficialBaixado {
  const ArquivoBibliotecaOficialBaixado({
    required this.remoto,
    required this.bytes,
  });

  final EntradaManifestoBibliotecaOficial remoto;
  final Uint8List bytes;
}

class ErroArquivoBibliotecaOficial {
  const ErroArquivoBibliotecaOficial({
    required this.remoto,
    required this.falha,
  });

  final EntradaManifestoBibliotecaOficial remoto;
  final FalhaBibliotecaOficial falha;
}

class PreparacaoAtualizacaoBibliotecaOficial {
  PreparacaoAtualizacaoBibliotecaOficial({
    required this.manifesto,
    required Iterable<ItemPreparacaoBibliotecaOficial> novas,
    required Iterable<ItemPreparacaoBibliotecaOficial> atualizadas,
    required Iterable<ItemPreparacaoBibliotecaOficial> inalteradas,
    required Iterable<OrigemSincronizadaVersao> ausentes,
    required Iterable<ArquivoBibliotecaOficialBaixado> arquivosBaixados,
    required Iterable<ErroArquivoBibliotecaOficial> erros,
  }) : novas = List.unmodifiable(novas),
       atualizadas = List.unmodifiable(atualizadas),
       inalteradas = List.unmodifiable(inalteradas),
       ausentes = List.unmodifiable(ausentes),
       arquivosBaixados = List.unmodifiable(arquivosBaixados),
       erros = List.unmodifiable(erros);

  final ManifestoBibliotecaOficial manifesto;
  String get geracao => manifesto.geracao;
  DateTime get publicadoEm => manifesto.publicadoEm;
  final List<ItemPreparacaoBibliotecaOficial> novas;
  final List<ItemPreparacaoBibliotecaOficial> atualizadas;
  final List<ItemPreparacaoBibliotecaOficial> inalteradas;
  final List<OrigemSincronizadaVersao> ausentes;
  final List<ArquivoBibliotecaOficialBaixado> arquivosBaixados;
  final List<ErroArquivoBibliotecaOficial> erros;
}

class PrepararAtualizacaoBibliotecaOficial {
  const PrepararAtualizacaoBibliotecaOficial(
    this._fonte,
    this._repositorioOrigens,
  );

  final FonteBibliotecaOficial _fonte;
  final RepositorioOrigensSincronizadas _repositorioOrigens;

  Future<PreparacaoAtualizacaoBibliotecaOficial> executar() async {
    final manifesto = await _fonte.obterManifesto();
    final origens = await _repositorioOrigens.listar();
    final porId = <IdVersaoMusica, OrigemSincronizadaVersao>{
      for (final origem in origens) origem.idVersaoMusica: origem,
    };
    final idsRemotos = <IdVersaoMusica>{};
    final novas = <ItemPreparacaoBibliotecaOficial>[];
    final atualizadas = <ItemPreparacaoBibliotecaOficial>[];
    final inalteradas = <ItemPreparacaoBibliotecaOficial>[];

    for (final remoto in manifesto.arquivos) {
      idsRemotos.add(remoto.idVersaoMusica);
      final origem = porId[remoto.idVersaoMusica];
      final item = ItemPreparacaoBibliotecaOficial(
        remoto: remoto,
        origemLocal: origem,
      );
      if (origem == null) {
        novas.add(item);
      } else if (origem.hashSha256 != remoto.sha256) {
        atualizadas.add(item);
      } else {
        inalteradas.add(item);
      }
    }

    final ausentes = origens
        .where((origem) => !idsRemotos.contains(origem.idVersaoMusica))
        .toList(growable: false);
    final baixados = <ArquivoBibliotecaOficialBaixado>[];
    final erros = <ErroArquivoBibliotecaOficial>[];

    for (final item in [...novas, ...atualizadas]) {
      try {
        final bytes = await _fonte.baixarArquivo(
          item.remoto.caminho,
          tamanhoEsperado: item.remoto.tamanhoBytes,
        );
        if (bytes.length != item.remoto.tamanhoBytes) {
          throw FalhaBibliotecaOficial(
            TipoFalhaBibliotecaOficial.tamanhoDivergente,
            'Tamanho divergente para ${item.remoto.caminho}: '
            'esperado ${item.remoto.tamanhoBytes}, recebido ${bytes.length}.',
          );
        }
        final hashRecebido = sha256.convert(bytes).toString();
        if (hashRecebido != item.remoto.sha256) {
          throw FalhaBibliotecaOficial(
            TipoFalhaBibliotecaOficial.sha256Divergente,
            'SHA-256 divergente para ${item.remoto.caminho}.',
          );
        }
        baixados.add(
          ArquivoBibliotecaOficialBaixado(remoto: item.remoto, bytes: bytes),
        );
      } on FalhaBibliotecaOficial catch (falha) {
        erros.add(
          ErroArquivoBibliotecaOficial(remoto: item.remoto, falha: falha),
        );
      }
    }

    return PreparacaoAtualizacaoBibliotecaOficial(
      manifesto: manifesto,
      novas: novas,
      atualizadas: atualizadas,
      inalteradas: inalteradas,
      ausentes: ausentes,
      arquivosBaixados: baixados,
      erros: erros,
    );
  }
}
