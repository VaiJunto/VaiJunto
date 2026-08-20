# VaiJunto — regras do projeto

## Versionamento obrigatório

**Toda alteração que exija recompilar o app incrementa a versão.** Sem exceção,
mesmo para mudança de uma linha.

Isso existe porque o teste acontece em device físico e web: a versão no rodapé
das telas de login/cadastro é a única forma de saber, olhando a tela, se o build
instalado já tem a mudança. Sem ela, "não funcionou" e "não recompilou" ficam
indistinguíveis — e já custou tempo neste projeto.

### Como incrementar

Dois arquivos, sempre juntos:

| Arquivo | Campo | Formato |
|---|---|---|
| `mobile/lib/core/app_version.dart` | `kAppVersion` | `1.0.0.1` |
| `mobile/pubspec.yaml` | `version:` | `1.0.0+1` |

O 4º número do Dart é o `+build` do pubspec. Eles têm que bater.

### Qual número mexer

- **build** (`1.0.0.1` → `1.0.0.2`) — o padrão. Correção, ajuste de UI, refactor.
- **patch** (`1.0.0.9` → `1.0.1.0`) — conjunto de correções fechado, algo que
  valha marcar.
- **minor** (`1.0.x` → `1.1.0.0`) — feature nova (tela, fluxo, endpoint).
- **major** (`1.x` → `2.0.0.0`) — só quando o usuário pedir.

Ao subir major/minor/patch, o build volta para `0`.

### O que NÃO precisa incrementar

Mudança que não vai para o binário: `README.md`, `REQUIREMENTS.md`,
`mobile/DESIGN.md`, este arquivo, `dev.ps1`, comentário solto, `.gitignore`.

## Design visual do app mobile

Antes de criar ou alterar qualquer tela/widget visual, leia
[mobile/DESIGN.md](mobile/DESIGN.md) — define a paleta (neobrutalismo, só 2
cores de marca com papel fixo cada) e os componentes prontos
(`NeoButton`, `NeoCard`, etc.) que devem ser reutilizados em vez de recriados.
Cor de acento nova ou fora do papel definido lá é sinal de que o padrão não
foi seguido.

## Fluxo de desenvolvimento

```bash
./dev.ps1
```

Sobe Postgres + backend, compila o APK, instala via ADB, refaz o `adb reverse` e
abre o app. Use `-Web` para rodar no Chrome com hot reload (loop bem mais rápido
para mexer em UI) e `-SkipBackend` se o backend já estiver no ar.

Detalhes de ambiente (versões de SDK, setup do Postgres/PostGIS, pegadinhas)
estão em [REQUIREMENTS.md](REQUIREMENTS.md).

## Git

O usuário faz os commits e pushes. Forneça os comandos prontos, mas **não
execute** `git commit` nem `git push`, e não adicione atribuição de IA às
mensagens.
