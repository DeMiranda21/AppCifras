# Decisões do MVP — AppCifras

**Status:** decisões vinculantes da versão local. Este documento resolve
divergências de escopo; modelo-dominio.md define conceitos permanentes.

## Produto, plataforma e dados locais

- Android é a plataforma inicial, com mínimo API 23; Samsung Galaxy A72 é a
  referência de validação.
- O produto é local e offline. Nuvem, backup entre aparelhos,
  compartilhamento, colaboração e IA não fazem parte da versão atual.
- Cada música gerenciada usa arquivo UTF-8 .cho nomeado por IdMusica.
  SQLite/Drift mantém índice e estado local derivado, não a cifra completa.
- Arquivo da música é fonte canônica de conteúdo e metadados. Índices, Listas
  de Culto e preferências não pertencem ao ChordPro.

## Música, ChordPro e edição

- Música válida exige exatamente uma diretiva válida de title, artist e key.
  Ausência, duplicidade ou valor inválido preservam o documento, mas bloqueiam
  criar Música.
- ChordPro é canônico e preservado sem reescrita; interpretação para leitura,
  transposição e graus é derivada. A futura edição assistida traduz ações
  semânticas do usuário em alterações controladas do documento, sem criar um
  segundo formato persistido concorrente.
- Quando a futura edição semântica escrever uma seção, usará ambiente ChordPro
  de nome longo, par explícito `start_of_*`/`end_of_*` e `label="..."`.
  O ambiente define o tipo (`verse`, `chorus`, `bridge`, `intro`,
  `pre_chorus`, `instrumental`, `solo` ou `final`); `section` representa tipo
  genérico. Leitura aceita aliases e rótulos legados, mas não os reescreve ao
  abrir ou importar documento externo.
- Entrada textual usa análise e revisão conservadoras. ChordPro completo usa
  as próprias diretivas: sem cabeçalhos duplicados, metadados paralelos ou
  deduplicação silenciosa. Na dúvida entre converter e preservar, preserva.
  Rótulos inequívocos de seção são preservados como texto e nunca convertidos
  automaticamente em acordes. No ChordPro, `[]` delimita cifras; no fluxo de
  entrada textual, rótulos inequívocos entre colchetes são reconhecidos antes
  da conversão. Fora desses casos, o conteúdo entre colchetes é tratado como
  cifra e, se não for suportado, permanece não interpretável.
- Cifras desconhecidas, diretivas desconhecidas, comentários, tablaturas,
  linhas vazias e conteúdo malformado permanecem preservados.
- Edição preserva IdMusica e altera explicitamente só diretivas funcionais.
  appcifras_schema e appcifras_id são internos, ocultos do editor e
  reaplicados/validados pela aplicação.
- `{appcifras_block_break}` é diretiva interna sem semântica musical, criada
  somente pela divisão explícita de bloco para persistir fronteiras entre
  trechos livres derivados. Ela não aparece na leitura nem no editor local.
- Reanálise preserva ChordPro e rótulos existentes; converte somente pares
  inequívocos de linha textual de acordes e letra ainda não marcados.

## Parser e acordes

- O parser reconhece fundamentais A–G, acidentes simples, maior, menor,
  quinta, sexta, sétimas, extensões 9/11/13, adições 2/add9/add11,
  sus2/sus4, diminuto, aumentado, meio-diminuto, alterações b5/#5/b9/#9 e
  inversões.
- C2 é segunda adicionada com terça preservada, não Csus2; C2(6) combina
  segunda adicionada e sexta. C5 não é maior nem menor.
- Parênteses só têm significado para componentes aprovados, inclusive formas
  equivalentes como C7(9), Cm7(9), C7M(9) e C7(13); barra representa somente
  inversão.
- Aliases 7M, M7 e Δ7 equivalem a maj7; ° a dim; + a aug; ø a m7(b5); 4 a
  sus4. 6/9, 69, alt, no3, #11, b13 e acidentes duplos ficam fora.
- Acorde não interpretável preserva seu texto; não há parsing parcial ou
  correção silenciosa.

## Transposição e graus

- Transposição é projeção de leitura: não altera ChordPro nem tomOriginal.
  O intervalo usa apenas key; não há inferência tonal.
- Com tom de destino conhecido, enarmonia segue tonalidade. Sem contexto,
  naturais prevalecem; com acidente, preserva-se a família original, ou
  sustenido para original natural.
- Último tom é preferência local por música, salva automaticamente. Voltar ao
  original remove a preferência; editar tom original ou excluir música a
  invalida.
- Acorde não interpretável bloqueia transposição integralmente; não há
  resultado parcial.
- Graus usam menor natural em tons menores. Só acordes inteiramente diatônicos
  são convertidos; inversões, não diatônicos e acordes de quinta permanecem
  cifras absolutas.

## Visualização

- A cifra cabe na largura útil, sem truncamento, ellipsis ou rolagem horizontal
  no modo normal. Reflow preserva acorde e trecho associado.
- Zoom deve recompor o layout e manter leitura vertical.
- Zoom é um estado temporário da rota de leitura: pinça altera a fonte entre
  75% e 180%, 100% é a escala padrão, há ação discreta de redefinição e não há
  persistência no MVP.
- A visualização de cifra mantém a tela ativa enquanto estiver aberta e libera
  esse comportamento ao sair da leitura.
- Acordes não interpretáveis permanecem visíveis com destaque discreto.
- Na visualização aberta por Lista de Culto, swipe horizontal navega entre os
  itens na ordem capturada; o indicador de posição permanece visível e o botão
  de voltar retorna diretamente à Lista.

## Lista de Culto v1

- Lista guarda IdListaCulto e nome. Item guarda IdItemListaCulto, IdMusica e
  posição; não guarda ChordPro nem tom próprio.
- Domínio aceita ocorrências repetidas; UI v1 impede nova inclusão de música já
  presente, sem alterar dados preexistentes.
- Excluir item ou Lista não exclui Música. Excluir Música remove itens de forma
  explícita, sem depender apenas de ON DELETE CASCADE.
- Remoção de item exige confirmação. Visualização aberta pela Lista navega na
  ordem capturada sem criar rota por música.
- A Lista usa último tom da Música ou tom original. Tom por item será conceito
  futuro separado.
