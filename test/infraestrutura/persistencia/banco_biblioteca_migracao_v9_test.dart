import 'dart:io';

import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'migração v9 preserva instalação e inicializa índice textual uma única vez',
    () async {
      final diretorio = await Directory.systemTemp.createTemp(
        'appcifras_migracao_v9_',
      );
      addTearDown(() => diretorio.delete(recursive: true));
      final arquivoBanco = File('${diretorio.path}/biblioteca.sqlite');
      final diretorioMusicas = Directory('${diretorio.path}/musicas');
      final armazenamento = _ArmazenamentoContado(diretorioMusicas);
      final bancoInicial = BancoBiblioteca(NativeDatabase(arquivoBanco));
      final repositorioInicial = RepositorioMusicasLocal(
        banco: bancoInicial,
        armazenamentoArquivos: armazenamento,
      );
      final musica = Musica(
        id: IdMusica('musica-existente'),
        documento: ParserDocumentoChordPro().interpretar(
          '{title: Existente}\n{artist: Artista}\n{key: C}\n'
          '[C]Letra preservada',
        ),
      );
      await repositorioInicial.salvar(musica);
      await bancoInicial.customStatement('DROP TABLE indices_pesquisa_musicas');
      await bancoInicial.customStatement('PRAGMA user_version = 8');
      await bancoInicial.close();

      final bancoMigrado = BancoBiblioteca(NativeDatabase(arquivoBanco));
      final repositorioMigrado = RepositorioMusicasLocal(
        banco: bancoMigrado,
        armazenamentoArquivos: armazenamento,
      );
      addTearDown(bancoMigrado.close);
      armazenamento.leituras = 0;

      final primeira = await repositorioMigrado.listarItensBiblioteca();
      expect(primeira.single.titulo, 'Existente');
      expect(primeira.single.conteudoVisivel, contains('Letra preservada'));
      expect(armazenamento.leituras, 1);
      final versaoAntes = await repositorioMigrado.obterVersaoPorId(
        IdVersaoMusica('musica-existente'),
      );
      expect(versaoAntes, isNotNull);

      armazenamento.leituras = 0;
      final segunda = await repositorioMigrado.listarItensBiblioteca();
      expect(segunda.single.idMusica, musica.id);
      expect(armazenamento.leituras, 0);
    },
  );
}

class _ArmazenamentoContado extends ArmazenamentoArquivosChordPro {
  _ArmazenamentoContado(super.diretorioMusicas);

  var leituras = 0;

  @override
  Future<String> obter(IdVersaoMusica id) {
    leituras++;
    return super.obter(id);
  }
}
