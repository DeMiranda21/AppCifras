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
- Entrar na Biblioteca e retornar a ela deve permanecer responsivo com a
  Biblioteca Oficial completa, inclusive acima de 2.000 músicas. A solução
  deve ser escolhida a partir de medição que separe consulta SQLite, leitura e
  parsing de ChordPro, criação do índice de pesquisa e construção de widgets.
- Listagem e pesquisa da Biblioteca reutilizam projeções leves e índices
  textuais persistidos; não devem reconstruir todas as Musicas nem ler todos os
  arquivos `.cho` em cada abertura ou retorno.
- O detalhe de Lista e as consultas históricas trabalham com IDs, colunas
  SQLite, projeções leves e mapas agregados. Devem deduplicar referências,
  evitar consultas por item, não reconstruir ChordPro para responder histórico
  e isolar a falha de uma versão sem derrubar a Lista.
- Inclusões múltiplas devem resolver versões e tons em lote e persistir em
  transação. A navegação por swipe não deve repetir consulta histórica a cada
  item, e o seletor de músicas deve reutilizar `ItemBiblioteca`.
- Rolagem é fluida, com consumo moderado de memória e bateria.
- A cifra cabe na largura útil sem truncamento, ellipsis ou rolagem horizontal
  no modo normal; o reflow preserva acorde e trecho associado.
- Interface de celular é legível, acessível e exige poucos toques.

## Manutenibilidade

- Domínio e aplicação independentes de Flutter e infraestrutura.
- Baixo acoplamento, responsabilidades claras e testes proporcionais ao risco.
- Evoluções preservam contratos e conteúdo existente sempre que possível.
