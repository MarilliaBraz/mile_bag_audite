# mile_bag_audite

Módulo de auditoria do **Milebag — Gestão de Última Milha de Bagagens**: garante conferência, validação e controle confiável das bagagens vinculadas ao processo de devolução, reduzindo divergências, fraudes ou erros no processo de auditoria.

## Conteúdo deste repositório

- [`CONSTITUTION.md`](./CONSTITUTION.md) — missão, princípios, escopo e regras de governança do módulo.
- [`CONVENTIONS.md`](./CONVENTIONS.md) — padrões técnicos: stack, estrutura de pastas, arquitetura, nomenclatura, convenção de commits e fluxo git.
- [`scripts/padronizar-projeto.sh`](./scripts/padronizar-projeto.sh) — aplica as normas de configuração do `CONVENTIONS.md` num repositório `mile_bag_*` e audita onde o código foge delas (ver abaixo).

## Script de padronização

Versão adaptada ao Milebag do script da aula de Normas de Configuração (o original, para Angular, está em `mile_bag_documentacao/evidencias/padronizar-projeto.sh`).

```bash
# a partir da pasta que contém os repositórios
mile_bag_audite/scripts/padronizar-projeto.sh mile_bag_api --dry-run   # mostra o que faria
mile_bag_audite/scripts/padronizar-projeto.sh mile_bag_api             # aplica
mile_bag_audite/scripts/padronizar-projeto.sh mile_bag_app             # React: só auditoria
```

- **Aplica** (só o que ainda não existe; `--force` substitui com backup `.bak`): `.editorconfig`, linhas em `.gitattributes` e `.gitignore`, Checkstyle com a nomenclatura da §4.1 (projeto Maven; o `pom.xml` nunca é editado) e hooks de Git: `commit-msg` com a §3 e `pre-commit` contra `System.out`, segredo no código e arquivo `.env`.
- **Projeto React:** somente auditoria — nenhum arquivo é criado ou alterado.
- **Não gera** `CONVENTIONS.md` nos repositórios: a fonte única é este repositório.
- **Audita** (só leitura): arquivos grandes, `core` importando `business` (§1.1), feature importando outra feature (§1.2), interfaces com prefixo `I` (§4.1), endereço de ambiente fixo no código e migrações Flyway repetidas (§2.3), código comentado, TODO sem responsável, mensagens de commit fora da §3 e coautoria de IA.

## Stack

- **Back-end:** Java, seguindo princípios SOLID
- **Front-end:** React, organizado por feature

Ver `CONVENTIONS.md` para o detalhamento completo.

## Repositórios relacionados

- [`mile_bag_documentacao`](https://github.com/MarilliaBraz/mile_bag_documentacao) — documentação do projeto (TAP, escopo, sessões)
- [`mile_bag_api`](https://github.com/MarilliaBraz/mile_bag_api) — back-end (Java/Spring Boot)
- [`mile_bag_app`](https://github.com/MarilliaBraz/mile_bag_app) — front-end / aplicação do motorista
- [`mile_bag_infra`](https://github.com/MarilliaBraz/mile_bag_infra) — infraestrutura e implantação
