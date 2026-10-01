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
  }) : ehInicio = true;

  const MarcadorSecaoChordPro.fim({required this.tipo})
    : ehInicio = false,
      rotuloOriginal = null;

  final bool ehInicio;
  final TipoSecaoMusica tipo;
  final String? rotuloOriginal;
}

/// Centraliza os rótulos inequívocos reconhecidos pelo AppCifras.
///
/// O reconhecimento não altera o texto: quem consome o resultado conserva a
/// grafia original para apresentação e futuras edições assistidas.
class ReconhecedorSecaoMusica {
  static final _diretivaSecao = RegExp(
    r'^\{(start_of_[A-Za-z_]+|end_of_[A-Za-z_]+)(?::(.*))?\}$',
  );

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
      'pre-refrao' => TipoSecaoMusica.preRefrao,
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
    final valor = (correspondencia.group(2) ?? '').trim();
    final ehInicio = nome.startsWith('start_of_');
    final sufixo = nome.substring(
      ehInicio ? 'start_of_'.length : 'end_of_'.length,
    );
    final tipoPadrao = _tipoDaDiretiva(sufixo);
    if (!ehInicio) {
      return MarcadorSecaoChordPro.fim(tipo: tipoPadrao);
    }
    final rotulo = valor.isEmpty ? conteudoOriginal : valor;
    final tipo = reconhecerRotulo(valor)?.tipo ?? tipoPadrao;
    return MarcadorSecaoChordPro.inicio(tipo: tipo, rotuloOriginal: rotulo);
  }

  TipoSecaoMusica _tipoDaDiretiva(String sufixo) =>
      switch (_normalizar(sufixo)) {
        'chorus' || 'refrao' => TipoSecaoMusica.refrao,
        'verse' || 'verso' => TipoSecaoMusica.verso,
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
