enum TipoSecaoMusica {
  intro,
  verso,
  preRefrao,
  refrao,
  ponte,
  instrumental,
  solo,
  encerramento,
  outro,
}

class RotuloSecaoMusica {
  const RotuloSecaoMusica({required this.tipo, required this.rotuloOriginal});

  final TipoSecaoMusica tipo;
  final String rotuloOriginal;
}

class MarcadorSecaoChordPro {
  const MarcadorSecaoChordPro.inicio({
    required this.tipo,
    required this.rotuloOriginal,
    required this.ambiente,
  }) : ehInicio = true;

  const MarcadorSecaoChordPro.fim({required this.tipo, required this.ambiente})
    : ehInicio = false,
      rotuloOriginal = null;

  final bool ehInicio;
  final TipoSecaoMusica tipo;
  final String? rotuloOriginal;
  final String ambiente;
}

/// Centraliza os rótulos inequívocos reconhecidos pelo AppCifras.
///
/// O reconhecimento não altera o texto: quem consome o resultado conserva a
/// grafia original para apresentação e futuras edições assistidas.
class ReconhecedorSecaoMusica {
  static final _diretivaSecao = RegExp(
    r'^\{(start_of_[A-Za-z_]+|end_of_[A-Za-z_]+|soc|eoc|sov|eov|sob|eob)(?::(.*))?\}$',
  );
  static final _label = RegExp(r'^\s*label\s*=\s*"((?:\\.|[^"\\])*)"\s*$');

  RotuloSecaoMusica? reconhecerRotulo(String texto) {
    final original = texto.trim();
    if (original.isEmpty) {
      return null;
    }
    var candidato = original;
    if (candidato.startsWith('[') && candidato.endsWith(']')) {
      candidato = candidato.substring(1, candidato.length - 1).trim();
    }
    if (candidato.endsWith(':')) {
      candidato = candidato.substring(0, candidato.length - 1).trim();
    }
    final normalizado = _normalizar(candidato);
    final tipo = switch (normalizado) {
      'intro' || 'introducao' => TipoSecaoMusica.intro,
      'primeira parte' || 'segunda parte' || 'verso' => TipoSecaoMusica.verso,
      'pre-refrao' || 'pre chorus' => TipoSecaoMusica.preRefrao,
      'refrao' || 'coro' => TipoSecaoMusica.refrao,
      'ponte' => TipoSecaoMusica.ponte,
      'instrumental' => TipoSecaoMusica.instrumental,
      'solo' => TipoSecaoMusica.solo,
      'final' => TipoSecaoMusica.encerramento,
      _
          when RegExp(r'^verso\s+(?:\d+|i|ii|iii|iv|v|vi|vii|viii|ix|x)$')
              .hasMatch(normalizado) =>
        TipoSecaoMusica.verso,
      _ => null,
    };
    return tipo == null
        ? null
        : RotuloSecaoMusica(tipo: tipo, rotuloOriginal: original);
  }

  MarcadorSecaoChordPro? reconhecerDiretiva(String conteudoOriginal) {
    final correspondencia = _diretivaSecao.firstMatch(conteudoOriginal);
    if (correspondencia == null) {
      return null;
    }
    final nome = correspondencia.group(1)!;
    final valor = correspondencia.group(2) ?? '';
    final diretiva = _interpretarNomeDiretiva(nome);
    if (diretiva == null) {
      return null;
    }
    if (!diretiva.ehInicio) {
      return MarcadorSecaoChordPro.fim(
        tipo: diretiva.tipo,
        ambiente: diretiva.ambiente,
      );
    }
    return MarcadorSecaoChordPro.inicio(
      tipo: diretiva.tipo,
      ambiente: diretiva.ambiente,
      rotuloOriginal: _extrairRotulo(valor) ?? conteudoOriginal,
    );
  }

  /// Extrai apenas o label declarado em uma diretiva de abertura.
  ///
  /// Retorna nulo quando a diretiva não é um início reconhecível ou não
  /// declara valor. Isso permite que a edição assistida preserve documentos
  /// externos sem label até uma alteração explícita do usuário.
  String? extrairLabelDaDiretiva(String conteudoOriginal) {
    final correspondencia = _diretivaSecao.firstMatch(conteudoOriginal);
    if (correspondencia == null ||
        !correspondencia.group(1)!.startsWith('start_of_') &&
            !const {'soc', 'sov', 'sob'}.contains(correspondencia.group(1))) {
      return null;
    }
    return _extrairRotulo(correspondencia.group(2) ?? '');
  }

  String escreverInicioCanonico(TipoSecaoMusica tipo, String label) =>
      '{start_of_${ambienteCanonico(tipo)}: label="${escaparLabel(label)}"}';

  String escreverFimCanonico(TipoSecaoMusica tipo) =>
      '{end_of_${ambienteCanonico(tipo)}}';

  String ambienteCanonico(TipoSecaoMusica tipo) => switch (tipo) {
    TipoSecaoMusica.intro => 'intro',
    TipoSecaoMusica.verso => 'verse',
    TipoSecaoMusica.preRefrao => 'pre_chorus',
    TipoSecaoMusica.refrao => 'chorus',
    TipoSecaoMusica.ponte => 'bridge',
    TipoSecaoMusica.instrumental => 'instrumental',
    TipoSecaoMusica.solo => 'solo',
    TipoSecaoMusica.encerramento => 'final',
    TipoSecaoMusica.outro => 'section',
  };

  String escaparLabel(String label) =>
      label.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

  _DiretivaSecao? _interpretarNomeDiretiva(String nome) {
    final longas = switch (nome) {
      'soc' => _DiretivaSecao(
        ehInicio: true,
        ambiente: 'chorus',
        tipo: TipoSecaoMusica.refrao,
      ),
      'eoc' => _DiretivaSecao(
        ehInicio: false,
        ambiente: 'chorus',
        tipo: TipoSecaoMusica.refrao,
      ),
      'sov' => _DiretivaSecao(
        ehInicio: true,
        ambiente: 'verse',
        tipo: TipoSecaoMusica.verso,
      ),
      'eov' => _DiretivaSecao(
        ehInicio: false,
        ambiente: 'verse',
        tipo: TipoSecaoMusica.verso,
      ),
      'sob' => _DiretivaSecao(
        ehInicio: true,
        ambiente: 'bridge',
        tipo: TipoSecaoMusica.ponte,
      ),
      'eob' => _DiretivaSecao(
        ehInicio: false,
        ambiente: 'bridge',
        tipo: TipoSecaoMusica.ponte,
      ),
      _ => null,
    };
    if (longas != null) {
      return longas;
    }
    final ehInicio = nome.startsWith('start_of_');
    final ambiente = nome.substring(
      ehInicio ? 'start_of_'.length : 'end_of_'.length,
    );
    return _DiretivaSecao(
      ehInicio: ehInicio,
      ambiente: ambiente,
      tipo: _tipoDaDiretiva(ambiente),
    );
  }

  String? _extrairRotulo(String valor) {
    if (valor.trim().isEmpty) {
      return null;
    }
    final label = _label.firstMatch(valor);
    return label == null ? valor.trim() : _desescaparLabel(label.group(1)!);
  }

  String _desescaparLabel(String valor) {
    final resultado = StringBuffer();
    for (var indice = 0; indice < valor.length; indice += 1) {
      final caractere = valor[indice];
      if (caractere == r'\' && indice + 1 < valor.length) {
        final proximo = valor[indice + 1];
        if (proximo == r'\' || proximo == '"') {
          resultado.write(proximo);
          indice += 1;
          continue;
        }
      }
      resultado.write(caractere);
    }
    return resultado.toString();
  }

  TipoSecaoMusica _tipoDaDiretiva(String sufixo) =>
      switch (_normalizar(sufixo)) {
        'chorus' || 'refrao' => TipoSecaoMusica.refrao,
        'verse' || 'verso' => TipoSecaoMusica.verso,
        'pre chorus' || 'pre-refrao' => TipoSecaoMusica.preRefrao,
        'bridge' || 'ponte' => TipoSecaoMusica.ponte,
        'intro' || 'introducao' => TipoSecaoMusica.intro,
        'instrumental' => TipoSecaoMusica.instrumental,
        'solo' => TipoSecaoMusica.solo,
        'outro' || 'final' || 'end' => TipoSecaoMusica.encerramento,
        _ => TipoSecaoMusica.outro,
      };

  String _normalizar(String texto) => texto
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('ç', 'c')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'\s+'), ' ');
}

class _DiretivaSecao {
  const _DiretivaSecao({
    required this.ehInicio,
    required this.ambiente,
    required this.tipo,
  });

  final bool ehInicio;
  final String ambiente;
  final TipoSecaoMusica tipo;
}
