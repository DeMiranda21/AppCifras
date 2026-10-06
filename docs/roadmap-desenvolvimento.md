# Roadmap de Desenvolvimento — AppCifras

Este é o documento de referência para funcionalidades futuras, prioridades e
dependências. Decisões aprovadas pertencem a decisoes-mvp.md; visão funcional
consolidada, a especificacao-funcional.md.

## Base já entregue

- Biblioteca offline, cadastro por colagem/importação, edição, exclusão
  confirmada e pesquisa por título e artista.
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

## Prioridade 1 — Estrutura, classificação e histórico

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
   Não criar entidade Arranjo/Versão
   nesta fase.
8. **Tags, classificação e metadados:** energia (muito calma, calma,
   moderada, animada e muito animada), tema, momento/tipo (celebração,
   adoração, abertura, ceia, oferta e encerramento) e tags livres; BPM,
   compasso, duração, dificuldade, ministério, compositor, álbum, idioma,
   instrumentação e observações, de forma gradual.
9. **Pesquisa ampliada e filtros:** letra, tags, tema, categoria e ministério,
   conforme os metadados disponíveis.
10. **Histórico:** execução, data, lista/culto, tom, frequência, ministrante,
   histórico de tons por Música + Ministrante e histórico de cultos/listas.

## Prioridade 2 — Apoio ao ministrante e evoluções locais

11. **Descoberta e uso recente:** repertório por classificação, BPM,
    tonalidade, ministrante, histórico e tempo desde última execução;
    recorrência e prevenção de repetição.
12. **BPM e compasso:** BPM por música, indicador luminoso discreto e
    compasso. Sem tap tempo ou metrônomo sonoro.
13. **Listas de Culto:** duplicar, data opcional, responsável, status derivado
    da data (futura, hoje ou passada/executada) e histórico após definir como
    confirmar execução real.
14. **Biblioteca:** favoritos, recentes, ordenações e coleções personalizadas
    em baixa prioridade.
15. **Seleção direta de tom** e **graus na interface** (cifras, graus ou
    ambos; romano ou numérico).
16. **Importação:** colagem melhorada, lote, fontes externas/APIs e detecção
    explícita de metadados e estrutura. Sem importação automática de PDF.

## Prioridade 3 — Compartilhamento, backup e estatísticas

17. Compartilhamento de músicas/Listas, equipe, versão oficial, distribuição,
    atualização e conflitos; sem antecipar entidade Arranjo/Versão.
18. Backup, importação/exportação, sincronização entre aparelhos e resolução de
    conflitos.
19. Estatísticas derivadas do histórico real: execuções, frequência, tons,
    ministrantes, cultos e classificações.

## Prioridade 4 — Interface e plataforma

20. Tema escuro, AMOLED, preferências de visualização e configurações gerais.
21. iOS como evolução posterior; Android continua principal.

## Última etapa — IA

IA não será integrada no horizonte atual. Antes de decidir, avaliar hospedagem
própria. Usos possíveis: tags, tema/energia, estrutura, correção de cifras e
análise de repertório. Não inclui sugestão automática de repertório, tom ou
transições.

## Dependências principais

    Correção de cifra → reconhecimento estrutural → edição assistida → editor por blocos
    Tags/metadados → pesquisa/filtros → descoberta de repertório
    Histórico → ministrantes/histórico de tons → descoberta e estatísticas
    BPM → indicador luminoso
    Listas + histórico → registro de culto → estatísticas
    Compartilhamento → usuários/equipe → sincronização colaborativa
