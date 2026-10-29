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
    'migração v10 prepara pesquisa usando índice v9 sem reler ChordPro',
    () async {
      final diretorio = await Directory.systemTemp.createTemp(
        'appcifras_migracao_v10_',
      );
      addTearDown(() => diretorio.delete(recursive: true));
      final arquivoBanco = File('${diretorio.path}/biblioteca.sqlite');
      final armazenamento = _ArmazenamentoContado(
        Directory('${diretorio.path}/musicas'),
      );
      final bancoInicial = BancoBiblioteca(NativeDatabase(arquivoBanco));
      final repositorioInicial = RepositorioMusicasLocal(
        banco: bancoInicial,
        armazenamentoArquivos: armazenamento,
      );
      await repositorioInicial.salvar(
        Musica(
          id: IdMusica('musica-existente'),
          documento: ParserDocumentoChordPro().interpretar(
            '{title: Graça Existente}\n{artist: Ministério}\n{key: C}\n'
            '[C]Letra preservada',
          ),
        ),
      );
      await bancoInicial.customStatement(
        'ALTER TABLE indices_pesquisa_musicas '
        'RENAME TO indices_pesquisa_musicas_v10',
      );
      await bancoInicial.customStatement(
        'CREATE TABLE indices_pesquisa_musicas ('
        'id_musica TEXT NOT NULL PRIMARY KEY '
        'REFERENCES indice_musicas(id) ON DELETE CASCADE, '
        'id_versao_musica TEXT NOT NULL '
        'REFERENCES versoes_musicas(id) ON DELETE CASCADE, '
        'conteudo_visivel TEXT NOT NULL)',
      );
      await bancoInicial.customStatement(
        'INSERT INTO indices_pesquisa_musicas '
        '(id_musica, id_versao_musica, conteudo_visivel) '
        'SELECT id_musica, id_versao_musica, conteudo_visivel '
        'FROM indices_pesquisa_musicas_v10',
      );
      await bancoInicial.customStatement(
        'DROP TABLE indices_pesquisa_musicas_v10',
      );
      await bancoInicial.customStatement('PRAGMA user_version = 9');
      await bancoInicial.close();

      final bancoMigrado = BancoBiblioteca(NativeDatabase(arquivoBanco));
      final repositorioMigrado = RepositorioMusicasLocal(
        banco: bancoMigrado,
        armazenamentoArquivos: armazenamento,
      );
      addTearDown(bancoMigrado.close);
      armazenamento.leituras = 0;

      final primeira =
          (await repositorioMigrado.listarItensBiblioteca()).single;
      expect(primeira.tituloNormalizado, 'graca existente');
      expect(
        primeira.textoNormalizado,
        contains('ministerio letra preservada'),
      );
      expect(armazenamento.leituras, 0);

      final indicePersistido = await bancoMigrado
          .customSelect(
            'SELECT titulo_normalizado, texto_normalizado '
            'FROM indices_pesquisa_musicas',
          )
          .getSingle();
      expect(
        indicePersistido.read<String>('titulo_normalizado'),
        'graca existente',
      );
      expect(
        indicePersistido.read<String>('texto_normalizado'),
        primeira.textoNormalizado,
      );

      armazenamento.leituras = 0;
      final segunda = (await repositorioMigrado.listarItensBiblioteca()).single;
      expect(segunda.textoNormalizado, primeira.textoNormalizado);
      expect(armazenamento.leituras, 0);
    },
    timeout: const Timeout(Duration(minutes: 2)),
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
