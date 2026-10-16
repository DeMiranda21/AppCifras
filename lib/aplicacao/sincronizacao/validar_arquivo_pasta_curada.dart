import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/entidades/versao_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import 'modelos_sincronizacao.dart';

class ValidarArquivoPastaCurada {
  ValidarArquivoPastaCurada({ParserDocumentoChordPro? parser})
    : _parser = parser ?? ParserDocumentoChordPro();

  final ParserDocumentoChordPro _parser;

  ResultadoValidacaoArquivoSincronizacao executar(
    ArquivoSincronizacaoCandidato candidato,
  ) {
    final erros = <ErroArquivoSincronizacao>[];
    if (!candidato.nomeLegivel.toLowerCase().endsWith('.cho')) {
      erros.add(
        const ErroArquivoSincronizacao(
          CodigoErroArquivoSincronizacao.extensaoInvalida,
        ),
      );
    }

    late final String conteudo;
    try {
      conteudo = utf8.decode(candidato.bytes, allowMalformed: false);
    } on FormatException {
      erros.add(
        const ErroArquivoSincronizacao(
          CodigoErroArquivoSincronizacao.utf8Invalido,
        ),
      );
      return ArquivoSincronizacaoInvalido(candidato: candidato, erros: erros);
    }

    final documento = _parser.interpretar(conteudo);
    final schemas = documento.elementos
        .whereType<DiretivaSchemaAppCifras>()
        .toList();
    if (schemas.length != 1 || schemas.single.versao != 2) {
      erros.add(
        const ErroArquivoSincronizacao(
          CodigoErroArquivoSincronizacao.schemaAusenteOuInvalido,
        ),
      );
    }

    final idsMusica = documento.elementos
        .whereType<DiretivaIdAppCifras>()
        .toList();
    final idMusicaTexto = idsMusica.length == 1 ? idsMusica.single.id : null;
    if (idMusicaTexto == null) {
      erros.add(
        const ErroArquivoSincronizacao(
          CodigoErroArquivoSincronizacao.idMusicaAusenteOuInvalido,
        ),
      );
    }

    final idsVersao = documento.elementos
        .whereType<DiretivaIdVersaoAppCifras>()
        .toList();
    final idVersaoTexto = idsVersao.length == 1 ? idsVersao.single.id : null;
    if (idVersaoTexto == null) {
      erros.add(
        const ErroArquivoSincronizacao(
          CodigoErroArquivoSincronizacao.idVersaoAusenteOuInvalido,
        ),
      );
    }

    final nomesVersao = documento.elementos
        .whereType<DiretivaNomeVersaoAppCifras>()
        .toList();
    final nomeVersao = nomesVersao.length == 1 ? nomesVersao.single.nome : '';
    if (nomeVersao.isEmpty) {
      erros.add(
        const ErroArquivoSincronizacao(
          CodigoErroArquivoSincronizacao.nomeVersaoInvalido,
        ),
      );
    }

    final principais = documento.elementos
        .whereType<DiretivaPrincipalAppCifras>()
        .toList();
    final principal = principais.isEmpty
        ? false
        : principais.length == 1
        ? principais.single.principal
        : null;
    if (principal == null) {
      erros.add(
        const ErroArquivoSincronizacao(
          CodigoErroArquivoSincronizacao.principalInvalida,
        ),
      );
    }

    final titulos = documento.elementos
        .whereType<DiretivaTituloChordPro>()
        .toList();
    final artistas = documento.elementos
        .whereType<DiretivaArtistaChordPro>()
        .toList();
    final tons = documento.elementos.whereType<DiretivaTomChordPro>().toList();
    final titulo = titulos.length == 1 ? titulos.single.titulo : '';
    final artista = artistas.length == 1 ? artistas.single.artista : '';
    if (titulo.isEmpty ||
        artista.isEmpty ||
        tons.length != 1 ||
        tons.single.tom == null) {
      erros.add(
        const ErroArquivoSincronizacao(
          CodigoErroArquivoSincronizacao.chordProInvalido,
        ),
      );
    }

    if (erros.isNotEmpty) {
      return ArquivoSincronizacaoInvalido(candidato: candidato, erros: erros);
    }

    final idMusica = IdMusica(idMusicaTexto!);
    final idVersaoMusica = IdVersaoMusica(idVersaoTexto!);
    try {
      VersaoMusica(
        id: idVersaoMusica,
        idMusica: idMusica,
        nome: nomeVersao,
        documento: documento,
        principal: principal!,
        arquivada: false,
      );
    } on ArgumentError {
      return ArquivoSincronizacaoInvalido(
        candidato: candidato,
        erros: const [
          ErroArquivoSincronizacao(
            CodigoErroArquivoSincronizacao.chordProInvalido,
          ),
        ],
      );
    }

    return ArquivoSincronizacaoValidado(
      candidato: candidato,
      idMusica: idMusica,
      idVersaoMusica: idVersaoMusica,
      nomeVersao: nomeVersao,
      principalDeclarada: principal,
      hashSha256: sha256.convert(candidato.bytes).toString(),
      titulo: titulo,
      artista: artista,
      documento: documento,
    );
  }
}
