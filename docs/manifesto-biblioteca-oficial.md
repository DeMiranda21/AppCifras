# Manifesto da Biblioteca Oficial

Este documento define o protocolo de publicação e consumo da Biblioteca
Oficial. A geração é hospedada e consumida por HTTPS pelo aplicativo; a antiga
integração Android SAF não faz parte do protocolo nem do produto.

## Estrutura da geração

Cada geração pronta para hospedagem possui esta estrutura:

```text
<saida>/
  manifest.json
  relatorio.md
  musicas/
    <IdVersaoMusica-em-base64url-sem-padding>.cho
```

O nome físico deriva somente de IdVersaoMusica. Título, artista, nome do
arquivo de entrada e nome da versão não participam do localizador publicado.

## Schema 1

```json
{
  "schema": 1,
  "generation": "20261025T120000Z",
  "publishedAt": "2026-10-25T12:00:00.000Z",
  "files": [
    {
      "idMusica": "musica-1",
      "idVersaoMusica": "versao-1",
      "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      "size": 321,
      "path": "musicas/dmVyc2FvLTE.cho"
    }
  ]
}
```

- `schema` identifica o contrato do manifesto; somente o valor `1` é aceito.
- `generation` é um identificador textual seguro. Por padrão, o publicador usa
  o instante UTC sem separadores; o operador pode fornecê-lo explicitamente.
- `publishedAt` é o instante de publicação em ISO-8601, normalizado para UTC.
- `files` é ordenado por IdMusica e depois IdVersaoMusica.
- `sha256` contém 64 caracteres hexadecimais minúsculos e identifica os bytes
  exatos publicados.
- `size` é o tamanho positivo desses bytes.
- `path` é relativo à futura URL-base da Biblioteca Oficial.

Cada IdVersaoMusica e cada `path` ocorre uma única vez. O manifesto não duplica
título, artista, tom, nome da versão ou a marca de principal: esses dados
continuam no ChordPro schema 2 validado por S1.

Paths aceitos não possuem scheme, host, query, fragmento, barra inicial,
contrabarra, `%`, segmento vazio, `.` ou `..`. Cada segmento usa somente
letras ASCII, dígitos, ponto, sublinhado, til ou hífen.

## Publicador local

```text
dart run tool/publicar_biblioteca.dart --entrada <pasta-curada> --saida <diretorio-novo-da-geracao> [--geracao <identificador>] [--publicado-em <ISO-8601>] [--relatorio <arquivo>]
```

Se `--relatorio` for omitido, o relatório externo fica em
`<saida>.relatorio.md`. A pasta de saída deve ser nova e ficar fora da pasta de
entrada. O publicador lê somente arquivos `.cho` filhos diretos; outros itens
são ignorados com aviso.

O fluxo local é:

1. ler os bytes sem alterar a origem;
2. validar UTF-8, schema 2, metadados, identidades, grupos e principal única;
3. montar manifesto e paths determinísticos;
4. escrever os `.cho` em diretório temporário irmão da saída;
5. reler cada arquivo e conferir tamanho e SHA-256;
6. escrever manifesto e relatório;
7. renomear o diretório temporário para a saída final.

Qualquer falha anterior ao último passo remove o temporário e não deixa uma
geração final parcial. Uma saída já existente nunca é sobrescrita. A pasta
curada original não é normalizada, reformatada ou modificada.
