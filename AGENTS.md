# AppCifras — Orientações Permanentes

## Propósito

App Flutter para músicos, centrado em uma Biblioteca Musical local para
consulta e organização de cifras. O aplicativo deve continuar útil sem
internet; a sincronização é apenas uma evolução futura.

## Hierarquia da documentação

Antes de decidir ou implementar, consulte:

1. `docs/principios.md` para princípios permanentes;
2. `docs/modelo-dominio.md` para conceitos musicais e regras de domínio;
3. `docs/decisoes-mvp.md` para o escopo e simplificações aprovados do MVP;
4. `docs/especificacao-funcional.md`, `docs/roadmap-desenvolvimento.md` e
   `docs/requisitos-nao-funcionais.md` como referências complementares.

Para o MVP, `docs/decisoes-mvp.md` resolve divergências temporárias de
escopo. Decisões permanentes de conceito musical pertencem ao Modelo de
Domínio.

## Princípios obrigatórios

- Offline é prioridade após os dados estarem disponíveis localmente.
- O usuário é dono de seus arquivos; prefira formatos acessíveis e não
  proprietários.
- A Biblioteca Musical é o centro da experiência, não arquivos isolados.
- A lógica de domínio não depende de Flutter, telas, banco de dados ou APIs.
- Clareza, baixo acoplamento e responsabilidade única valem mais que padrões
  sofisticados sem necessidade concreta.
- Implemente de forma incremental; não antecipe recursos futuros.
- Durante ensaios e cultos, rapidez, estabilidade e poucos toques prevalecem
  sobre efeitos visuais.

## Escopo aprovado do MVP

Inclui:

- biblioteca local, busca por título, favoritos e configurações locais;
- cadastro, edição em texto simples e exclusão confirmada de músicas;
- título, artista, tom original e conteúdo com letra e acordes obrigatórios;
- conteúdo das músicas estruturado em ChordPro;
- visualização de cifras, ajuste de fonte e transposição;
- visualização por cifras, graus ou ambas;
- Listas de Culto com criação, inclusão, reordenação, tom por item e
  navegação;
- funcionamento offline.

Ficam fora do MVP: sincronização em nuvem, importação de PDF,
compartilhamento, coleções, histórico avançado, editor estruturado por
seções, modo palco, rolagem automática, estatísticas, Bluetooth, MIDI, IA e
colaboração.

## Regras de domínio do MVP

- Música é uma entidade independente, identificada por ID e persistida
  localmente.
- Biblioteca Musical é um escopo organizacional, não um Aggregate Root formal
  no MVP.
- Lista de Culto tem identidade própria e seus itens referenciam músicas por
  ID.
- Registro de Tom, Tag e Fonte de Sincronização não são entidades completas no
  MVP; use valores ou estruturas simples somente quando forem necessários.
- A transposição nunca altera o conteúdo original nem o tom original da
  música.
- Na exibição por graus, converta somente acordes diatônicos para o tom atual.
  Acordes não diatônicos e inversões permanecem como cifras absolutas com a
  grafia original.
- O editor inicial é texto simples. Não implemente edição estruturada de
  seções ou blocos antes de existir necessidade aprovada.

## Dados e persistência

- Preserve o conteúdo ChordPro fornecido pelo usuário.
- Uma representação interpretada para renderização, transposição e graus deve
  ser derivada do ChordPro, sem substituir o conteúdo original.
- Metadados associados ao ChordPro devem ter esquema versionável.
- A exclusão de música é definitiva no armazenamento local e exige confirmação
  explícita. Não implemente lixeira ou exclusão lógica no MVP.

## Arquitetura e qualidade

- Mantenha entidades, objetos de valor e serviços musicais em Dart puro,
  isolados da interface.
- Use casos de uso para coordenar domínio e persistência.
- Mantenha infraestrutura local atrás de abstrações de repositório.
- Teste parser ChordPro, transposição e conversão de graus sem depender de
  widgets.
- Valide a experiência em um Samsung Galaxy A72: abertura de músicas,
  operação offline, rolagem fluida, leitura confortável, transposição sem
  atraso perceptível e consumo moderado de memória e bateria.

## Conduta de mudanças

- Não altere o escopo do MVP nem documentos de decisão sem aprovação explícita
  do proprietário.
- Atualize a documentação oficial quando uma decisão permanente mudar.
- Não faça commit, push, exclusões destrutivas ou alterações fora da tarefa
  solicitada sem autorização explícita.

## Pendências antes do parser

- Definir a versão mínima do Android.
- Especificar a lista exata de notações básicas aceitas pelo parser ChordPro.
- Definir o esquema versionado dos metadados associados ao arquivo ChordPro.
