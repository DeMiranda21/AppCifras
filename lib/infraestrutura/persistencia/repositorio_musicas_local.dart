import '../../dominio/chordpro/validador_schema_appcifras.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/entidades/versao_musica.dart';
import '../../dominio/erros/id_musica_ja_existente.dart';
import '../../dominio/erros/musica_em_uso_em_lista.dart';
import '../../dominio/erros/musica_nao_encontrada.dart';
import '../../dominio/erros/operacao_versao_musica_nao_permitida.dart';
import '../../dominio/erros/versao_musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/repositorios/repositorio_musicas.dart';
import '../../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../../aplicacao/entrada/rascunho_documento_chordpro.dart';
import '../arquivos/armazenamento_arquivos_chordpro.dart';
import '../arquivos/codificador_chordpro_gerenciado.dart';
import 'banco_biblioteca.dart';

class EstadoPersistenciaMusicaInconsistente implements Exception {
  const EstadoPersistenciaMusicaInconsistente(this.id);

  final IdMusica id;
}

class RepositorioMusicasLocal
    implements RepositorioMusicas, RepositorioVersoesMusicas {
  RepositorioMusicasLocal({
    required this._banco,
    required this._armazenamentoArquivos,
    ParserDocumentoChordPro? parserDocumento,
    this._codificador = const CodificadorChordProGerenciado(),
    this._validadorSchema = const ValidadorSchemaAppCifras(),
  }) : _parserDocumento = parserDocumento ?? ParserDocumentoChordPro();

  final BancoBiblioteca _banco;
  final ArmazenamentoArquivosChordPro _armazenamentoArquivos;
  final ParserDocumentoChordPro _parserDocumento;
  final CodificadorChordProGerenciado _codificador;
  final ValidadorSchemaAppCifras _validadorSchema;

  @override
  Future<void> salvar(Musica musica) async {
    final versao = musica.versaoPrincipal;
    if (await _banco.obterPorId(musica.id.valor) != null ||
        await _armazenamentoArquivos.existe(versao.id)) {
      throw IdMusicaJaExistente(musica.id);
    }

    final conteudo = _codificador.codificar(musica);
    await _armazenamentoArquivos.salvar(versao.id, conteudo);
    try {
      await _banco.inserir(
        id: musica.id.valor,
        titulo: musica.titulo,
        artista: musica.artista,
        arquivo: _armazenamentoArquivos.nomeArquivo(versao.id),
      );
      await _banco.inserirVersaoMusica(
        id: versao.id.valor,
        idMusica: musica.id.valor,
        nome: versao.nome,
        arquivo: _armazenamentoArquivos.nomeArquivo(versao.id),
        principal: true,
        arquivada: false,
      );
    } catch (erro, pilha) {
      try {
        await _banco.excluirPorId(musica.id.valor);
        await _armazenamentoArquivos.excluir(versao.id);
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(musica.id);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  Future<void> atualizar(Musica musica) async {
    final indice = await _banco.obterPorId(musica.id.valor);
    if (indice == null) {
      throw MusicaNaoEncontrada(musica.id);
    }
    final versaoPersistida = await _banco.obterVersaoPrincipalPorMusica(
      musica.id.valor,
    );
    if (versaoPersistida == null) {
      throw EstadoPersistenciaMusicaInconsistente(musica.id);
    }
    final versao = musica.versaoPrincipal;
    if (versao.id.valor != versaoPersistida.id) {
      throw ArgumentError(
        'A atualização atual opera somente a versão principal.',
      );
    }
    _validarNomeArquivo(versao.id, versaoPersistida.arquivo, musica.id);
    final conteudosAnteriores = <IdVersaoMusica, String>{};
    final conteudosAtualizados = <IdVersaoMusica, String>{};
    final versoes = await _banco.listarVersoesMusica(musica.id.valor);
    for (final registroVersao in versoes) {
      final idVersao = IdVersaoMusica(registroVersao.id);
      _validarNomeArquivo(idVersao, registroVersao.arquivo, musica.id);
      final conteudoAnterior = await _armazenamentoArquivos.obter(idVersao);
      conteudosAnteriores[idVersao] = conteudoAnterior;
      conteudosAtualizados[idVersao] = idVersao == versao.id
          ? _codificador.codificar(musica)
          : _revisarMetadadosCatalogo(
              conteudoAnterior,
              titulo: musica.titulo,
              artista: musica.artista,
            );
    }
    try {
      for (final entrada in conteudosAtualizados.entries) {
        await _armazenamentoArquivos.substituir(entrada.key, entrada.value);
      }
    } catch (erro, pilha) {
      await _restaurarArquivos(musica.id, conteudosAnteriores);
      Error.throwWithStackTrace(erro, pilha);
    }
    try {
      final linhasAtualizadas = await _banco.atualizar(
        id: musica.id.valor,
        titulo: musica.titulo,
        artista: musica.artista,
      );
      if (linhasAtualizadas != 1) {
        throw MusicaNaoEncontrada(musica.id);
      }
    } catch (erro, pilha) {
      await _restaurarArquivos(musica.id, conteudosAnteriores);
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  Future<Musica?> obterPorId(IdMusica id) async {
    final indice = await _banco.obterPorId(id.valor);
    if (indice == null) {
      return null;
    }
    return _reconstruir(id, indice);
  }

  @override
  Future<List<Musica>> listar() async {
    final indices = await _banco.listar();
    return Future.wait(
      indices.map((indice) => _reconstruir(IdMusica(indice.id), indice)),
    );
  }

  @override
  Future<void> excluir(IdMusica id) async {
    final indice = await _banco.obterPorId(id.valor);
    if (indice == null) {
      throw MusicaNaoEncontrada(id);
    }
    if (await _banco.possuiItemListaParaMusica(id.valor)) {
      throw MusicaEmUsoEmLista(id);
    }
    final versoes = await _banco.listarVersoesMusica(id.valor);
    if (versoes.isEmpty) {
      throw EstadoPersistenciaMusicaInconsistente(id);
    }
    final conteudos = <IdVersaoMusica, String>{};
    for (final versao in versoes) {
      final idVersao = IdVersaoMusica(versao.id);
      _validarNomeArquivo(idVersao, versao.arquivo, id);
      conteudos[idVersao] = await _armazenamentoArquivos.obter(idVersao);
      await _armazenamentoArquivos.excluir(idVersao);
    }
    try {
      await _banco.excluirPorId(id.valor);
    } catch (erro, pilha) {
      try {
        for (final entrada in conteudos.entries) {
          await _armazenamentoArquivos.salvar(entrada.key, entrada.value);
        }
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(id);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica idMusica) async {
    final indice = await _banco.obterVersaoPrincipalPorMusica(idMusica.valor);
    return indice == null ? null : _reconstruirVersao(indice);
  }

  @override
  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id) async {
    final indice = await _banco.obterVersaoPorId(id.valor);
    return indice == null ? null : _reconstruirVersao(indice);
  }

  @override
  Future<List<VersaoMusica>> listarPorMusica(IdMusica idMusica) async {
    final indices = await _banco.listarVersoesMusica(idMusica.valor);
    return Future.wait(indices.map(_reconstruirVersao));
  }

  @override
  Future<void> salvarVersao(VersaoMusica versao) async {
    if (await _banco.obterVersaoPorId(versao.id.valor) != null ||
        await _armazenamentoArquivos.existe(versao.id)) {
      throw ArgumentError.value(versao.id, 'versao', 'A versão já existe.');
    }
    if (await _banco.obterPorId(versao.idMusica.valor) == null) {
      throw MusicaNaoEncontrada(versao.idMusica);
    }

    final conteudo = versao.documento.conteudoOriginal;
    await _armazenamentoArquivos.salvar(versao.id, conteudo);
    try {
      await _banco.inserirVersaoMusica(
        id: versao.id.valor,
        idMusica: versao.idMusica.valor,
        nome: versao.nome,
        arquivo: _armazenamentoArquivos.nomeArquivo(versao.id),
        principal: versao.principal,
        arquivada: versao.arquivada,
      );
    } catch (erro, pilha) {
      try {
        await _armazenamentoArquivos.excluir(versao.id);
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(versao.idMusica);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  Future<bool> estaUsadaEmLista(IdVersaoMusica id) =>
      _banco.possuiItemListaParaVersao(id.valor);

  @override
  Future<void> renomear(IdVersaoMusica id, String nome) async {
    final versao = await obterVersaoPorId(id);
    if (versao == null) throw VersaoMusicaNaoEncontrada(id);
    final nomeValidado = VersaoMusica(
      id: versao.id,
      idMusica: versao.idMusica,
      nome: nome,
      documento: versao.documento,
      principal: versao.principal,
      arquivada: versao.arquivada,
    ).nome;
    await _banco.renomearVersaoMusica(id.valor, nomeValidado);
  }

  @override
  Future<void> definirComoPrincipal(IdVersaoMusica id) async {
    final versao = await obterVersaoPorId(id);
    if (versao == null) {
      throw VersaoMusicaNaoEncontrada(id);
    }
    if (versao.arquivada) {
      throw ArgumentError('A versão arquivada não pode ser principal.');
    }
    if (!versao.principal) {
      await _banco.definirVersaoPrincipal(versao.idMusica.valor, id.valor);
    }
  }

  @override
  Future<void> arquivar(IdVersaoMusica id) async {
    final versao = await obterVersaoPorId(id);
    if (versao == null) throw VersaoMusicaNaoEncontrada(id);
    if (versao.principal) throw VersaoPrincipalNaoPodeSerArquivada(versao);
    if (!versao.arquivada) await _banco.definirArquivadaVersao(id.valor, true);
  }

  @override
  Future<void> restaurar(IdVersaoMusica id) async {
    final versao = await obterVersaoPorId(id);
    if (versao == null) throw VersaoMusicaNaoEncontrada(id);
    if (versao.arquivada) await _banco.definirArquivadaVersao(id.valor, false);
  }

  @override
  Future<void> excluirVersao(IdVersaoMusica id) async {
    final versao = await obterVersaoPorId(id);
    if (versao == null) throw VersaoMusicaNaoEncontrada(id);
    if (versao.principal) throw VersaoPrincipalNaoPodeSerExcluida(versao);
    if (await estaUsadaEmLista(id)) throw VersaoMusicaEmUsoEmLista(versao);
    final conteudo = await _armazenamentoArquivos.obter(id);
    await _armazenamentoArquivos.excluir(id);
    try {
      await _banco.excluirVersaoMusica(id.valor);
    } catch (erro, pilha) {
      try {
        await _armazenamentoArquivos.salvar(id, conteudo);
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(versao.idMusica);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  Future<Musica> _reconstruir(IdMusica id, IndiceMusica indice) async {
    final versao = await obterPrincipalPorMusica(id);
    if (versao == null) {
      throw EstadoPersistenciaMusicaInconsistente(id);
    }
    return Musica(
      id: id,
      titulo: indice.titulo,
      artista: indice.artista,
      versaoPrincipal: versao,
    );
  }

  Future<VersaoMusica> _reconstruirVersao(VersoesMusica indice) async {
    final id = IdVersaoMusica(indice.id);
    _validarNomeArquivo(id, indice.arquivo, IdMusica(indice.idMusica));
    try {
      final conteudo = await _armazenamentoArquivos.obter(id);
      final documento = _parserDocumento.interpretar(conteudo);
      _validadorSchema.validarParaIncorporacao(documento);
      return VersaoMusica(
        id: id,
        idMusica: IdMusica(indice.idMusica),
        nome: indice.nome,
        documento: documento,
        principal: indice.principal,
        arquivada: indice.arquivada,
      );
    } catch (_) {
      throw EstadoPersistenciaMusicaInconsistente(IdMusica(indice.idMusica));
    }
  }

  void _validarNomeArquivo(
    IdVersaoMusica id,
    String nomeArquivo,
    IdMusica idMusica,
  ) {
    if (nomeArquivo != _armazenamentoArquivos.nomeArquivo(id)) {
      throw EstadoPersistenciaMusicaInconsistente(idMusica);
    }
  }

  String _revisarMetadadosCatalogo(
    String conteudo, {
    required String titulo,
    required String artista,
  }) =>
      RascunhoDocumentoChordPro.criar(
            conteudoChordPro: conteudo,
            parserDocumento: _parserDocumento,
          )
          .comRevisao(
            RevisaoMetadadosChordPro(titulo: titulo, artista: artista),
          )
          .produzirConteudoFinal();

  Future<void> _restaurarArquivos(
    IdMusica idMusica,
    Map<IdVersaoMusica, String> conteudos,
  ) async {
    try {
      for (final entrada in conteudos.entries) {
        await _armazenamentoArquivos.substituir(entrada.key, entrada.value);
      }
    } catch (_) {
      throw EstadoPersistenciaMusicaInconsistente(idMusica);
    }
  }
}
