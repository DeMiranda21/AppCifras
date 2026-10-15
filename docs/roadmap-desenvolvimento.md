# Roadmap de Desenvolvimento — AppCifras

Este é o documento de referência para funcionalidades futuras, prioridades e
dependências. Decisões aprovadas pertencem a decisoes-mvp.md; visão funcional
consolidada, a especificacao-funcional.md. As prioridades indicam ordem de
trabalho, sem representar cronograma.

## Base já entregue

- Biblioteca offline, cadastro por colagem/importação, edição, exclusão
  confirmada e pesquisa textual por título, artista e letra.
- ChordPro canônico, parser conservador e preservação de conteúdo desconhecido.
- Reconhecimento estrutural e editor por blocos derivados do ChordPro, com
  transformações básicas e modo textual avançado.
- Visualização responsiva, transposição temporária, último tom por versão,
  zoom com reflow, swipe entre itens da Lista de Culto e tela mantida ativa
  durante a leitura.
- Listas de Culto: criar, renomear, excluir, adicionar, remover, reordenar,
  escolher a versão concreta do item e navegar entre itens.
- Versões/arranjos até a Fatia C2: fundação, criação, seleção, ciclo de vida e
  edição explícita da VersaoMusica aberta.
- Energia, tags, pesquisa combinada e arquivos ChordPro com SQLite local para
  índices, relações e preferências.

## Prioridade 0 — Rework de entrada e edição

1. **Entrada manual com revisão contextual:** esta é a primeira fatia e cobre
   somente o fluxo colar texto comum → analisar → converter com segurança →
   manter ChordPro interno → revisar problemas em sequência → reanalisar →
   salvar. A tela mostra uma ocorrência concreta por vez, com `Problema X de
   N`, contexto, motivo e ações permitidas. As ações iniciais são `É acorde`,
   `É texto` e `Corrigir acorde`, com correção curta validada por ParserAcorde.
   A ação valida faixa, texto e revisão do rascunho, aplica-se só à ocorrência
   exibida e provoca reanálise integral. Título, artista e tom original seguem
   como campos próprios. Inserção semântica, editor visual completo de acordes,
   seletor avançado, sincronização e importação em lote ficam fora desta fatia.
2. **Diagnóstico contextual da transposição:** depois da primeira fatia,
   reutilizar o modelo de ocorrência e revisão para mostrar e localizar, em
   linguagem simples, cada trecho que impede transposição. Acordes desconhecidos
   continuam preservados e não são corrigidos silenciosamente.
3. **Rework do editor comum:** adaptar reconhecimento estrutural, editor por
   blocos e transformações puras já entregues para operações explícitas sobre
   acordes, texto, linhas e seções. O fluxo comum não dependerá de seleção
   automática, `RenderEditable`, busca com `indexOf` nem menu contextual nativo.
   ChordPro textual permanece secundário, como modo avançado e fallback.

O trabalho de Versões/Arranjos fica pausado depois da C2 enquanto estes três
itens são executados. Esta pausa não remove nem altera o comportamento já
entregue.

## Prioridade 1 — Estrutura, classificação e Listas

4. **Reconhecimento estrutural:** continuar refinando Intro, Verso,
   Pré-Refrão, Refrão, Ponte, Instrumental, Final e outros rótulos, sempre
   preservando o original e priorizando poucos falsos positivos.
5. **Editor por blocos:** manter a fundação entregue com visualização
   estrutural derivada, criação canônica, duplicação literal, exclusão,
   reordenação e edição interna sem expor delimitadores. Permanecem futuras a
   edição avançada de acordes dentro do bloco e a ocultação de blocos para
   reorganização rápida. Qualquer ampliação deve usar a revisão contextual e
   as mesmas transformações seguras do rework.
6. **Tags, classificação e metadados:** energia e tags livres estão entregues.
   Tema, momento, BPM, compasso, duração, dificuldade, ministério, compositor,
   álbum, idioma e instrumentação permanecem futuros.
7. **Pesquisa ampliada e filtros:** busca offline por título, artista e letra,
   combinável com energia e tags, está entregue. Resultados encontrados na
   letra exibem trecho correspondente.
8. **Versões e arranjos:** manter o comportamento entregue até C2. Permanece
   futura a escolha de versão durante a inclusão inicial em Lista; outras
   ampliações serão retomadas depois do rework do editor.
9. **Listas com contexto de ministração:** adicionar data e ministrante
   opcional à Lista e tom snapshot da ocasião ao ItemListaCulto. A Lista é
   memória operacional do repertório, sem estado planejada/executada nem
   entidade autônoma de histórico.
10. **Consulta de Listas anteriores:** pesquisar músicas, data, ministrante,
    versão e tom nas Listas já criadas. Esta visão substitui histórico separado.

## Prioridade 2 — Apoio ao ministrante e evoluções locais

11. **Importação em lote:** primeiro múltiplos arquivos `.cho`; depois `.txt`
    com conversão conservadora, revisão de ambiguidades e resultado por
    arquivo, sem deixar uma falha bloquear o lote inteiro. Duplicidade e o
    destino como Música nova ou VersaoMusica continuam abertos. Este fluxo é
    separado da sincronização com pasta curada.
12. **Descoberta e uso recente:** repertório por classificação, BPM,
    tonalidade, ministrante, Listas anteriores e tempo desde a última aparição;
    recorrência e prevenção de repetição.
13. **BPM e compasso:** BPM por música, indicador luminoso discreto e compasso.
    Sem tap tempo ou metrônomo sonoro.
14. **Biblioteca:** favoritos, recentes, ordenações e coleções personalizadas
    em baixa prioridade.
15. **Seleção direta de tom** e **graus na interface**: cifras, graus ou ambos;
    romano ou numérico.
16. **Estatísticas derivadas das Listas:** frequência de músicas, última
    aparição, tons e repertórios por ministrante. Não persistir estatísticas
    independentes nesta etapa.

## Prioridade 3 — Pasta sincronizada, backup e evoluções remotas

17. **Sincronização inicial com pasta curada:** consumir arquivos `.cho`
    previamente revisados em uma pasta mantida pelo AppCifras, aplicar validação
    técnica leve e refletir o conteúdo na Biblioteca local. Não converter `.txt`
    genérico, não abrir revisão interativa e não confundir este fluxo com
    importação.
18. **Backup e sincronização entre aparelhos:** definir exportação, conflitos e
    continuidade entre dispositivos depois de validar a sincronização local.
19. **Múltiplas bibliotecas públicas ou assináveis:** distribuição, equipe,
    atualização remota e conflitos entre origens são possibilidade distante e
    não orientam a arquitetura atual.

## Prioridade 4 — Interface e plataforma

20. Indicador percentual discreto de zoom e possível suavização visual da
    escala, sem prejudicar reflow, rolagem ou desempenho.
21. Transição horizontal coerente com a direção do swipe entre músicas da
    Lista, preservando resposta imediata.
22. Tema escuro, AMOLED, preferências de visualização e configurações gerais.
23. iOS como evolução posterior; Android continua principal.

## Última etapa — IA

IA não será integrada no horizonte atual. Antes de decidir, avaliar hospedagem
própria. Usos possíveis: tags, tema/energia, estrutura, correção de cifras e
análise de repertório. Não inclui sugestão automática de repertório, tom ou
transições.

## Dependências principais

    Entrada manual contextual → diagnóstico da transposição → rework do editor comum
    Reconhecimento estrutural + blocos + transformações puras → rework do editor comum
    Tags/metadados → pesquisa/filtros → descoberta de repertório
    Versões/arranjos entregues → versão e tom por ItemListaCulto → consulta de Listas
    Contexto da Lista → ministrante/data → descoberta e estatísticas derivadas
    Importação em lote → revisão/duplicidade → fontes externas futuras
    Biblioteca principal → pasta sincronizada curada → backup/sincronização remota
