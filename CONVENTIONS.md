# Convenções do Projeto — mile_bag_audite

Este documento define os padrões de construção do projeto.

## 0. Stack

- **Backend:** Java, seguindo os princípios **SOLID**.
- **Frontend:** React, organizado por **feature**.

## 1. Estrutura de pastas

### 1.1 Backend (Java)

Separação entre **core** (infraestrutura genérica, reutilizável, sem regra de
negócio) e **business** (regras de negócio, organizadas por domínio):

```
backend/
├── src/main/java/com/marillia/milebag/
│   ├── core/                    # genérico, reutilizável, independente de negócio
│   │   ├── config/              # beans, security, configs gerais, contexto de tenant
│   │   ├── exception/           # tratamento de exceções e erros padronizados
│   │   ├── util/                # utilitários reutilizáveis
│   │   └── base/                # classes base (BaseEntity, BaseRepository, BaseService)
│   ├── business/                # regras de negócio, um subpacote por domínio
│   │   ├── tenant/       # tenant, plano de assinatura, convite de administrador
│   │   ├── bdo/          # captura e conferência do BDO (OCR)
│   │   ├── entrega/      # ciclo de vida da entrega, bagagem carona
│   │   ├── rota/         # cálculo de rota (transitório)
│   │   ├── viagem/       # snapshot de rota congelado
│   │   ├── comprovante/  # comprovante de entrega (POD)
│   │   ├── ocorrencia/   # ocorrências e reabertura de BDO
│   │   ├── tarifa/       # tabelas de tarifa
│   │   ├── pedagio/      # praças de pedágio
│   │   ├── fechamento/   # fechamento financeiro periódico
│   │   └── configuracao/ # parametrização por tenant, identidade visual
│   │       ├── controller/
│   │       ├── service/
│   │       ├── repository/
│   │       ├── model/           # entities / DTOs
│   │       └── mapper/
│   └── MilebagApplication.java
├── src/main/resources/
│   ├── application.yml
│   ├── application-dev.yml
│   └── application-prod.yml
├── src/test/java/...            # espelha a estrutura de src/main/java
└── pom.xml
```

Cada subpacote de `business/<dominio>/` segue a mesma estrutura interna mostrada em
`configuracao/` acima (`controller/`, `service/`, `repository/`, `model/`, `mapper/`
quando aplicável) — omitida nos demais só para não repetir no diagrama.

Regras:
- `core` nunca depende de `business`; a dependência é sempre em uma direção
  (`business` pode usar `core`, nunca o inverso).
- Regra de negócio nova entra em `business/<dominio>`, nunca solta em `core`.
- Comportamento comum a múltiplos domínios (ex: validação genérica,
  paginação, resposta padrão de API) vive em `core` para reuso.

### 1.2 Frontend (React) — organização por feature

```
frontend/
├── src/
│   ├── features/
│   │   ├── motorista/            # PWA do motorista
│   │   │   ├── captura-bdo/
│   │   │   │   ├── components/
│   │   │   │   ├── hooks/
│   │   │   │   ├── services/    # chamadas à API
│   │   │   │   ├── types/
│   │   │   │   └── index.ts
│   │   │   ├── rota/
│   │   │   └── offline-sync/
│   │   └── back-office/          # administrador do tenant e da plataforma
│   │       ├── tarifas/
│   │       ├── pedagios/
│   │       ├── fechamento/
│   │       └── ...
│   ├── shared/                  # componentes, hooks e utils reutilizados entre features
│   │   ├── components/
│   │   ├── hooks/
│   │   └── utils/
│   ├── App.tsx
│   └── main.tsx
├── public/
└── package.json
```

Regras:
- Cada `feature/` é autocontida: componentes, hooks e chamadas de API
  específicos daquela feature ficam dentro dela, não espalhados por pastas
  técnicas genéricas (`components/`, `services/` na raiz).
- Só sobe para `shared/` o que é usado por **duas ou mais** features.
- Uma feature não importa direto de dentro de outra feature; se precisa
  compartilhar algo, esse algo sobe para `shared/`.
- Quando um repositório reúne mais de uma aplicação (caso do `mile_bag_app`,
  que tem back-office e a PWA do motorista no mesmo projeto), `features/`
  ganha um nível de agrupamento por aplicação (`features/<app>/<dominio>/`)
  antes da regra acima — a organização por feature continua valendo dentro
  de cada aplicação.

## 2. Princípios de arquitetura

### 2.1 SOLID (backend)

- **S — Single Responsibility:** cada classe tem um único motivo para mudar
  (ex: `Service` não deve conter lógica de acesso a dados nem de apresentação).
- **O — Open/Closed:** extensão via novas classes/implementações, não
  modificando classes existentes que já funcionam.
- **L — Liskov Substitution:** implementações de uma interface devem ser
  substituíveis entre si sem quebrar o comportamento esperado.
- **I — Interface Segregation:** interfaces pequenas e específicas em vez de
  uma interface genérica "faz tudo".
- **D — Dependency Inversion:** classes dependem de abstrações (interfaces),
  não de implementações concretas; injeção de dependência sempre que possível.

### 2.2 Reutilização de código

- Antes de escrever uma nova função/classe, verificar se algo equivalente já
  existe em `core` (backend) ou `shared` (frontend).
- Lógica repetida em 2+ lugares deve ser extraída para um ponto único de
  reuso (não copiar/colar).
- Preferir composição a herança profunda; usar herança apenas para relações
  genuínas de "é um" (ex: `BaseEntity`).

### 2.3 Os 3 pilares da manutenção de software

1. **Parametrização** — valores que podem variar (limites, regras,
   textos, feature flags) não são hardcoded no código; ficam em
   configuração (`application.yml`, tabelas de parâmetro, variáveis de
   ambiente do frontend).
2. **Ambiente** — configuração isolada por ambiente (`dev`, `staging`,
   `prod`) via profiles do Spring (`application-<env>.yml`) e arquivos
   `.env.<env>` no frontend; nenhum valor de ambiente específico
   (URL, credencial, etc.) vai direto no código-fonte.
3. **Versão** — versionamento explícito de: API (ex: `/api/v1/...`),
   migrações de banco (Flyway/Liquibase, sempre incrementais e nunca
   editadas após aplicadas) e do próprio projeto (SemVer + `CHANGELOG.md`).

## 3. Convenção de commits

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
- Descrição no imperativo, minúscula, sem ponto final (`fix: corrige congelamento de pedagio na viagem`).
- Um commit deve representar uma mudança lógica única e coesa.
- Breaking changes marcados com `!` após o tipo/escopo (`feat!: ...`) e explicados no rodapé com `BREAKING CHANGE:`.
- Commits não devem incluir rodapé de coautoria de IA (ex: `Co-Authored-By: Claude`); a autoria do commit é sempre humana.

## 4. Nomenclatura de código

### 4.1 Backend (Java)

- **Pacotes**: `lowercase`, sem underscore (ex: `com.marillia.milebag.business.entrega`).
- **Classes e interfaces**: `PascalCase` (ex: `EntregaService`, `EntregaRepository`, `TabelaTarifa`).
- **Métodos e variáveis**: `camelCase` (ex: `calcularQuilometragemComplementar`, `congelarSnapshotRota`).
- **Constantes e valores de enum**: `SCREAMING_SNAKE_CASE` (ex: `EntregaStatus.EM_ANDAMENTO`, `EntregaStatus.ENCERRADA_COM_SUCESSO`).
- **Interfaces de implementação única** não usam prefixo `I` (ex: `EntregaService` + `EntregaServiceImpl`, não `IEntregaService`).
- **Booleanos**: prefixo `is`, `has`, `can` (ex: `isPendente`, `hasExcedidoLimiteMotoristas`).

### 4.2 Frontend (React)

- **Componentes**: arquivo e nome do componente em `PascalCase` (ex: `EntregaCard.tsx`, `TelaConferenciaBdo.tsx`).
- **Hooks**: `camelCase` com prefixo `use` (ex: `useCapturaBdo.ts`, `useRota.ts`).
- **Funções, variáveis, services**: `camelCase` (ex: `bdoService`, `rotaService`).
- **Tipos/Interfaces**: `PascalCase` (ex: `EntregaDTO`).
- **Pastas de feature**: `kebab-case` (ex: `captura-bdo/`, `bagagem-carona/`).

### 4.3 Geral

- Vocabulário técnico genérico (padrões de arquitetura, tipos de dado, verbos de
  CRUD) em inglês: `Service`, `Repository`, `Controller`, `Request`, `Response`,
  `create`, `find`, `update`.
- Termos de domínio (a linguagem ubíqua do negócio, a mesma usada no TAP, nas
  HUs e com a empresa parceira) ficam em **português**, mesmo em identificadores
  de código: `Entrega`, `BDO`, `TabelaTarifa`, `PracaPedagio`, `ComprovanteEntrega`,
  `EntregaStatus`. Não traduzir esses nomes para o inglês — a tradução afastaria o
  código do vocabulário usado na documentação e na conversa com o cliente.
- Textos voltados ao usuário final sempre em português.
- Evitar abreviações não óbvias; preferir clareza a brevidade.

## 5. Branching / fluxo git

Modelo baseado em **trunk-based simplificado**:

- `main`: sempre estável e deployável.
- `feature/<descrição-curta>`: novas funcionalidades, a partir de `main`.
- `fix/<descrição-curta>`: correções de bug, a partir de `main`.
- `chore/<descrição-curta>`: manutenção/config.

Regras:
- Nomes de branch em `kebab-case`, descritivos (ex: `feature/congelamento-rota-viagem`).
- Toda mudança entra em `main` via **Pull Request**, nunca push direto.
- PR deve ter descrição do que mudou e por quê; título segue o padrão de commits.
- Branch é excluída após o merge.
- Rebase (não merge commit) para manter histórico linear ao atualizar a branch com `main`, quando possível.

---

*Este documento deve evoluir junto com o projeto. Alterações nas convenções passam por PR e revisão.*
