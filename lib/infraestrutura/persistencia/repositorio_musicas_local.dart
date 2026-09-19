import '../../dominio/chordpro/validador_schema_appcifras.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/erros/id_musica_ja_existente.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/repositorios/repositorio_musicas.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../arquivos/armazenamento_arquivos_chordpro.dart';
import '../arquivos/codificador_chordpro_gerenciado.dart';
import 'banco_biblioteca.dart';

class EstadoPersistenciaMusicaInconsistente implements Exception {
  const EstadoPersistenciaMusicaInconsistente(this.id);

  final IdMusica id;
}

class RepositorioMusicasLocal implements RepositorioMusicas {
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
    if (await _banco.obterPorId(musica.id.valor) != null ||
        await _armazenamentoArquivos.existe(musica.id)) {
      throw IdMusicaJaExistente(musica.id);
    }

    final conteudo = _codificador.codificar(musica);
    await _armazenamentoArquivos.salvar(musica.id, conteudo);
    try {
      await _banco.inserir(
        id: musica.id.valor,
        titulo: musica.titulo,
        artista: musica.artista,
        arquivo: _armazenamentoArquivos.nomeArquivo(musica.id),
      );
    } catch (erro, pilha) {
      try {
        await _armazenamentoArquivos.excluir(musica.id);
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(musica.id);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  Future<Musica?> obterPorId(IdMusica id) async {
    final indice = await _banco.obterPorId(id.valor);
    if (indice == null) {
      return null;
    }
    return _reconstruir(id, indice.arquivo);
  }

  @override
  Future<List<Musica>> listar() async {
    final indices = await _banco.listar();
    return Future.wait(
      indices.map(
        (indice) => _reconstruir(IdMusica(indice.id), indice.arquivo),
      ),
    );
  }

  @override
  Future<void> excluir(IdMusica id) async {
    final indice = await _banco.obterPorId(id.valor);
    if (indice == null) {
      return;
    }
    _validarNomeArquivo(id, indice.arquivo);
    final conteudo = await _armazenamentoArquivos.obter(id);
    await _armazenamentoArquivos.excluir(id);
    try {
      await _banco.excluirPorId(id.valor);
    } catch (erro, pilha) {
      try {
        await _armazenamentoArquivos.salvar(id, conteudo);
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(id);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  Future<Musica> _reconstruir(IdMusica id, String nomeArquivo) async {
    _validarNomeArquivo(id, nomeArquivo);
    try {
      final conteudo = await _armazenamentoArquivos.obter(id);
      final documento = _parserDocumento.interpretar(conteudo);
      _validadorSchema.validarParaIncorporacao(documento);
      return Musica(id: id, documento: documento);
    } catch (_) {
      throw EstadoPersistenciaMusicaInconsistente(id);
    }
  }

  void _validarNomeArquivo(IdMusica id, String nomeArquivo) {
    if (nomeArquivo != _armazenamentoArquivos.nomeArquivo(id)) {
      throw EstadoPersistenciaMusicaInconsistente(id);
    }
  }
}
