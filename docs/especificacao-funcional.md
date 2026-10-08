# Especificação Funcional — AppCifras

## Objetivo

App Android para músicos de igreja manterem uma Biblioteca Musical local,
consultarem cifras com rapidez e organizarem repertórios para ensaios e cultos.
O uso cotidiano não depende de internet nem exige conhecimento de ChordPro.

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
remove mediante confirmação. Ao abrir uma música da Lista, percorre os itens
na ordem preparada. A Lista atual não possui tom próprio por item.

## Visão de evolução

O editor assistido será a experiência principal para alterações comuns: o
usuário poderá atuar sobre um token, linha ou bloco para indicar acorde, texto
ou seção, e o aplicativo produzirá a alteração correspondente no ChordPro.
Exemplos incluem marcar texto como acorde, remover sua marcação, editar um
acorde e marcar ou trocar o tipo de uma seção. A edição textual ChordPro
permanece como modo avançado e fallback; ela não será removida nesta etapa.

Reconhecimento estrutural, edição assistida, edição por blocos, classificação,
metadados, versões/arranjos, contexto de ministração nas Listas, consulta de
repertórios anteriores, importação múltipla, BPM, backup e estatísticas
evoluirão em etapas. Uma evolução aprovada permitirá que uma Música tenha
versões de arranjo, com uma versão principal; Listas futuras registrarão data,
ministrante opcional, versão e tom da ocasião por item. Consultas históricas e
estatísticas serão derivadas das próprias Listas, sem subsistema independente
de execução nesta fase. Versões usadas por Listas preservarão seu conteúdo
musical e serão arquivadas, em vez de excluídas, quando necessário. Ordem,
dependências e prioridades estão em
roadmap-desenvolvimento.md. Sincronização, colaboração e múltiplas bibliotecas
não fazem parte da experiência atual.
