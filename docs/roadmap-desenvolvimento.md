# Roadmap de Desenvolvimento — AppCifras

Este é o documento de referência para funcionalidades futuras, prioridades e
dependências. Decisões aprovadas pertencem a decisoes-mvp.md; visão funcional
consolidada, a especificacao-funcional.md.

## Base já entregue

- Biblioteca offline, cadastro por colagem/importação, edição, exclusão
  confirmada e pesquisa textual por título, artista e letra.
- ChordPro canônico, parser conservador e preservação de conteúdo desconhecido.
- Visualização responsiva, transposição temporária, último tom por música,
  zoom com reflow, swipe entre itens da Lista de Culto e tela mantida ativa
  durante a leitura.
- Listas de Culto: criar, renomear, excluir, adicionar, remover, reordenar e
  navegar entre itens.
- Arquivos ChordPro e SQLite local para índices e preferências.

## Prioridade 0 — Qualidade do núcleo

1. **Falsos acordes e localização de erros:** reconhecer rótulos como Intro,
   Verso, Refrão, Ponte e Final; evitar texto comum como acorde; destacar e
   permitir localizar no editor o trecho que bloqueia transposição. Explicar
   em linguagem simples por que o trecho exige revisão, com orientação
   contextual quando houver informação suficiente.
2. **Zoom com reflow:** pinch zoom e tamanho de fonte, recompondo letra e
   acordes sem rolagem horizontal. Adicionar futuramente um indicador
   percentual discreto de zoom e avaliar suavização visual da escala, sem
   prejudicar reflow, rolagem vertical, desempenho ou resposta ao gesto.
3. **Transições de leitura:** animar futuramente a troca horizontal entre
   músicas da Lista de Culto de modo coerente com a direção do swipe, sem
   prejudicar a resposta imediata à navegação.

## Prioridade 1 — Estrutura, classificação, versões e Listas

5. **Reconhecimento estrutural:** Intro, Verso, Pré-Refrão, Refrão, Ponte,
   Instrumental, Final e outros rótulos, sempre preservando o original.
6. **Edição assistida básica:** marcar uma seleção válida como acorde/tratar
   acorde entre colchetes como texto, transformar uma linha selecionada em
   seção ChordPro e editar tipo/rótulo de uma seção explícita. A edição por
   blocos reutiliza essas transformações e mantém o ChordPro como fonte de
   verdade. O toque simples seleciona automaticamente palavras e tokens
   musicais completos; a seleção manual por pressão longa permanece como
   alternativa. O mesmo toque que seleciona automaticamente abre o menu
   contextual nativo. As ações de acorde são oferecidas nesse menu; a
   descoberta/onboarding dessa interação permanece futura.
   `Tratar como texto` deverá ganhar uma apresentação mais encontrável, sem
   depender da posição variável do menu nativo. Permanecem futuras: editar
   acorde e movimento de seções.
7. **Editor por blocos:** fundação entregue com alternância entre blocos e
   ChordPro textual, visualização estrutural derivada, criação canônica,
   duplicação literal, exclusão confirmada e reordenação por arraste de
   seções com limites confiáveis. O conteúdo interno de uma seção também é
   editável sem expor seus delimitadores estruturais e reutiliza as ações de
   marcar como acorde/tratar como texto. ChordPro textual segue como modo
   avançado/fallback. A saída da edição protege alterações não salvas, e o
   editor local de conteúdo confirma o descarte de alterações ainda não
   aplicadas.
   A divisão explícita de bloco por linha persiste fronteiras entre trechos
   livres com diretiva interna, sem atribuir semântica musical à segunda parte.
   Permanecem futuras: edição avançada de acordes dentro do bloco e ocultação
   de blocos para reorganização rápida. Trechos musicais fora de seção também
   aparecem como blocos derivados. As operações básicas de editar, mover,
   duplicar e excluir usam a mesma regra de faixa segura para seções ChordPro
   explícitas, rótulos textuais reconhecidos e trechos livres; metadados,
   diretivas e espaçadores isolados não viram blocos.
8. **Tags, classificação e metadados:** energia (Calma, Moderada ou Animada)
   e tags livres entregues como metadados locais. Tema, momento, BPM, compasso,
   duração, dificuldade, ministério, compositor, álbum, idioma e
   instrumentação permanecem futuros.
9. **Pesquisa ampliada e filtros:** busca textual offline por título, artista
   e letra, combinável com filtros por energia e tags. Resultados encontrados
   na letra exibem o primeiro trecho visível correspondente, entregue.
10. **Versões e arranjos:** introduzir VersaoMusica como arranjo concreto de
    uma Música, com versão principal protegida contra sobrescrita silenciosa.
    Migrar a cifra única atual para a versão principal e permitir que uma nova
    versão nasça de outra. Após uso em Lista, o conteúdo musical da versão será
    imutável; versões usadas serão arquivadas, não excluídas, e a marca de
    principal poderá ser trocada sem alterar identidade ou conteúdo.
11. **Listas com contexto de ministração:** adicionar data e ministrante
    opcional à Lista; fazer o Item registrar Música, versão escolhida e tom
    snapshot da ocasião. A Lista é memória operacional do repertório, sem
    estado planejada/executada nem entidade autônoma de histórico.
12. **Consulta de Listas anteriores:** pesquisar músicas, data, ministrante,
    versão e tom nas Listas já criadas. Esta visão substitui o antigo item de
    Histórico separado.

## Prioridade 2 — Apoio ao ministrante e evoluções locais

13. **Importação em lote:** primeiro múltiplos arquivos `.cho`; depois `.txt`
    com conversão conservadora, revisão de ambiguidades e resultado por
    arquivo, sem deixar uma falha bloquear o lote inteiro. Duplicidade e o
    destino de um arquivo como Música nova ou VersaoMusica continuam abertos.
14. **Descoberta e uso recente:** repertório por classificação, BPM,
    tonalidade, ministrante, Listas anteriores e tempo desde a última
    aparição em Lista;
    recorrência e prevenção de repetição.
15. **BPM e compasso:** BPM por música, indicador luminoso discreto e
    compasso. Sem tap tempo ou metrônomo sonoro.
16. **Biblioteca:** favoritos, recentes, ordenações e coleções personalizadas
    em baixa prioridade.
17. **Seleção direta de tom** e **graus na interface** (cifras, graus ou
    ambos; romano ou numérico).
18. **Estatísticas derivadas das Listas:** frequência de músicas, última
    aparição, tons e repertórios por ministrante. Não persistir estatísticas
    independentes nesta etapa.

## Prioridade 3 — Backup e evoluções remotas

19. Backup, importação/exportação, sincronização entre aparelhos e resolução de
    conflitos. Sincronização não substitui importação.
20. Múltiplas bibliotecas públicas ou assináveis, distribuição, equipe,
    atualização remota e conflitos entre origens são possibilidade distante.
    Não orientam a arquitetura atual, que mantém uma Biblioteca principal e
    oficial.

## Prioridade 4 — Interface e plataforma

21. Tema escuro, AMOLED, preferências de visualização e configurações gerais.
22. iOS como evolução posterior; Android continua principal.

## Última etapa — IA

IA não será integrada no horizonte atual. Antes de decidir, avaliar hospedagem
própria. Usos possíveis: tags, tema/energia, estrutura, correção de cifras e
análise de repertório. Não inclui sugestão automática de repertório, tom ou
transições.

## Dependências principais

    Correção de cifra → reconhecimento estrutural → edição assistida → editor por blocos
    Tags/metadados → pesquisa/filtros → descoberta de repertório
    Versões/arranjos → versão e tom por ItemListaCulto → consulta de Listas
    Contexto da Lista → ministrante/data → descoberta e estatísticas derivadas
    Importação em lote → revisão/duplicidade → fontes externas futuras
    BPM → indicador luminoso
    Biblioteca principal → backup/sincronização → múltiplas bibliotecas futuras
