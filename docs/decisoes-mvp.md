# Decisões do MVP — AppCifras

**Status:** decisões vinculantes da versão local. Este documento resolve
divergências de escopo; modelo-dominio.md define conceitos permanentes.

## Produto, plataforma e dados locais

- Android é a plataforma inicial, com mínimo API 23; Samsung Galaxy A72 é a
  referência de validação.
- O produto é local e offline, com uma única Biblioteca principal e oficial,
  alimentada pelo AppCifras e pela atualização de uma Biblioteca Oficial
  pública. Nuvem genérica, backup entre aparelhos,
  compartilhamento, colaboração, múltiplas bibliotecas públicas ou assináveis
  e IA não fazem parte da versão atual.
- Cada versão gerenciada usa arquivo UTF-8 .cho nomeado por IdVersaoMusica.
  SQLite/Drift mantém índice e estado local derivado, não a cifra completa.
- Arquivo da música é fonte canônica de conteúdo e metadados. Índices, Listas
  de Culto e preferências não pertencem ao ChordPro.
- Energia (Calma, Moderada ou Animada) é opcional e Tags são livres, opcionais
  e múltiplas. Ambas são classificações locais no SQLite, não diretivas do
  ChordPro; Tema e Momento não fazem parte desta etapa.
- Importação introduz conteúdo novo na Biblioteca; sincronização mantém
  conteúdo conhecido alinhado à única Biblioteca Oficial. São fluxos distintos.
  Importação genérica e em lote continuam evoluções futuras.

## Distribuição da Biblioteca Oficial

- Existe uma única Biblioteca Oficial pública, preparada pelo curador. O
  usuário não faz login, não fornece conta de serviço e não escolhe pasta
  remota; apenas solicita a atualização.
- O protocolo alvo é um manifesto público versionado e arquivos `.cho`
  acessíveis por HTTPS. Google Drive pode ser área de trabalho do curador, mas
  Drive e SAF não fazem parte do protocolo consumido pelo aplicativo.
- Cada geração válida é preparada integralmente antes de ficar disponível. O
  manifesto declara schema, geração, data de publicação e, para cada versão,
  IdMusica, IdVersaoMusica, SHA-256, tamanho e path relativo seguro. O contrato
  exato está em `manifesto-biblioteca-oficial.md`.
- Os arquivos publicados preservam exatamente os bytes ChordPro validados; o
  manifesto não duplica título, artista, tom ou nome da versão. O ChordPro
  schema 2 continua sendo a fonte desses metadados.
- Depois de baixado e incorporado, o conteúdo oficial permanece local e
  utilizável offline. Versões exclusivamente locais coexistem na mesma
  Biblioteca visual.
- O aplicativo consome a Biblioteca Oficial exclusivamente por HTTPS. A antiga
  implementação Android SAF foi removida depois da validação da migração; não
  existe seleção de pasta nem configuração de provedor no produto. A tabela
  física legada pode permanecer no schema local para abrir bancos existentes,
  sem caso de uso ou acesso no runtime.

## Contrato musical da sincronização oficial

- A publicação é uma única fonte editorial controlada de arquivos `.cho`
  revisados.
  O MVP não cria abstração para múltiplas fontes, múltiplas bibliotecas, nuvem,
  colaboração ou envio de alterações locais à publicação oficial.
- Cada arquivo representa exatamente uma VersaoMusica concreta. Arquivos com o
  mesmo IdMusica podem representar versões diferentes.
- Todo arquivo sincronizável usa `{appcifras_schema:2}` e declara exatamente um
  `{appcifras_id:<IdMusica>}`, um
  `{appcifras_version_id:<IdVersaoMusica>}` e um
  `{appcifras_version_name:<nome>}`. Somente a versão que deve iniciar como
  principal de uma Música ainda inexistente declara
  `{appcifras_primary:true}`.
- `appcifras_id` identifica a Musica e `appcifras_version_id` identifica a
  VersaoMusica. Título, nome da versão, nome de arquivo e caminho não são
  identidade. Arquivos locais anteriores ao schema 2 não precisam ser migrados
  imediatamente apenas por causa da sincronização.
- Para uma Música nova, o grupo válido da fonte contém exatamente uma versão
  marcada como principal. Essa marca define a principal somente na primeira
  incorporação. Depois disso, a principal efetiva pertence ao estado local;
  mudanças posteriores da marca externa não a alteram silenciosamente e podem
  aparecer no relatório.
- VersaoMusica com origem sincronizada presente é somente leitura no fluxo
  comum. Para alterar seu conteúdo, o usuário cria uma versão local com novo
  IdVersaoMusica. A versão sincronizada permanece intacta; não há merge,
  desvinculação automática nem sobrescrita local.
- Versão criada no aplicativo permanece local, segue as regras normais de
  edição e principal e não é enviada à publicação oficial. Colisão entre seu
  IdVersaoMusica e um arquivo externo é erro, sem adoção automática pela
  sincronização.
- Mesmo IdMusica e IdVersaoMusica representam a mesma versão apesar de mudança
  de nome ou caminho do arquivo. Uma principal sincronizada pode atualizar o
  mesmo ID. Uma alternativa sincronizada pode fazê-lo enquanto nunca tiver sido
  usada em Lista. Se já estiver referenciada, a atualização musical é rejeitada
  e o relatório orienta publicar novo arquivo com novo IdVersaoMusica.
- Se um arquivo desaparecer após uma enumeração completa, a versão, o último
  tom e as referências de Lista são preservados e sua origem é marcada como
  ausente. Não há exclusão nem arquivamento automático, inclusive da principal.
  Se reaparecer com os mesmos IDs, volta a ser presente e continua sendo a
  mesma versão.
- O publicador local considera somente arquivos `.cho` filhos diretos da pasta
  curada de entrada e produz paths estáveis próprios para a saída.
- Mesmo IdVersaoMusica em dois arquivos faz ambos serem rejeitados. Se o mesmo
  IdVersaoMusica estiver ligado a IdMusica diferentes, todo o conjunto é
  rejeitado. Mesmo IdMusica com IdVersaoMusica diferentes é permitido. Arquivo
  sem ID de versão é rejeitado. Título ou artista divergentes no grupo da mesma
  Música rejeitam o grupo. Erro de arquivo ou grupo não impede Músicas
  independentes.
- A origem por versão guarda IdVersaoMusica, localizador publicado atual, hash
  SHA-256 dos bytes externos e estado presente ou ausente. IdMusica é derivado
  da VersaoMusica. Não se guardam histórico de hashes, merge base, timestamps
  por arquivo, várias fontes ou prioridade entre fontes.
- SHA-256 dos bytes externos é a verdade para detectar alteração. Timestamp e
  tamanho não decidem atualização. Uma sincronização sem mudanças é idempotente.
- O processamento consome uma geração completa, lê e valida os `.cho`, monta o
  inventário, detecta inconsistências, agrupa por Música e aplica
  somente grupos válidos. Falha isolada não interrompe outros grupos. Se a
  enumeração falhar ou estiver incompleta, arquivos não vistos não são tratados
  como removidos.
- A persistência é segura por Música e reutiliza transações e gravação
  `.tmp`/`.bak`. A Biblioteca deve permanecer utilizável depois de falha ou
  interrupção, sem estado parcial observável.
- **Decisão histórica superada:** a seleção Android por Storage Access Framework
  serviu à fundação S1–S5, mas foi removida do runtime após a migração M1–M6.
  A Biblioteca Oficial por manifesto e arquivos HTTPS é o único mecanismo
  vigente. Estruturas físicas legadas do banco podem permanecer somente para
  compatibilidade com bancos existentes, sem caso de uso, acesso no runtime ou
  orientação futura para restaurar ou preservar o fluxo SAF executável.
- O resultado informa quantidades adicionadas, atualizadas, inalteradas, com
  origem ausente e ignoradas com erro. Cada erro mostra arquivo e motivo breve;
  não há dashboard de sincronização no MVP.

## Música, ChordPro e edição

- Música válida exige exatamente uma diretiva válida de title, artist e key.
  Ausência, duplicidade ou valor inválido preservam o documento, mas bloqueiam
  criar Música.
- ChordPro é canônico e preservado sem reescrita; interpretação para leitura,
  transposição e graus é derivada. A futura edição assistida traduz ações
  semânticas do usuário em alterações controladas do documento, sem criar um
  segundo formato persistido concorrente.
- No uso comum, o usuário edita uma música e o AppCifras mantém o ChordPro por
  trás. A interface fala em letra, acordes, seções, problemas e ações musicais;
  não exige conhecimento nem edição da sintaxe. O ChordPro textual permanece
  disponível como modo avançado e fallback, com ponto de acesso ainda a definir.
- A primeira fatia do rework cobre somente entrada manual: colar texto comum,
  analisar, aplicar conversões automáticas seguras, gerar ChordPro interno,
  identificar pontos de decisão, revisar cada ocorrência em sequência,
  reanalisar depois de cada resolução e salvar. Título, artista e tom original
  continuam campos próprios e não entram na sequência de problemas da cifra.
- A revisão apresenta um problema por vez, com posição `Problema X de N`,
  contexto, motivo e ações permitidas. Anterior e próximo podem existir, mas a
  ação principal avança automaticamente. Cada ação vale somente para a
  ocorrência concreta apresentada; depois dela, os diagnósticos anteriores são
  descartados e o rascunho inteiro é analisado novamente.
- A primeira fatia oferece somente `É acorde`, `É texto` e `Corrigir acorde`.
  A correção recebe texto curto e só é aplicada quando `ParserAcorde` o valida.
  Inserção semântica, seletor avançado e editor visual completo de acordes ficam
  fora dessa fatia.
- A análise distingue conteúdo reconhecido com segurança, ambíguo, inválido ou
  problemático, e desconhecido porém preservável. Ambiguidade é tratada de modo
  conservador e com baixa taxa de falso positivo; na dúvida, o trecho permanece
  texto. Conteúdo desconhecido ou acorde não transponível pode limitar recursos
  e gerar aviso, mas não bloqueia salvar quando pode ser preservado.
- Só condições realmente incompatíveis bloqueiam salvar, como metadado
  obrigatório inválido ou impossibilidade de produzir ChordPro minimamente
  válido. Limitações de transposição e conteúdo desconhecido preservável não
  são erros fatais.
- `ProblemaDeCifra` é uma projeção transitória da revisão. Ele registra tipo,
  faixa exata no rascunho, texto encontrado, contexto, motivo, ações permitidas
  e revisão do rascunho. A ação valida que a faixa ainda contém o texto esperado
  antes de transformar. Ocorrências duplicadas permanecem distinguíveis; não se
  usa identidade de `TextSelection` nem busca por texto com `indexOf`.
- Faixas laterais ao rascunho são a estratégia inicial. Esta etapa não adiciona
  posições a toda a AST, não persiste diagnósticos e não cria um segundo modelo
  semântico concorrente com ChordPro.
- O rework reaproveita Parser ChordPro, `ParserAcorde`,
  `ConversorCifraTextual`, `RascunhoDocumentoChordPro`, persistência e
  salvamento de versões atuais, reconhecimento estrutural, editor e operações
  por blocos, transformações puras existentes e o editor ChordPro avançado.
  Esses componentes podem ser adaptados, mas não são substituídos sem uma
  necessidade concreta descoberta na implementação.
- A entrada manual contextual já permite a jornada mínima de cadastro. O
  rework amplo do editor e o diagnóstico contextual da transposição continuam
  aprovados, mas não bloqueiam a primeira versão utilizável em produção pessoal;
  seu recorte será reavaliado após uso real em ensaios e cultos.
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
  linhas vazias e conteúdo malformado permanecem preservados ao abrir,
  importar ou editar conteúdo fornecido pelo usuário. Essa preservação
  conservadora não autoriza tablaturas na Biblioteca Oficial: a curadoria as
  remove definitivamente dos arquivos que alimentam a publicação, preservando
  trechos instrumentais úteis que não sejam tablaturas.
- Edição preserva IdMusica e altera explicitamente só diretivas funcionais.
  appcifras_schema e appcifras_id são internos, ocultos do editor e
  reaplicados/validados pela aplicação.
- `{appcifras_block_break}` é diretiva interna sem semântica musical, criada
  somente pela divisão explícita de bloco para persistir fronteiras entre
  trechos livres derivados. Ela não aparece na leitura nem no editor local.
- Reanálise preserva ChordPro e rótulos existentes; converte somente pares
  inequívocos de linha textual de acordes e letra ainda não marcados.
- Seleção automática, `RenderEditable` e menu contextual nativo deixam de ser a
  fundação das operações musicais comuns. Podem continuar existindo no modo
  textual avançado, sem orientar a entrada manual nem o futuro editor comum.
- Musica é a identidade de catálogo com título e artista, enquanto
  VersaoMusica é o arranjo concreto, com identidade, ChordPro e tom original
  próprios. A cifra única anterior migra para a versão principal; arranjos não
  duplicam a Música no catálogo. `title` e `artist` em cada ChordPro espelham
  o catálogo; `key` pertence à versão.
- Ao alterar musicalmente a versão principal, o usuário escolhe explicitamente
  entre atualizar essa versão ou salvar como nova versão. Atualizar preserva o
  IdVersaoMusica e a preferência de último tom; itens de Listas que a referenciam
  passam a exibir o conteúdo atualizado. Salvar como nova mantém a origem intacta,
  gera novo ID e não herda o último tom.
- Cada Música tem exatamente uma VersaoMusica principal ativa. A principal não
  pode ser arquivada diretamente; trocá-la apenas move essa marca para outra
  versão ativa, sem copiar conteúdo, excluir a anterior ou alterar identidades.
- O nome da versão permanece editável e não define sua identidade. Uma versão
  alternativa deixa de aceitar sobrescrita de conteúdo musical após a primeira
  referência por ItemListaCulto; sua alteração musical cria nova versão. A
  principal pode ser atualizada mesmo quando usada em Listas, mediante escolha
  explícita do usuário, pois representa o arranjo corrente padrão da Música.
- Versão usada por Lista não pode ser excluída fisicamente; ela poderá ser
  arquivada, preservando conteúdo e referências antigas e ficando fora das
  novas seleções usuais. Versão nunca usada poderá ser excluída.
- `{appcifras_id}` continua identificando IdMusica. Arquivos locais legados
  mantêm IdVersaoMusica pela persistência e pelo arquivo físico; arquivos
  sincronizáveis em schema 2 também o declaram por
  `{appcifras_version_id:...}`.
- A Biblioteca mantém uma única entrada por Música e abre a versão principal.
  Fora de uma Lista, a leitura permite selecionar somente versões ativas, sem
  trocar a principal. A visualização aberta por Lista usa a versão concreta do
  ItemListaCulto. No detalhe da Lista, o usuário pode trocar esse item para
  outra versão ativa da mesma Música; a operação preserva item, Música e posição.
- Criar versão duplica integralmente o ChordPro da versão aberta, preserva
  IdMusica e `{appcifras_id}`, gera IdVersaoMusica novo e cria versão ativa não
  principal. O nome recebe trim e não pode ser vazio; unicidade de nome não é
  exigida nesta etapa. A nova versão não herda último tom e inicia no próprio
  tom original.

## Parser e acordes

- O parser reconhece fundamentais A–G, acidentes simples, maior, menor,
  quinta, sexta, sétimas, extensões 9/11/13, adições 2/add9/add11,
  sus2/sus4, diminuto, aumentado, meio-diminuto, alterações b5/#5/b9/#9 e
  inversões.
- A notação latina de fundamentais (`DÓ`, `RÉ`, `MI`, `FÁ`, `SOL`, `LÁ`, `SI`)
  não entra nesta etapa; o contrato continua baseado em A–G.
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
- Último tom é preferência local por VersaoMusica, salva automaticamente.
  Voltar ao original remove a preferência; editar o tom original daquela
  versão ou excluir a música a invalida. Na migração, a preferência antiga é
  associada à versão principal criada para a Música.
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

## Lista de Culto v1 e evolução aprovada

- Atualmente, Lista guarda IdListaCulto e nome. Item guarda IdItemListaCulto,
  IdMusica, IdVersaoMusica e posição; não guarda ChordPro nem tom próprio.
- Domínio aceita ocorrências repetidas; UI v1 impede nova inclusão de música já
  presente, sem alterar dados preexistentes.
- Excluir item ou Lista não exclui Música. A exclusão física de Música é
  bloqueada se alguma de suas versões for referenciada por ItemListaCulto;
  arquivamento de Música permanece evolução futura.
- Remoção de item exige confirmação. Visualização aberta pela Lista navega na
  ordem capturada sem criar rota por música.
- Uma Lista salva representa informação histórica válida e servirá como memória
  operacional da ministração. Não haverá entidade separada de Histórico ou
  Execução, distinção inicial entre Lista planejada e executada, marcação de
  execução ou confirmação música a música. A futura tela Histórico consultará
  dados derivados das Listas e não será fonte independente.
- A evolução aprovada dará à Lista DataCulto e Ministrante opcionais, aplicados
  à Lista inteira. Ministrante será cadastro local simples e selecionável, sem
  texto livre por Lista, conta, autenticação, permissão ou sincronização. Não
  haverá ministrante por música, múltiplos ministrantes ou override por item.
- DataCulto e Ministrante são opcionais. Toda Lista nova recebe `criadaEm`
  automaticamente, como instante técnico e imutável de criação no aplicativo.
  Ele não substitui DataCulto, não representa a data do culto e não precisa ser
  exibido normalmente.
- Listas legadas mantêm DataCulto, Ministrante e `criadaEm` nulos e continuam
  válidas e utilizáveis. Seus itens mantêm tom histórico nulo. A migração não
  inventará nenhum desses valores nem usará preferência atual ou tom original
  como fato histórico. A apresentação usará “Data não informada”, “Ministrante
  não informado” e “Tom não registrado”, ou textos equivalentes.
- Ministrante possui identidade estável própria, independente do nome. Pode ser
  renomeado sem romper referências. Se estiver associado a Listas históricas,
  não será excluído fisicamente: poderá ser arquivado ou inativado, ficando fora
  das novas seleções usuais e preservando as referências existentes. Não haverá
  snapshot histórico do nome; a Lista exibirá o nome atual cadastrado. O ciclo
  de vida da H1 usa arquivamento e restauração, sem exclusão física.
- Nomes de Ministrantes não são únicos. Dois IDs podem possuir o mesmo nome e
  não haverá restrição `UNIQUE(nome)`. Ao cadastrar nome equivalente ao de um
  Ministrante ativo, a futura interface alertará sobre possível duplicação e
  exigirá confirmação explícita, mas permitirá concluir. A comparação do alerta
  ignorará diferenças triviais de espaços e caixa e reutilizará a normalização
  vigente quando apropriado.
- ItemListaCulto registrará o tom da ocasião. Ao abrir pela Lista, esse tom é a
  fonte de verdade; alterá-lo nesse contexto atualiza somente o Item. O valor é
  snapshot histórico e não muda quando a preferência de último tom, a versão
  principal ou outra Lista for alterada. O Item referencia a versão
  concreta e não armazena snapshot completo de ChordPro. A Lista preserva a
  memória operacional de repertório e da versão escolhida; não congela o arranjo.
  Por isso, atualizar a principal também atualiza sua leitura em Listas antigas.
- Ao incluir uma música em Lista com Ministrante definido, o tom inicial segue:
  último tom desse Ministrante na mesma Música e VersaoMusica; depois, último
  tom geral da VersaoMusica; por fim, tom original. Depois de salvo, o tom do
  Item não acompanha mudanças dessas preferências.
- O último tom do Ministrante considera somente itens com tom não nulo e Listas
  com DataCulto conhecida. Ordena por DataCulto decrescente e, em caso de
  igualdade, exclusivamente por `criadaEm` decrescente. ID, UUID, `rowid`,
  posição e outros identificadores não são critérios temporais. Lista sem
  DataCulto não participa dessa determinação, ainda que possa ser ordenada com
  outras Listas sem data por `criadaEm` para apresentação.
- Alterar o Ministrante de uma Lista preserva os tons existentes; apenas novas
  músicas usam o novo Ministrante no fallback. Alterar o tom dentro da Lista
  atualiza somente o ItemListaCulto e não atualiza a preferência global da
  VersaoMusica. Item legado nulo pode usar preferência global e depois tom
  original apenas durante a execução; somente alteração explícita persiste tom.
- Trocar a VersaoMusica de um ItemListaCulto preserva o tom já definido, sem
  recalcular nem consultar outro histórico. Se o tom era nulo, permanece nulo e
  o fallback temporário passa a considerar a nova versão.
- Consultas históricas considerarão o Ministrante e permitirão recuperar, por
  Música e VersaoMusica, última utilização, último tom e ocorrências anteriores.
  Energia e tempo desde a última utilização apoiarão filtros de repertório;
  nunca usada, mais de 30 dias e mais de 60 dias são evoluções previstas. Não
  está aprovado algoritmo automático de montagem ou sugestão de repertório.
