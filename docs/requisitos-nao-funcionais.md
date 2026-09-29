# Requisitos Não Funcionais

## Plataforma

- Android é a plataforma principal, com mínimo API 23 (Android 6.0).
- Flutter permanece em canal estável.
- Samsung Galaxy A72 é a referência de validação prática.
- iOS é evolução futura, sem comprometer a independência do domínio e da
  aplicação.

## Offline e confiabilidade

- Biblioteca, cifras, Listas de Culto e preferências locais funcionam sem
  internet.
- Cada música permanece em arquivo UTF-8 ChordPro; SQLite guarda índice e
  estado local derivado.
- Persistência mantém coerência entre arquivo e índice e não perde conteúdo
  silenciosamente em falhas.

## Desempenho e legibilidade

- Abrir música, pesquisar, navegar entre itens e transpor deve ter resposta
  percebida como imediata no aparelho de referência.
- Rolagem é fluida, com consumo moderado de memória e bateria.
- A cifra cabe na largura útil sem truncamento, ellipsis ou rolagem horizontal
  no modo normal; o reflow preserva acorde e trecho associado.
- Interface de celular é legível, acessível e exige poucos toques.

## Manutenibilidade

- Domínio e aplicação independentes de Flutter e infraestrutura.
- Baixo acoplamento, responsabilidades claras e testes proporcionais ao risco.
- Evoluções preservam contratos e conteúdo existente sempre que possível.
