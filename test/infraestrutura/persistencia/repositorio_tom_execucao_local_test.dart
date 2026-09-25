import 'dart:io';

import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
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
    final primeirasPreferencias = RepositorioTomExecucaoLocal(primeiroBanco);
    expect(await primeirasPreferencias.obterUltimoTom(id), isNull);

    await primeirasPreferencias.salvarUltimoTom(id, tom);
    expect(await primeirasPreferencias.obterUltimoTom(id), tom);
    await primeiroBanco.close();

    final segundoBanco = BancoBiblioteca(NativeDatabase(arquivo));
    await segundoBanco.inicializar();
    final preferencias = RepositorioTomExecucaoLocal(segundoBanco);

    expect(await preferencias.obterUltimoTom(id), tom);

    await preferencias.removerUltimoTom(id);
    expect(await preferencias.obterUltimoTom(id), isNull);

    await segundoBanco.close();
    await diretorio.delete(recursive: true);
  });
}
