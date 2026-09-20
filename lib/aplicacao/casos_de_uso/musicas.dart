import '../../dominio/entidades/musica.dart';
import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/chordpro/validador_schema_appcifras.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/erros/id_musica_ja_existente.dart';
import '../../dominio/repositorios/repositorio_musicas.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../portas/gerador_id_musica.dart';

class SalvarMusica {
  const SalvarMusica(this._repositorio);
  final RepositorioMusicas _repositorio;

  Future<void> executar(Musica musica) => _repositorio.salvar(musica);
}

class ObterMusicaPorId {
  const ObterMusicaPorId(this._repositorio);
  final RepositorioMusicas _repositorio;

  Future<Musica?> executar(IdMusica id) => _repositorio.obterPorId(id);
}

class ListarMusicas {
  const ListarMusicas(this._repositorio);
  final RepositorioMusicas _repositorio;

  Future<List<Musica>> executar() => _repositorio.listar();
}

class DadosCadastroMusica {
  const DadosCadastroMusica({
    required this.titulo,
    required this.artista,
    required this.tomOriginal,
    required this.conteudoChordPro,
  });

  final String titulo;
  final String artista;
  final String tomOriginal;
  final String conteudoChordPro;
}

enum CampoCadastroMusica { titulo, artista, tomOriginal, conteudo }

class CadastroMusicaInvalido implements Exception {
  const CadastroMusicaInvalido(this.campo);

  final CampoCadastroMusica campo;
}

class CadastrarMusica {
  const CadastrarMusica({
    required this.repositorio,
    required this.parserDocumento,
    required this.geradorId,
  });

  final RepositorioMusicas repositorio;
  final ParserDocumentoChordPro parserDocumento;
  final GeradorIdMusica geradorId;

  Future<Musica> executar(DadosCadastroMusica dados) async {
    _validarObrigatorios(dados);
    final documento = parserDocumento.interpretar(_montarConteudo(dados));
    final diretivaTom = documento.elementos.whereType<DiretivaTomChordPro>();
    if (diretivaTom.length != 1 || diretivaTom.single.tom == null) {
      throw const CadastroMusicaInvalido(CampoCadastroMusica.tomOriginal);
    }

    late Musica musica;
    try {
      musica = Musica(id: geradorId.gerar(), documento: documento);
    } on ArgumentError {
      throw const CadastroMusicaInvalido(CampoCadastroMusica.conteudo);
    }
    await repositorio.salvar(musica);
    return musica;
  }

  void _validarObrigatorios(DadosCadastroMusica dados) {
    if (dados.titulo.trim().isEmpty) {
      throw const CadastroMusicaInvalido(CampoCadastroMusica.titulo);
    }
    if (dados.artista.trim().isEmpty) {
      throw const CadastroMusicaInvalido(CampoCadastroMusica.artista);
    }
    if (dados.tomOriginal.trim().isEmpty) {
      throw const CadastroMusicaInvalido(CampoCadastroMusica.tomOriginal);
    }
    if (dados.conteudoChordPro.trim().isEmpty) {
      throw const CadastroMusicaInvalido(CampoCadastroMusica.conteudo);
    }
  }

  String _montarConteudo(DadosCadastroMusica dados) =>
      '{title: ${dados.titulo}}\n'
      '{artist: ${dados.artista}}\n'
      '{key: ${dados.tomOriginal}}\n'
      '${dados.conteudoChordPro}';
}

class ExcluirMusica {
  const ExcluirMusica(this._repositorio);
  final RepositorioMusicas _repositorio;

  Future<void> executar(IdMusica id, {required bool confirmada}) {
    if (!confirmada) {
      throw StateError('A exclusão da música exige confirmação explícita.');
    }
    return _repositorio.excluir(id);
  }
}

class ImportarMusica {
  const ImportarMusica({
    required this._repositorio,
    required this._parserDocumento,
    required this._geradorId,
  });

  final RepositorioMusicas _repositorio;
  final ParserDocumentoChordPro _parserDocumento;
  final GeradorIdMusica _geradorId;

  Future<Musica> executar(String conteudoChordProExterno) async {
    final documento = _parserDocumento.interpretar(conteudoChordProExterno);
    const validadorSchema = ValidadorSchemaAppCifras();
    validadorSchema.validarParaIncorporacao(documento);
    final id = _obterId(documento);
    if (await _repositorio.obterPorId(id) != null) {
      throw IdMusicaJaExistente(id);
    }
    final musica = Musica(id: id, documento: documento);
    await _repositorio.salvar(musica);
    return musica;
  }

  IdMusica _obterId(DocumentoChordPro documento) {
    final diretivas = documento.elementos.whereType<DiretivaIdAppCifras>();
    if (diretivas.isEmpty) {
      return _geradorId.gerar();
    }
    if (diretivas.length != 1 || diretivas.single.id == null) {
      throw ArgumentError(
        'A diretiva appcifras_id deve ocorrer uma única vez e ser válida.',
      );
    }
    return IdMusica(diretivas.single.id!);
  }
}
