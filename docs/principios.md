# Princípios do Projeto

Estes princípios são estáveis e orientam decisões de produto, arquitetura e
implementação.

- **Offline primeiro.** Depois de disponíveis localmente, músicas e fluxos
  essenciais funcionam sem internet.
- **Biblioteca antes de arquivos isolados.** O usuário trabalha com repertório;
  arquivos externos são fontes de importação.
- **ChordPro canônico, sintaxe opcional na UX.** O conteúdo musical tem fonte
  preservada; leitura, transposição e graus são representações derivadas. Nas
  tarefas comuns, a interface deve preferir ações semânticas a exigir que o
  usuário escreva a sintaxe ChordPro.
- **Poucos toques e uso real.** Em ensaios e cultos, rapidez, legibilidade,
  estabilidade e baixa distração superam efeitos visuais.
- **Domínio independente.** Regras musicais não dependem de Flutter, banco,
  arquivos ou APIs.
- **Simplicidade responsável.** Complexidade, abstrações e entidades só entram
  quando resolvem necessidade concreta.
- **Evolução incremental.** Entregar, observar e ampliar sem reescrever o
  núcleo desnecessariamente.
- **Fonte de verdade clara.** Cada informação e documento tem responsabilidade
  definida, sem duplicação concorrente.
