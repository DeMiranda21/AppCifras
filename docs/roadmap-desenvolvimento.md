# Roadmap de Desenvolvimento — AppCifras

Este é o documento de referência para funcionalidades futuras, prioridades e
dependências. Decisões aprovadas pertencem a `decisoes-mvp.md`; a visão
funcional consolidada, a `especificacao-funcional.md`. As prioridades indicam
ordem de trabalho, sem representar cronograma.

## Critério atual de prioridade

O objetivo imediato é alcançar a menor versão confiável para produção pessoal
em ensaios, cultos e manutenção cotidiana. O cenário de sucesso é:

1. atualizar a Biblioteca Oficial pública a partir de uma geração publicada;
2. encontrar a música na Biblioteca;
3. abrir a VersaoMusica correta e transpor quando necessário;
4. preparar e navegar uma Lista de Culto;
5. usar o repertório em ensaio ou culto;
6. continuar consultando os dados já locais sem acesso à origem.

Depois dessa jornada funcionar de ponta a ponta, o uso real orientará o rework
do editor, as conveniências de Lista e as otimizações seguintes. Antes disso,
somente defeitos de correção, perda de dados, travamentos ou lentidão perceptível
no caminho principal interrompem a sequência.

## Base já entregue

- Biblioteca offline, cadastro por colagem/importação, edição, exclusão
  confirmada e pesquisa por título, artista e letra.
- Entrada manual contextual R1/R2, com conversão conservadora, revisão por
  ocorrência e ChordPro interno.
- ChordPro canônico, parser conservador e preservação de conteúdo desconhecido.
- Reconhecimento estrutural e editor por blocos derivados do ChordPro, com
  transformações básicas e modo textual avançado.
- Visualização responsiva, transposição temporária, último tom por versão, zoom
  com reflow, swipe entre itens da Lista e tela mantida ativa durante a leitura.
- Listas de Culto: criar, renomear, excluir, adicionar, remover, reordenar,
  escolher a versão concreta do item e navegar entre itens.
- Versões/arranjos até a Fatia C2: fundação, criação, seleção, ciclo de vida e
  edição explícita da VersaoMusica aberta.
- Energia, tags, pesquisa combinada e arquivos ChordPro com SQLite local para
  índices, relações e preferências.
- Biblioteca Oficial pública por manifesto e arquivos `.cho` via HTTPS, com
  atualização incremental, relatório, uso offline e migração validada no A72.

## Prioridade 0 — Estabilizar a jornada já entregue

Concluir somente correções concretas encontradas na validação atual da entrada
e da visualização. Não ampliar o editor nem iniciar refinamentos gerais antes da
sincronização. Regressões de integridade, leitura, navegação ou desempenho no
caminho principal continuam bloqueadoras.

## Prioridade 1 concluída — Biblioteca Oficial por manifesto e HTTPS

O contrato do MVP está fechado em `decisoes-mvp.md`. A fundação S1–S5 de
validação, identidade, persistência, aplicação e relatório foi migrada para um
manifesto público versionado e arquivos `.cho` por HTTPS, sem login e sem
escolha de pasta remota. A validação no A72 foi concluída e a integração SAF
foi removida do runtime e da interface.

### M1 — Contrato do manifesto e publicador local

- consolidar o contrato em `manifesto-biblioteca-oficial.md`;
- definir modelos Dart-pure, schema versionado, serialização e validação do
  manifesto;
- reutilizar S1 para validar UTF-8, ChordPro schema 2, identidades, grupos e
  principal única antes da publicação;
- copiar os bytes sem normalização para paths estáveis derivados de
  IdVersaoMusica;
- gerar em diretório temporário, verificar SHA-256/tamanho e somente então
  finalizar a geração local;
- produzir relatório sem alterar o diretório privado de entrada do curador.

### Fatias M1–M6 concluídas

1. contrato do manifesto e publicador local;
2. hospedagem HTTPS e geração real publicada;
3. cliente do manifesto e download verificado;
4. aplicação incremental e ausência por geração completa;
5. UX “Atualizar biblioteca” validada no A72;
6. remoção da configuração, canais Android e implementação SAF sem uso.

## Histórico da fundação — S1–S5

### S1 — Schema 2 e validação pura

- reconhecer e preservar as diretivas `appcifras_version_id`,
  `appcifras_version_name` e `appcifras_primary`;
- validar schema 2, metadados obrigatórios e relação um arquivo/uma versão;
- montar inventário em memória, detectar duplicidades e inconsistências por
  grupo de Música;
- calcular SHA-256 dos bytes externos;
- cobrir regras em testes Dart sem Android, banco ou interface.

### S2 — Origem sincronizada e persistência segura

- persistir a configuração única da pasta e o vínculo mínimo por versão;
- distinguir versão sincronizada presente, sincronizada ausente e local;
- incorporar Música e versões preservando IDs, principal inicial e referências;
- suportar atualização permitida, reaparecimento e marcação de ausência;
- reutilizar transações e `.tmp`/`.bak`, incluindo recuperação após interrupção;
- bloquear edição direta de origem presente e criar versão local pelo fluxo já
  existente.

### S3 — Acesso à pasta pelo Android SAF

- selecionar uma document tree pelo seletor do sistema;
- persistir autorização e URI `content://`;
- enumerar somente arquivos `.cho` filhos diretos e ler seus bytes;
- tratar autorização revogada, pasta removida e provedor indisponível como
  falha de acesso, nunca como remoção de conteúdo.

### S4 — Orquestração idempotente

- executar enumeração, leitura, validação, inventário e agrupamento antes da
  aplicação;
- aplicar somente grupos válidos e continuar após erro isolado;
- respeitar a política de alternativas usadas em Lista;
- marcar ausências somente depois de enumeração completa;
- garantir que repetição sem mudanças não altere a Biblioteca.

### S5 — Relatório mínimo e validação no A72

- apresentar totais de adicionadas, atualizadas, inalteradas, origens ausentes
  e ignoradas com erro;
- mostrar arquivo e motivo breve, sem dashboard;
- validar primeira carga, atualização, renomeação, ausência, reaparecimento,
  duplicidades, interrupção, origem indisponível e uso offline;
- executar a jornada completa de Biblioteca, pesquisa, música, transposição,
  Lista, versão, ensaio e culto no Samsung Galaxy A72.

## Prioridade 2 — Iniciar uso real e fechar bloqueios observados

Com a sincronização validada, iniciar uso pessoal real. Corrigir primeiro apenas
problemas que impeçam ou tornem insegura a jornada principal. O tom snapshot por
ItemListaCulto é o candidato funcional mais próximo, mas só passa à frente se o
uso mostrar que perder o tom da ocasião prejudica ensaios ou cultos; até lá, o
último tom por versão mantém o fluxo utilizável.

## Depois do uso real

1. **Rework do editor comum:** reavaliar quais operações realmente causam
   atrito. Adaptar reconhecimento estrutural, blocos e transformações puras para
   ações explícitas sobre acordes, texto, linhas e seções. ChordPro textual
   continua modo avançado e fallback.
2. **Diagnóstico contextual da transposição:** reutilizar o modelo de ocorrência
   da entrada para localizar, em linguagem simples, cada trecho que bloqueia a
   transposição, quando essa limitação se mostrar frequente.
3. **Listas e versões:** ordenar pela evidência de uso a escolha de versão na
   inclusão inicial (C3), o tom da ocasião por item, data e ministrante opcional
   e consultas de Listas anteriores. A Lista continua sendo a memória
   operacional, sem entidade autônoma de histórico.
4. **Desempenho:** corrigir gargalos medidos ou regressões perceptíveis. Não abrir
   uma rodada de micro-otimizações sem evidência no A72 ou em bibliotecas reais.

## Classificação das lacunas conhecidas

| Tema | Estado para a produção pessoal | Próximo critério |
| --- | --- | --- |
| Biblioteca Oficial por HTTPS | Entregue e validada | Observar o uso real e corrigir apenas regressões |
| Diagnóstico contextual da transposição | Desejável, não bloqueador | Frequência de cifras que impedem transpor |
| Rework amplo do editor | Desejável, não bloqueador | Atritos observados no uso real |
| C3: escolher versão ao incluir em Lista | Conveniência adiável | Custo real da troca depois da inclusão |
| Tom por ItemListaCulto | Primeiro candidato pós-sincronização | Perda recorrente do tom da ocasião |
| Data e ministrante da Lista | Adiável | Necessidade de consulta por contexto |
| Histórico e estatísticas | Adiáveis | Derivar das Listas quando houver volume real |
| Otimizações gerais | Adiáveis | Perfil ou regressão perceptível no A72 |
| Importação em lote | Adiável e separada da sincronização | Necessidade de fontes não curadas |
| Múltiplas bibliotecas | Distante | Não orienta a arquitetura atual |

## Evoluções locais adiadas

- Refinamentos adicionais de reconhecimento estrutural e edição avançada de
  acordes dentro dos blocos.
- Tema, momento, BPM, compasso, duração, dificuldade, ministério, compositor,
  álbum, idioma e instrumentação.
- Descoberta por classificação, tonalidade, Listas anteriores e tempo desde a
  última aparição; favoritos, recentes, ordenações e coleções.
- Seleção direta de tom e apresentação por graus na interface.
- Estatísticas derivadas das Listas.
- Indicador percentual de zoom, animação do swipe, temas, preferências visuais
  e iOS.

## Importação, backup e distribuição futura

- **Importação em lote:** primeiro múltiplos `.cho`; depois `.txt` com conversão
  conservadora, revisão de ambiguidades e resultado isolado por arquivo. É um
  fluxo diferente da sincronização curada.
- **Backup e sincronização entre aparelhos:** definir exportação, conflitos e
  continuidade entre dispositivos depois de validar a Biblioteca curada local.
- **Múltiplas bibliotecas públicas ou assináveis:** distribuição, equipe,
  atualização remota e conflitos entre origens são possibilidades distantes e
  não orientam o desenho da primeira sincronização.

## Última etapa — IA

IA não será integrada no horizonte atual. Antes de decidir, avaliar hospedagem
própria. Usos possíveis: tags, tema/energia, estrutura, correção de cifras e
análise de repertório. Não inclui sugestão automática de repertório, tom ou
transições.

## Dependências principais

    S1–S5 → manifesto + publicador → hospedagem e cliente HTTPS
    Cliente HTTPS + aplicação incremental → nova UX → validação A72 → remoção SAF
    Uso real do editor → recorte do rework e diagnóstico da transposição
    Versões/arranjos entregues → C3 e tom por item, se o uso justificar
    Contexto da Lista → consultas e estatísticas derivadas
    Biblioteca Oficial validada → backup e fontes remotas futuras
