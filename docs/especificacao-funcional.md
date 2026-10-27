# Especificação Funcional — AppCifras

## Objetivo

App Android para músicos de igreja manterem uma Biblioteca Musical local,
consultarem cifras com rapidez e organizarem repertórios para ensaios e cultos.
O uso cotidiano não depende de internet nem exige conhecimento de ChordPro.

## Meta imediata de produção pessoal

A próxima versão utilizável deve permitir a jornada completa: atualizar a
Biblioteca Oficial pública, localizar uma música na Biblioteca, abrir e
transpor a versão correta, organizá-la em Lista de Culto, usá-la em ensaio ou
culto e continuar consultando todo o conteúdo já local sem acesso à origem.
Melhorias amplas de edição e conveniência serão priorizadas depois de observar
esse uso real.

## Capacidades atuais

### Biblioteca Musical

A Biblioteca reúne músicas locais identificadas individualmente. Cada música
válida tem título, artista, tom original e conteúdo musical. O usuário cadastra
por texto/colagem, importa ChordPro, edita, exclui com confirmação e pesquisa
por título, artista ou conteúdo visível da letra. Resultados encontrados na
letra podem exibir uma linha correspondente. A pesquisa pode ser combinada com
filtros locais de energia e tags.

### Conteúdo e leitura

ChordPro é o formato canônico. A cifra mostra título, artista, tom de execução
e letra com acordes em layout responsivo. Conteúdo ou acordes não reconhecidos
são preservados; acordes não interpretáveis ficam visíveis e bloqueiam
transposição insegura.

### Tom de execução

O usuário altera temporariamente o tom por semitom. A alteração não reescreve
a música nem o tom original. O último tom é uma preferência local por versão e
é restaurado ao reabrir.

### Listas de Culto

O usuário cria, renomeia e exclui Listas, inclui músicas, reordena itens e os
remove mediante confirmação. No detalhe, pode trocar a versão concreta de um
item por outra versão ativa da mesma Música. Ao abrir uma música da Lista,
percorre os itens na ordem preparada. A Lista atual não possui tom próprio por
item.

## Visão de evolução

### Entrada manual e revisão

A experiência comum não expõe ChordPro. O usuário cola texto normal, o
AppCifras analisa e converte apenas o que reconhece com segurança, mantém o
ChordPro internamente e apresenta pontos de decisão em sequência. Cada etapa
mostra `Problema X de N`, o trecho no contexto, o motivo e somente as ações
compatíveis com aquela ocorrência.

Na primeira fatia, as ações são `É acorde`, `É texto` e `Corrigir acorde`. Uma
correção de acorde usa campo curto e validação musical antes de ser aplicada.
Depois de cada decisão, o documento é analisado novamente e a revisão segue
para o próximo problema atual. O usuário pode voltar ou avançar, mas não precisa
localizar o trecho, selecioná-lo, lembrar avisos anteriores nem editar sintaxe.

Trechos desconhecidos que possam ser preservados não impedem salvar. O
aplicativo informa limitações concretas, como indisponibilidade de transposição,
e bloqueia apenas quando não consegue formar um documento minimamente válido
ou quando um campo obrigatório está inválido. Título, artista e tom original
continuam fora da sequência, em campos próprios.

### Edição comum e modo avançado

A infraestrutura dessa revisão será reutilizada depois para localizar o trecho
que bloqueia transposição. Em uma etapa posterior, o editor comum aplicará
ações musicais sobre acordes, texto, linhas e seções sem depender de seleção
automática, `RenderEditable`, busca textual ou menu contextual nativo. A base
já entregue de reconhecimento estrutural, blocos e transformações puras será
adaptada, sem trocar o ChordPro como fonte canônica.

O editor textual ChordPro permanece como opção secundária para usuários
avançados e como fallback. O ponto de acesso e sua apresentação ainda serão
definidos.

O rework do editor comum e o diagnóstico contextual dos trechos que bloqueiam
transposição continuam desejáveis, mas não são requisito para iniciar uso
pessoal em produção. O uso real determinará o próximo recorte dessas melhorias.

### Atualização da Biblioteca Oficial

A Biblioteca Oficial é única e pública. O usuário não faz login nem escolhe
pasta remota. A atualização futura consulta por HTTPS um manifesto versionado,
baixa somente os arquivos `.cho` necessários, incorpora-os ao armazenamento
local e mantém a Biblioteca utilizável offline. O fluxo não converte `.txt`,
não abre revisão interativa e não substitui importação.

O curador prepara cada geração com uma ferramenta local que valida integralmente
os arquivos antes de produzir `manifest.json` e os bytes prontos para
hospedagem. O manifesto contém identidades, SHA-256, tamanho e path relativo;
título, artista, tom e nome da versão permanecem no ChordPro schema 2.

Cada arquivo usa schema 2 e identifica explicitamente a Musica, a VersaoMusica,
o nome da versão e, para a primeira incorporação, a principal inicial. Nome,
caminho, título e rótulo da versão não são identidade. Arquivos inválidos,
duplicidades e grupos inconsistentes são informados sem impedir Músicas
independentes.

Versões sincronizadas presentes são somente leitura. O usuário que desejar
alterá-las cria uma nova versão local, que pode ser editada e definida como
principal, mas não retorna à publicação oficial. Atualizações externas
preservam os IDs e as referências das Listas; uma alternativa já usada em
Lista exige que o curador publique novo IdVersaoMusica em vez de sobrescrevê-la.

Quando um arquivo desaparece após uma enumeração completa, seu conteúdo local,
último tom e referências são preservados e a origem passa a ausente. Reaparecer
com os mesmos IDs recupera o mesmo vínculo. Falha de acesso ou de uma geração
incompleta não é remoção. O conteúdo incorporado continua disponível offline.

Ao fim, um relatório simples informa adicionadas, atualizadas, inalteradas,
origens ausentes e ignoradas com erro, com arquivo e motivo breve para cada
falha.

A Biblioteca Oficial é atualizada exclusivamente pelo manifesto e pelos
arquivos públicos via HTTPS. A integração Android SAF anterior foi removida e
não há seleção de pasta ou configuração de provedor no produto. Apenas a
tabela física legada pode permanecer no banco para compatibilidade de schema.

### Demais evoluções

Versões e arranjos estão entregues até a edição da versão concreta. A escolha
de versão na inclusão inicial em Lista, o tom da ocasião por item, data,
ministrante, consulta de repertórios anteriores, importação múltipla, BPM,
backup e estatísticas permanecem evoluções. Elas serão ordenadas por problemas
observados no uso real; consultas históricas e estatísticas continuarão
derivadas das próprias Listas, sem subsistema independente de execução nesta
fase.

Sincronização e importação são fluxos distintos. Importação genérica e em lote
permanece uma evolução própria. Colaboração e múltiplas bibliotecas não fazem
parte da experiência atual. Ordem, dependências e prioridades estão em
roadmap-desenvolvimento.md.
