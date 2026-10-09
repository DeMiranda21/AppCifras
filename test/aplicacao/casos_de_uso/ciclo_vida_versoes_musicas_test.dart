import 'package:appcifras/aplicacao/casos_de_uso/ciclo_vida_versoes_musicas.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/erros/operacao_versao_musica_nao_permitida.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_versoes_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();
  final idMusica = IdMusica('musica');
  VersaoMusica criar(
    String id, {
    bool principal = false,
    bool arquivada = false,
    String nome = 'Nome',
  }) => VersaoMusica(
    id: IdVersaoMusica(id),
    idMusica: idMusica,
    nome: nome,
    documento: parser.interpretar(
      '{title: T}\n{artist: A}\n{key: C}\n[C]Letra',
    ),
    principal: principal,
    arquivada: arquivada,
  );

  test('renomeia inclusive versão usada preservando sua identidade', () async {
    final principal = criar('principal', principal: true);
    final usada = criar('usada');
    final repo = _RepositorioMemoria([principal, usada], usadas: {usada.id});
    await RenomearVersaoMusica(repo).executar(usada.id, '  Acústica  ');
    final resultado = (await repo.obterVersaoPorId(usada.id))!;
    expect(resultado.nome, 'Acústica');
    expect(resultado.id, usada.id);
    expect(resultado.idMusica, usada.idMusica);
    expect(resultado.documento, usada.documento);
    expect(resultado.principal, isFalse);
    expect(resultado.arquivada, isFalse);
  });

  test('troca principal ativa, preservando as identidades', () async {
    final principal = criar('principal', principal: true);
    final alternativa = criar('alternativa');
    final repo = _RepositorioMemoria([principal, alternativa]);
    await DefinirVersaoPrincipal(repo).executar(alternativa.id);
    final versoes = await repo.listarPorMusica(idMusica);
    expect(versoes.where((versao) => versao.principal), [
      isA<VersaoMusica>().having((v) => v.id, 'id', alternativa.id),
    ]);
    await DefinirVersaoPrincipal(repo).executar(alternativa.id);
    expect(
      (await repo.listarPorMusica(idMusica)).where((v) => v.principal),
      hasLength(1),
    );
  });

  test(
    'bloqueia principal arquivada e exclusão de principal ou usada',
    () async {
      final principal = criar('principal', principal: true);
      final usada = criar('usada');
      final repo = _RepositorioMemoria([principal, usada], usadas: {usada.id});
      await expectLater(
        ArquivarVersaoMusica(repo).executar(principal.id),
        throwsA(isA<VersaoPrincipalNaoPodeSerArquivada>()),
      );
      await expectLater(
        ExcluirVersaoMusica(repo).executar(principal.id),
        throwsA(isA<VersaoPrincipalNaoPodeSerExcluida>()),
      );
      await expectLater(
        ExcluirVersaoMusica(repo).executar(usada.id),
        throwsA(isA<VersaoMusicaEmUsoEmLista>()),
      );
    },
  );

  test('arquiva, restaura e exclui alternativa não usada', () async {
    final principal = criar('principal', principal: true);
    final alternativa = criar('alternativa');
    final repo = _RepositorioMemoria([principal, alternativa]);
    await ArquivarVersaoMusica(repo).executar(alternativa.id);
    expect((await repo.obterVersaoPorId(alternativa.id))!.arquivada, isTrue);
    await RestaurarVersaoMusica(repo).executar(alternativa.id);
    expect((await repo.obterVersaoPorId(alternativa.id))!.arquivada, isFalse);
    await ExcluirVersaoMusica(repo).executar(alternativa.id);
    expect(await repo.obterVersaoPorId(alternativa.id), isNull);
    expect(await repo.obterVersaoPorId(principal.id), principal);
  });
}

class _RepositorioMemoria implements RepositorioVersoesMusicas {
  _RepositorioMemoria(
    Iterable<VersaoMusica> valores, {
    Set<IdVersaoMusica>? usadas,
  }) : _versoes = {for (final versao in valores) versao.id: versao},
       _usadas = usadas ?? {};
  final Map<IdVersaoMusica, VersaoMusica> _versoes;
  final Set<IdVersaoMusica> _usadas;
  @override
  Future<bool> estaUsadaEmLista(IdVersaoMusica id) async =>
      _usadas.contains(id);
  @override
  Future<void> arquivar(IdVersaoMusica id) async {
    final v = _versoes[id]!;
    if (v.principal) throw VersaoPrincipalNaoPodeSerArquivada(v);
    _versoes[id] = VersaoMusica(
      id: v.id,
      idMusica: v.idMusica,
      nome: v.nome,
      documento: v.documento,
      principal: false,
      arquivada: true,
    );
  }

  @override
  Future<void> restaurar(IdVersaoMusica id) async {
    final v = _versoes[id]!;
    _versoes[id] = VersaoMusica(
      id: v.id,
      idMusica: v.idMusica,
      nome: v.nome,
      documento: v.documento,
      principal: v.principal,
      arquivada: false,
    );
  }

  @override
  Future<void> excluirVersao(IdVersaoMusica id) async {
    final v = _versoes[id]!;
    if (v.principal) throw VersaoPrincipalNaoPodeSerExcluida(v);
    if (_usadas.contains(id)) throw VersaoMusicaEmUsoEmLista(v);
    _versoes.remove(id);
  }

  @override
  Future<void> definirComoPrincipal(IdVersaoMusica id) async {
    final alvo = _versoes[id]!;
    if (alvo.arquivada) throw ArgumentError();
    for (final v in _versoes.values.toList()) {
      if (v.idMusica == alvo.idMusica) {
        _versoes[v.id] = VersaoMusica(
          id: v.id,
          idMusica: v.idMusica,
          nome: v.nome,
          documento: v.documento,
          principal: v.id == id,
          arquivada: v.arquivada,
        );
      }
    }
  }

  @override
  Future<void> renomear(IdVersaoMusica id, String nome) async {
    final v = _versoes[id]!;
    _versoes[id] = VersaoMusica(
      id: v.id,
      idMusica: v.idMusica,
      nome: nome,
      documento: v.documento,
      principal: v.principal,
      arquivada: v.arquivada,
    );
  }

  @override
  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id) async =>
      _versoes[id];
  @override
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica id) async => _versoes
      .values
      .where((v) => v.idMusica == id && v.principal)
      .cast<VersaoMusica?>()
      .firstWhere((v) => v != null, orElse: () => null);
  @override
  Future<List<VersaoMusica>> listarPorMusica(IdMusica id) async =>
      _versoes.values.where((v) => v.idMusica == id).toList();
  @override
  Future<void> salvarVersao(VersaoMusica versao) async =>
      _versoes[versao.id] = versao;
}
