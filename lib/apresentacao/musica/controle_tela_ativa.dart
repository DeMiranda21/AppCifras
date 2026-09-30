import 'package:wakelock_plus/wakelock_plus.dart';

/// Mantém a tela ligada enquanto uma cifra está em leitura.
abstract interface class ControleTelaAtiva {
  Future<void> ativar();

  Future<void> desativar();
}

class ControleTelaAtivaWakelockPlus implements ControleTelaAtiva {
  const ControleTelaAtivaWakelockPlus();

  @override
  Future<void> ativar() => WakelockPlus.enable();

  @override
  Future<void> desativar() => WakelockPlus.disable();
}
