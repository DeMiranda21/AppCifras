import 'dart:io';

import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/origem_sincronizada_versao.dart';
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
  const hashA =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const hashB =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  late Directory diretorio;
  late BancoBiblioteca banco;
  late RepositorioMusicasLocal musicas;
  late RepositorioSincronizacaoLocal sincronizacao;
  late IdMusica idMusica;
  late IdVersaoMusica idVersao;

  setUp(() async {
    diretorio = await Directory.systemTemp.createTemp('appcifras_s2_');
    banco = BancoBiblioteca(NativeDatabase.memory());
    musicas = RepositorioMusicasLocal(
      banco: banco,
      armazenamentoArquivos: ArmazenamentoArquivosChordPro(diretorio),
    );
    sincronizacao = RepositorioSincronizacaoLocal(banco);
    idMusica = IdMusica('musica-1');
    await musicas.salvar(
      Musica(
        id: idMusica,
        documento: ParserDocumentoChordPro().interpretar(
          '{title: Título}\n{artist: Artista}\n{key: C}\n[C]Letra',
        ),
      ),
    );
    idVersao = (await musicas.obterPrincipalPorMusica(idMusica))!.id;
  });

  tearDown(() async {
    await banco.close();
    await diretorio.delete(recursive: true);
  });

  test('salva origem e distingue versão sincronizada de local', () async {
    expect(await sincronizacao.obterPorVersao(idVersao), isNull);

    await sincronizacao.salvarOrigem(
      OrigemSincronizadaVersao(
        idVersaoMusica: idVersao,
        localizadorExterno: 'content://drive/document/abc%2Fdef',
        hashSha256: hashA,
        estado: EstadoOrigemSincronizada.presente,
      ),
    );

    final origem = await sincronizacao.obterPorVersao(idVersao);
    expect(origem?.idVersaoMusica, idVersao);
    expect(origem?.localizadorExterno, 'content://drive/document/abc%2Fdef');
    expect(origem?.hashSha256, hashA);
    expect(origem?.presente, isTrue);
  });

  test('reaparecimento atualiza estado, localizador opaco e hash', () async {
    await sincronizacao.salvarOrigem(
      OrigemSincronizadaVersao(
        idVersaoMusica: idVersao,
        localizadorExterno: 'documento-antigo',
        hashSha256: hashA,
        estado: EstadoOrigemSincronizada.presente,
      ),
    );
    await sincronizacao.marcarAusente(idVersao);
    expect((await sincronizacao.obterPorVersao(idVersao))?.presente, isFalse);

    await sincronizacao.marcarPresente(
      idVersao,
      localizadorExterno: 'content://novo.provedor/document/42',
      hashSha256: hashB,
    );

    final origem = await sincronizacao.obterPorVersao(idVersao);
    expect(origem?.presente, isTrue);
    expect(origem?.localizadorExterno, 'content://novo.provedor/document/42');
    expect(origem?.hashSha256, hashB);
    expect((await musicas.obterVersaoPorId(idVersao))?.id, idVersao);
  });

  test('ausência preserva versão, último tom, Lista e classificação', () async {
    await sincronizacao.salvarOrigem(
      OrigemSincronizadaVersao(
        idVersaoMusica: idVersao,
        localizadorExterno: 'content://origem/versao',
        hashSha256: hashA,
        estado: EstadoOrigemSincronizada.presente,
      ),
    );
    await banco.salvarTomExecucao(
      idVersaoMusica: idVersao.valor,
      nomeNota: 'g',
      alteracao: 'natural',
      modo: 'maior',
    );
    await banco.inserirListaCulto(id: 'lista-1', nome: 'Culto');
    await banco.inserirItemListaCulto(
      id: 'item-1',
      idLista: 'lista-1',
      idMusica: idMusica.valor,
      idVersaoMusica: idVersao.valor,
      posicao: 0,
    );
    await banco.definirEnergiaMusica(idMusica.valor, 'animada');
    await banco.substituirTagsMusica(idMusica.valor, const [
      (chave: 'ceia', valor: 'Ceia'),
    ]);

    await sincronizacao.marcarAusente(idVersao);

    expect(await musicas.obterVersaoPorId(idVersao), isNotNull);
    expect(await banco.obterTomExecucaoPorVersao(idVersao.valor), isNotNull);
    expect(
      (await banco.listarItensListaCulto('lista-1')).single.idVersaoMusica,
      idVersao.valor,
    );
    expect(
      (await banco.obterEnergiaMusica(idMusica.valor))?.energia,
      'animada',
    );
    expect((await banco.listarTagsMusica(idMusica.valor)).single.valor, 'Ceia');
  });

  test('exclusão permitida remove vínculo sem deixar órfão', () async {
    final principal = (await musicas.obterVersaoPorId(idVersao))!;
    final idAlternativa = IdVersaoMusica('alternativa');
    await musicas.salvarVersao(
      VersaoMusica(
        id: idAlternativa,
        idMusica: principal.idMusica,
        nome: 'Alternativa',
        documento: principal.documento,
        principal: false,
        arquivada: false,
      ),
    );
    await sincronizacao.salvarOrigem(
      OrigemSincronizadaVersao(
        idVersaoMusica: idAlternativa,
        localizadorExterno: 'document-id-alternativa',
        hashSha256: hashA,
        estado: EstadoOrigemSincronizada.ausente,
      ),
    );

    await musicas.excluirVersao(idAlternativa);

    expect(await musicas.obterVersaoPorId(idAlternativa), isNull);
    expect(await sincronizacao.obterPorVersao(idAlternativa), isNull);
    expect(
      await banco.select(banco.origensSincronizadasVersoes).get(),
      isEmpty,
    );
  });
}
