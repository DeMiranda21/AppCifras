import 'dart:io';

import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_tom_execucao_local.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recupera último tom após reabrir o mesmo SQLite físico', () async {
    final diretorio = await Directory.systemTemp.createTemp(
      'appcifras_tom_execucao_',
    );
    final arquivo = File(
      '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
    );
    final id = IdMusica('musica-1');
    final idVersao = IdVersaoMusica(id.valor);
    const tom = Tom(
      notaFundamental: Nota(
        nome: NomeNota.f,
        alteracao: AlteracaoNota.sustenido,
      ),
      modo: ModoTom.menor,
    );

    final primeiroBanco = BancoBiblioteca(NativeDatabase(arquivo));
    await primeiroBanco.inicializar();
    await primeiroBanco.inserir(
      id: id.valor,
      titulo: 'Título',
      artista: 'Artista',
      arquivo: 'musica-1.cho',
    );
    await primeiroBanco.inserirVersaoMusica(
      id: idVersao.valor,
      idMusica: id.valor,
      nome: 'Principal',
      arquivo: 'musica-1.cho',
      principal: true,
      arquivada: false,
    );
    final primeirasPreferencias = RepositorioTomExecucaoLocal(primeiroBanco);
    expect(await primeirasPreferencias.obterUltimoTom(idVersao), isNull);

    await primeirasPreferencias.salvarUltimoTom(idVersao, tom);
    expect(await primeirasPreferencias.obterUltimoTom(idVersao), tom);
    await primeiroBanco.close();

    final segundoBanco = BancoBiblioteca(NativeDatabase(arquivo));
    await segundoBanco.inicializar();
    final preferencias = RepositorioTomExecucaoLocal(segundoBanco);

    expect(await preferencias.obterUltimoTom(idVersao), tom);

    await preferencias.removerUltimoTom(idVersao);
    expect(await preferencias.obterUltimoTom(idVersao), isNull);

    await segundoBanco.close();
    await diretorio.delete(recursive: true);
  });

  test(
    'mantém preferências independentes para versões da mesma música',
    () async {
      final banco = BancoBiblioteca(NativeDatabase.memory());
      await banco.inicializar();
      const idMusica = 'musica-1';
      final versaoA = IdVersaoMusica('versao-a');
      final versaoB = IdVersaoMusica('versao-b');
      await banco.inserir(
        id: idMusica,
        titulo: 'Título',
        artista: 'Artista',
        arquivo: 'versao-a.cho',
      );
      await banco.inserirVersaoMusica(
        id: versaoA.valor,
        idMusica: idMusica,
        nome: 'Principal',
        arquivo: 'versao-a.cho',
        principal: true,
        arquivada: false,
      );
      await banco.inserirVersaoMusica(
        id: versaoB.valor,
        idMusica: idMusica,
        nome: 'Acústica',
        arquivo: 'versao-b.cho',
        principal: false,
        arquivada: false,
      );
      final repositorio = RepositorioTomExecucaoLocal(banco);
      const tomA = Tom(
        notaFundamental: Nota(nome: NomeNota.c),
        modo: ModoTom.maior,
      );
      const tomB = Tom(
        notaFundamental: Nota(nome: NomeNota.d),
        modo: ModoTom.maior,
      );

      await repositorio.salvarUltimoTom(versaoA, tomA);
      await repositorio.salvarUltimoTom(versaoB, tomB);

      expect(await repositorio.obterUltimoTom(versaoA), tomA);
      expect(await repositorio.obterUltimoTom(versaoB), tomB);
      await banco.close();
    },
  );
}
