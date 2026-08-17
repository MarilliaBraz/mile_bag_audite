# Convenções do Projeto — mile_bag_audite

Este documento define os padrões de construção do projeto. Como a stack ainda não
foi definida, as convenções abaixo são agnósticas de linguagem e devem ser
adaptadas (sem perder o espírito) quando a stack for escolhida.

## 1. Estrutura de pastas

Estrutura raiz recomendada:

```
mile_bag_audite/
├── src/                # código-fonte da aplicação
│   ├── modules/        # ou domains/ — um subdiretório por domínio/feature
│   ├── shared/         # código compartilhado entre módulos (utils, types, config)
│   └── main.*          # ponto de entrada da aplicação
├── tests/              # testes automatizados, espelhando a estrutura de src/
├── docs/               # documentação adicional (ADRs, diagramas, etc.)
├── scripts/            # scripts auxiliares (build, deploy, migração)
├── .github/             # workflows de CI/CD, templates de PR/issue
├── CONVENTIONS.md
├── README.md
└── CHANGELOG.md
```

Regras:
- Organização por **domínio/feature** dentro de `src/`, não por tipo técnico
  (evitar pastas genéricas como `controllers/`, `services/` soltas na raiz de `src/`).
- Cada módulo deve conter seus próprios testes próximos ou espelhados em `tests/`.
- Nenhum arquivo solto na raiz do repositório além de configuração
  (`.gitignore`, `README.md`, `CONVENTIONS.md`, arquivos de config de build).

## 2. Convenção de commits

Seguimos **Conventional Commits**:

```
<tipo>(<escopo opcional>): <descrição curta no imperativo>

[corpo opcional explicando o porquê]

[rodapé opcional: referências a issues, breaking changes]
```

Tipos permitidos:
- `feat`: nova funcionalidade
- `fix`: correção de bug
- `docs`: mudanças apenas de documentação
- `style`: formatação, sem mudança de lógica
- `refactor`: refatoração sem mudar comportamento
- `test`: adição ou ajuste de testes
- `chore`: manutenção (deps, config, build)
- `perf`: melhoria de performance

Regras:
- Descrição no imperativo, minúscula, sem ponto final (`fix: corrige validação de peso da mala`).
- Um commit deve representar uma mudança lógica única e coesa.
- Breaking changes marcados com `!` após o tipo/escopo (`feat!: ...`) e explicados no rodapé com `BREAKING CHANGE:`.

## 3. Nomenclatura de código

- **Arquivos**: `kebab-case` (ex: `bag-audit-service.ts`), exceto quando a stack exigir outro padrão (ex: classes Java em `PascalCase.java`).
- **Variáveis e funções**: `camelCase`.
- **Classes, interfaces, tipos, componentes**: `PascalCase`.
- **Constantes globais/imutáveis**: `SCREAMING_SNAKE_CASE`.
- **Booleanos**: prefixo `is`, `has`, `can`, `should` (ex: `isValid`, `hasPermission`).
- **Nomes descritivos e em inglês** no código (variáveis, funções, classes); textos voltados ao usuário final podem ser em português.
- Evitar abreviações não óbvias; preferir clareza a brevidade.

## 4. Branching / fluxo git

Modelo baseado em **trunk-based simplificado**:

- `main`: sempre estável e deployável.
- `feature/<descrição-curta>`: novas funcionalidades, a partir de `main`.
- `fix/<descrição-curta>`: correções de bug, a partir de `main`.
- `chore/<descrição-curta>`: manutenção/config.

Regras:
- Nomes de branch em `kebab-case`, descritivos (ex: `feature/validacao-peso-mala`).
- Toda mudança entra em `main` via **Pull Request**, nunca push direto.
- PR deve ter descrição do que mudou e por quê; título segue o padrão de commits.
- Branch é excluída após o merge.
- Rebase (não merge commit) para manter histórico linear ao atualizar a branch com `main`, quando possível.

---

*Este documento deve evoluir junto com o projeto. Alterações nas convenções passam por PR e revisão.*
