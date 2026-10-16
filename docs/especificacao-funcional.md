# Especificação Funcional — AppCifras

## Objetivo

App Android para músicos de igreja manterem uma Biblioteca Musical local,
consultarem cifras com rapidez e organizarem repertórios para ensaios e cultos.
O uso cotidiano não depende de internet nem exige conhecimento de ChordPro.

## Meta imediata de produção pessoal

A próxima versão utilizável deve permitir a jornada completa: sincronizar uma
pasta curada, localizar uma música na Biblioteca, abrir e transpor a versão
correta, organizá-la em Lista de Culto, usá-la em ensaio ou culto e continuar
consultando todo o conteúdo já local sem acesso à origem. Melhorias amplas de
edição e conveniência serão priorizadas depois de observar esse uso real.

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

### Sincronização da pasta curada

A próxima entrega funcional permite configurar uma pasta curada de arquivos
`.cho`, descobrir os arquivos disponíveis e aplicar validação técnica leve por
arquivo. Arquivos válidos novos, alterados ou removidos serão reconciliados com
a Biblioteca local conforme regras explícitas de identidade e remoção ainda a
decidir. Uma falha deve aparecer no resultado daquele arquivo sem impedir os
demais.

O fluxo não converte `.txt`, não abre a revisão da entrada manual e não substitui
importação. A sincronização reutiliza a persistência local segura e deve
preservar IdMusica, IdVersaoMusica e referências existentes de Listas conforme
o contrato que for aprovado antes da implementação. O conteúdo aceito permanece
disponível offline depois da operação.

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
