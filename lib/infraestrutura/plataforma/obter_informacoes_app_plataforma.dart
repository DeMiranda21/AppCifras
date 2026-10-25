import 'package:package_info_plus/package_info_plus.dart';

import '../../aplicacao/portas/obter_informacoes_app.dart';

class ObterInformacoesAppPlataforma implements ObterInformacoesApp {
  const ObterInformacoesAppPlataforma();

  static const _commitGitCompilado = String.fromEnvironment('APP_GIT_COMMIT');

  @override
  Future<InformacoesApp> executar() async {
    final pacote = await PackageInfo.fromPlatform();
    final commit = _commitGitCompilado.trim();
    return InformacoesApp(
      versao: pacote.version,
      numeroBuild: pacote.buildNumber,
      commitGit: commit.isEmpty ? null : commit,
    );
  }
}
