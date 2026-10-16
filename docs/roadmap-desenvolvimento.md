# Roadmap de Desenvolvimento — AppCifras

Este é o documento de referência para funcionalidades futuras, prioridades e
dependências. Decisões aprovadas pertencem a `decisoes-mvp.md`; a visão
funcional consolidada, a `especificacao-funcional.md`. As prioridades indicam
ordem de trabalho, sem representar cronograma.

## Critério atual de prioridade

O objetivo imediato é alcançar a menor versão confiável para produção pessoal
em ensaios, cultos e manutenção cotidiana. O cenário de sucesso é:

1. sincronizar uma pasta curada de arquivos `.cho`;
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

## Prioridade 0 — Estabilizar a jornada já entregue

Concluir somente correções concretas encontradas na validação atual da entrada
e da visualização. Não ampliar o editor nem iniciar refinamentos gerais antes da
sincronização. Regressões de integridade, leitura, navegação ou desempenho no
caminho principal continuam bloqueadoras.

## Prioridade 1 — Sincronização inicial com pasta curada

### 1. Fechar o contrato mínimo

Resolver as decisões abertas registradas em `anotacoes.md` que bloqueiam a
implementação: acesso à pasta no Android, identidade do conteúdo remoto,
correspondência com Musica e VersaoMusica, atualização, remoção e conflito com
edição local. As regras devem preservar IDs e referências de Listas. Não criar
um modelo genérico de fontes, múltiplas bibliotecas ou conflitos remotos.

### 2. Configurar e ler a origem

Permitir escolher, autorizar e substituir uma única pasta curada conforme o
contrato aprovado. Descobrir apenas arquivos `.cho` e não misturar esse fluxo
com importação manual, `.txt` ou revisão contextual.

### 3. Validar e reconciliar por arquivo

Aplicar validação técnica leve a cada `.cho`. Um arquivo inválido gera resultado
próprio e não impede os demais. Identificar arquivos novos, alterados e removidos
e aplicar as políticas aprovadas sem trocar identidades nem referências por
coincidência de título, caminho ou ordem de leitura.

### 4. Persistir com segurança e manter uso offline

Reutilizar casos de uso, repositórios e gravação segura `.tmp`/`.bak`. Ao fim da
operação, o conteúdo aceito deve estar disponível pela Biblioteca, pesquisa,
visualização, transposição, versões e Listas sem nova leitura da pasta. Repetir
uma sincronização sem mudanças não deve criar duplicatas nem alterar os dados
locais.

### 5. Validar a jornada completa

No Samsung Galaxy A72, validar primeira sincronização, atualização, remoção
conforme a política escolhida, arquivo inválido isolado, origem indisponível e
uso offline posterior. Em seguida, executar a jornada completa de Biblioteca,
pesquisa, música, transposição, Lista, versão, ensaio e culto.

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
| Sincronização da pasta curada | Bloqueador imediato | Fechar contrato mínimo e implementar |
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

    Decisões mínimas de identidade e remoção → sincronização da pasta curada
    Pasta acessível + validação isolada → reconciliação → persistência offline
    Sincronização validada → jornada real no A72 → prioridades por evidência
    Uso real do editor → recorte do rework e diagnóstico da transposição
    Versões/arranjos entregues → C3 e tom por item, se o uso justificar
    Contexto da Lista → consultas e estatísticas derivadas
    Sincronização curada validada → backup e fontes remotas futuras
