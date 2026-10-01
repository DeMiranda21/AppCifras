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
6. **Edição assistida básica:** primeira fatia entregue: no editor textual,
   marcar uma seleção válida como acorde e tratar um acorde entre colchetes
   como texto, sem exigir sintaxe ChordPro. Permanecem futuras: editar acorde e
   marcar linha ou bloco como seção. Evoluir de forma incremental: criação,
   troca de tipo, movimento, duplicação e exclusão de seções não precisam entrar
   juntas.
7. **Editor por blocos:** criar, excluir, duplicar, arrastar e ocultar blocos
   para reorganização rápida, após a edição assistida estabelecer sua camada de
   transformação para ChordPro. Não criar entidade Arranjo/Versão nesta fase.
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
