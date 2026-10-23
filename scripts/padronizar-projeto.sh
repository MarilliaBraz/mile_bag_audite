#!/usr/bin/env bash
# =============================================================================
#  padronizar-projeto.sh — versão Milebag
#  Aplica as normas de configuração de CONVENTIONS.md (deste repositório) num
#  repositório mile_bag_* e audita onde o código foge delas.
#
#  Adaptado do script da aula "Normas de Configuração de Software e Boas
#  Práticas" (SENAI — evidencias/padronizar-projeto.sh em mile_bag_documentacao),
#  que assumia Angular + Maven. Diferenças principais:
#    - Front-end React + Vite + oxlint (CONVENTIONS.md §0), não Angular: o
#      Prettier segue o estilo atual do código e o hook usa o oxlint do projeto.
#    - Não gera CONVENTIONS.md: a fonte única é mile_bag_audite/CONVENTIONS.md.
#    - Hook de commit com os tipos e regras da §3 de CONVENTIONS.md.
#    - Auditoria das regras do projeto: core não depende de business (§1.1),
#      feature não importa de outra feature (§1.2), migrações Flyway (§2.3).
#    - Nunca sobrescreve sem --force e nunca edita o pom.xml.
#
#  Uso:
#    scripts/padronizar-projeto.sh [caminho-do-repositorio] [opções]
#
#  Opções:
#    --dry-run    Mostra o que seria feito, sem gravar nada
#    --force      Substitui arquivos existentes (cria backup .bak antes)
#    --audit      Só roda a auditoria (não cria arquivos)
#    --install    Projeto React: instala o Prettier (devDependency) via npm
#    -h, --help   Mostra esta ajuda
#
#  Exemplo (todos os repositórios, a partir de D:\Projeto_PI):
#    for r in mile_bag_api mile_bag_app mile_bag_infra; do
#      mile_bag_audite/scripts/padronizar-projeto.sh "$r" --dry-run
#    done
# =============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
# Configuração
# ----------------------------------------------------------------------------
PROJECT_DIR="."
DRY_RUN=false
FORCE=false
AUDIT_ONLY=false
INSTALL=false

MAX_FILE_LINES=300   # acima disso o arquivo provavelmente faz coisa demais
LIMITE_LISTA=20      # máximo de achados mostrados por item da auditoria
PACOTE_BASE="com.marillia.milebag"
TIPOS_COMMIT="feat|fix|docs|style|refactor|test|chore|perf"   # CONVENTIONS.md §3

if [[ -t 1 ]]; then
  C_OK=$'\e[32m'; C_WARN=$'\e[33m'; C_INFO=$'\e[36m'; C_ERR=$'\e[31m'; C_RESET=$'\e[0m'
else
  C_OK=""; C_WARN=""; C_INFO=""; C_ERR=""; C_RESET=""
fi

log_ok()    { echo "${C_OK}✔${C_RESET} $*"; }
log_warn()  { echo "${C_WARN}⚠${C_RESET} $*"; }
log_info()  { echo "${C_INFO}→${C_RESET} $*"; }
log_error() { echo "${C_ERR}✖${C_RESET} $*" >&2; }
section()   { echo; echo "${C_INFO}== $* ==${C_RESET}"; }

show_help() { sed -n '2,33p' "$0" | sed 's/^#  \{0,1\}//'; exit 0; }

# ----------------------------------------------------------------------------
# Argumentos
# ----------------------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --force)   FORCE=true ;;
    --audit)   AUDIT_ONLY=true ;;
    --install) INSTALL=true ;;
    -h|--help) show_help ;;
    -*)        log_error "Opção desconhecida: $arg"; exit 1 ;;
    *)         PROJECT_DIR="$arg" ;;
  esac
done

if [[ ! -d "$PROJECT_DIR" ]]; then
  log_error "Diretório não encontrado: $PROJECT_DIR"
  exit 1
fi
cd "$PROJECT_DIR"
PROJECT_DIR="$(pwd)"

# ----------------------------------------------------------------------------
# Detecção do tipo de projeto
# ----------------------------------------------------------------------------
IS_MAVEN=false
IS_REACT=false
[[ -f pom.xml ]] && IS_MAVEN=true
if [[ -f package.json ]] && grep -q '"react"' package.json; then
  IS_REACT=true
fi


# ----------------------------------------------------------------------------
# Escrita segura: nunca sobrescreve sem --force, e faz backup quando sobrescreve
# ----------------------------------------------------------------------------
write_file() {
  local target="$1"
  local content
  content="$(cat)"

  if [[ -e "$target" && "$FORCE" == false ]]; then
    log_warn "Já existe, mantido: $target  (use --force para substituir)"
    return
  fi
  if $DRY_RUN; then
    log_info "[dry-run] criaria: $target"
    return
  fi

  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" ]]; then
    cp "$target" "$target.bak"
    log_warn "Backup salvo em $target.bak"
  fi
  printf '%s\n' "$content" > "$target"
  log_ok "Criado: $target"
}

# Acrescenta linhas a um arquivo apenas se ainda não existirem
append_unique() {
  local target="$1"; shift
  local line
  for line in "$@"; do
    if [[ -f "$target" ]] && grep -qxF "$line" "$target"; then
      continue
    fi
    if $DRY_RUN; then
      log_info "[dry-run] adicionaria '$line' em $target"
    else
      echo "$line" >> "$target"
      log_ok "Adicionado em $target: $line"
    fi
  done
}

# =============================================================================
# 1. PADRONIZAÇÃO — formatação igual para todo mundo
# =============================================================================
setup_editorconfig() {
  section "Padronização: .editorconfig"
  write_file ".editorconfig" <<'EOF'
# Regras de formatação compartilhadas por todas as IDEs (IntelliJ, VS Code, Eclipse).
# Fonte: mile_bag_audite/scripts/padronizar-projeto.sh
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[*.java]
indent_size = 4
max_line_length = 140

[*.{xml,sql}]
indent_size = 4

[*.md]
trim_trailing_whitespace = false
EOF
}

setup_gitattributes() {
  section "Padronização: .gitattributes"
  # Só o que quebra se vier com CRLF (scripts e hooks executados no Linux/Git
  # Bash). Não usamos "* text=auto eol=lf": renormalizaria o repositório inteiro.
  append_unique ".gitattributes" \
    "*.sh text eol=lf" \
    ".githooks/* text eol=lf"
}

setup_gitignore() {
  section "Organização: .gitignore"
  # .env.development/.env.production do Vite só têm configuração pública
  # (variáveis VITE_ vão para o navegador) e são versionadas; valores locais ou
  # secretos ficam em .env, .env.local e .env.*.local.
  append_unique ".gitignore" \
    "# --- Backups do padronizar-projeto.sh e ambiente local ---" \
    "*.bak" ".env" ".env.local" ".env.*.local"
}

setup_checkstyle() {
  $IS_MAVEN || return 0
  section "Padronização: Checkstyle (CONVENTIONS.md §4.1)"

  write_file "config/checkstyle/checkstyle.xml" <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE module PUBLIC
  "-//Checkstyle//DTD Checkstyle Configuration 1.3//EN"
  "https://checkstyle.org/dtds/configuration_1_3.dtd">

<!--
  Nomenclatura de CONVENTIONS.md §4.1 e limites de tamanho/complexidade.
  Tudo como aviso (severity=warning): mostra o desvio sem quebrar o build.
-->
<module name="Checker">
  <property name="charset" value="UTF-8"/>
  <property name="severity" value="warning"/>

  <module name="FileLength"><property name="max" value="400"/></module>
  <module name="LineLength"><property name="max" value="140"/></module>
  <module name="NewlineAtEndOfFile"/>

  <module name="TreeWalker">
    <!-- Nomenclatura (§4.1) -->
    <module name="TypeName"/>                       <!-- PascalCase: EntregaService -->
    <module name="MethodName"/>                     <!-- camelCase: calcularQuilometragemComplementar -->
    <module name="LocalVariableName">
      <property name="allowOneCharVarInForLoop" value="true"/>
    </module>
    <module name="MemberName"/>
    <module name="ParameterName"/>
    <module name="ConstantName">                    <!-- SCREAMING_SNAKE_CASE -->
      <!-- "log" é o nome do Logger em todo o projeto (private static final Logger log) -->
      <property name="format" value="^(log|[A-Z][A-Z0-9]*(_[A-Z0-9]+)*)$"/>
    </module>
    <module name="PackageName">                     <!-- lowercase, sem underscore -->
      <property name="format" value="^[a-z]+(\.[a-z][a-z0-9]*)*$"/>
    </module>

    <!-- Simplicidade -->
    <module name="MethodLength"><property name="max" value="60"/></module>
    <module name="ParameterNumber">
      <property name="max" value="7"/>
      <property name="ignoreOverriddenMethods" value="true"/>
    </module>
    <module name="CyclomaticComplexity"><property name="max" value="10"/></module>
    <module name="NestedIfDepth"><property name="max" value="2"/></module>

    <!-- Organização -->
    <module name="AvoidStarImport"/>
    <module name="UnusedImports"/>
    <module name="OneStatementPerLine"/>

    <!-- Comentários: TODO precisa de responsável -->
    <module name="TodoComment">
      <property name="format" value="TODO(?!\(\w+\))"/>
      <message key="todo.match" value="Use TODO(responsavel): descricao"/>
    </module>
  </module>
</module>
EOF

  # O pom.xml nunca é editado automaticamente: o trecho fica pronto para colar.
  write_file "config/checkstyle/pom-snippet.xml" <<'EOF'
<!-- Cole dentro de <build><plugins> no pom.xml -->
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-checkstyle-plugin</artifactId>
  <version>3.6.0</version>
  <configuration>
    <configLocation>config/checkstyle/checkstyle.xml</configLocation>
    <consoleOutput>true</consoleOutput>
    <failOnViolation>false</failOnViolation>
    <includeTestSourceDirectory>false</includeTestSourceDirectory>
  </configuration>
</plugin>
EOF
  log_info "Para rodar sem mexer no pom: mvn org.apache.maven.plugins:maven-checkstyle-plugin:3.6.0:check -Dcheckstyle.config.location=config/checkstyle/checkstyle.xml -Dcheckstyle.failOnViolation=false"
}

setup_prettier() {
  $IS_REACT || return 0
  section "Padronização: Prettier (React)"

  # Espelha o estilo que o código já usa (aspas duplas, ponto e vírgula,
  # vírgula final, linhas longas), para a primeira formatação mexer pouco.
  # endOfLine "auto": no Windows o checkout vem com CRLF (core.autocrlf) e o
  # Git já normaliza para LF no commit - "lf" acusaria todos os arquivos.
  write_file ".prettierrc.json" <<'EOF'
{
  "printWidth": 140,
  "singleQuote": false,
  "semi": true,
  "trailingComma": "all",
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "auto"
}
EOF

  write_file ".prettierignore" <<'EOF'
dist/
dev-dist/
node_modules/
coverage/
package-lock.json
EOF

  if $INSTALL && ! $DRY_RUN; then
    if command -v npm >/dev/null; then
      npm install --save-dev --save-exact prettier
      log_ok "Prettier instalado (devDependency)"
    else
      log_warn "npm não encontrado — instale com: npm i -D -E prettier"
    fi
  else
    log_info "Para instalar: npm i -D -E prettier (ou rode este script com --install). Formatar: npx prettier --write src"
  fi
}

# =============================================================================
# 5. ORGANIZAÇÃO — hooks do Git que aplicam as regras automaticamente
# =============================================================================
setup_git_hooks() {
  section "Organização: hooks do Git"

  write_file ".githooks/commit-msg" <<'EOF'
#!/usr/bin/env bash
# Mensagem de commit conforme mile_bag_audite/CONVENTIONS.md §3.
arquivo="$1"
primeira=$(grep -v '^#' "$arquivo" | sed '/^[[:space:]]*$/d' | head -n 1 | tr -d '\r')

# Mensagens geradas pelo próprio Git não seguem o padrão.
case "$primeira" in
  Merge\ *|Revert\ *|fixup!\ *|squash!\ *) exit 0 ;;
esac

tipos='feat|fix|docs|style|refactor|test|chore|perf'
# Descrição começa minúscula; uma sigla em maiúsculas no início é aceita (ex.: "PDF não quebra...").
if ! printf '%s\n' "$primeira" | grep -Eq "^(${tipos})(\([a-z0-9-]+\))?!?: ([^A-Z]|[A-Z][A-Z0-9]+[ /:,-]).*[^.]$"; then
  echo "✖ Mensagem de commit fora do padrão (CONVENTIONS.md §3)."
  echo "  Use: tipo(escopo opcional): descrição no imperativo, minúscula, sem ponto final"
  echo "  Tipos: feat, fix, docs, style, refactor, test, chore, perf"
  echo "  Ex.:   fix(rota): corrige congelamento de pedagio na viagem"
  exit 1
fi

if grep -v '^#' "$arquivo" | grep -Eiq '^Co-Authored-By:.*(claude|anthropic|copilot|chatgpt|openai|gemini)'; then
  echo "✖ Rodapé de coautoria de IA não é permitido (CONVENTIONS.md §3)."
  exit 1
fi
EOF

  write_file ".githooks/pre-commit" <<'EOF'
#!/usr/bin/env bash
# Verificações rápidas antes de cada commit (mile_bag_audite/scripts/padronizar-projeto.sh).
# Lê o conteúdo que vai para o commit (index), não o da pasta de trabalho.
falhou=0
ts_alterados=()

while IFS= read -r -d '' arquivo; do
  conteudo() { git show ":$arquivo" 2>/dev/null; }

  # Arquivo de ambiente com valores locais/secretos nunca vai para o
  # repositório (§2.3, pilar Ambiente). .env.development/.env.production do
  # Vite (só configuração pública) e os .example são permitidos.
  case "$arquivo" in
    *.example) ;;
    .env|*/.env|*.env|.env.local|*/.env.local|*.local)
      echo "✖ $arquivo: arquivo de ambiente local no commit (use um .example)."; falhou=1 ;;
  esac

  # Front-end: console.log e debugger esquecidos (testes ficam de fora).
  case "$arquivo" in
    *.test.ts|*.test.tsx|*.spec.ts|*.spec.tsx) ;;
    *.ts|*.tsx)
      if conteudo | grep -nE '(console\.log\(|^\s*debugger;?\s*$)' >/dev/null; then
        echo "✖ $arquivo: console.log ou debugger esquecido."; falhou=1
      fi
      ts_alterados+=("$arquivo") ;;
  esac

  # Print de depuração em código de produção Java: use um Logger.
  case "$arquivo" in
    */src/main/*.java|src/main/*.java)
      if conteudo | grep -nE 'System\.(out|err)\.print' >/dev/null; then
        echo "✖ $arquivo: System.out/err (use um Logger)."; falhou=1
      fi ;;
  esac

  # Segredo escrito no código. Testes ficam de fora (senhas de banco de teste
  # do Testcontainers) e a chave precisa ser a palavra inteira, para não pegar
  # ALFABETO_SENHA ou APP_PASSWORD.
  case "$arquivo" in
    */src/test/*|src/test/*|*.md|*.example) ;;
    *)
      if conteudo | grep -nEi "(^|[^A-Za-z0-9_])(password|senha|secret|api[_-]?key)[[:space:]]*[:=][[:space:]]*[\"'][^\"'\$]{4,}" >/dev/null; then
        echo "✖ $arquivo: possível segredo no código. Use variável de ambiente (§2.3)."; falhou=1
      fi ;;
  esac
done < <(git diff --cached --name-only --diff-filter=ACM -z)

# Front-end: o oxlint do próprio projeto (npm run lint) nos arquivos do commit -
# erro bloqueia, aviso não. O Prettier, se instalado, só avisa.
if (( ${#ts_alterados[@]} > 0 )) && [[ -x node_modules/.bin/oxlint ]]; then
  if ! node_modules/.bin/oxlint "${ts_alterados[@]}" >/dev/null 2>&1; then
    echo "✖ oxlint encontrou erros. Veja com: npx oxlint ${ts_alterados[*]}"; falhou=1
  fi
fi
if (( ${#ts_alterados[@]} > 0 )) && [[ -x node_modules/.bin/prettier ]]; then
  node_modules/.bin/prettier --check "${ts_alterados[@]}" >/dev/null 2>&1 \
    || echo "⚠ Arquivos fora da formatação do Prettier (rode: npx prettier --write <arquivos>)."
fi

exit $falhou
EOF

  if $DRY_RUN; then
    return
  fi
  chmod +x .githooks/commit-msg .githooks/pre-commit 2>/dev/null || true
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_warn "Não é um repositório Git — depois de 'git init', rode: git config core.hooksPath .githooks"
    return
  fi
  local atual
  atual="$(git config --get core.hooksPath || true)"
  if [[ -z "$atual" ]]; then
    git config core.hooksPath .githooks
    log_ok "Hooks ativados (git config core.hooksPath .githooks)"
  elif [[ "$atual" != ".githooks" ]]; then
    log_warn "core.hooksPath já aponta para '$atual' — mantido. Para usar estes hooks: git config core.hooksPath .githooks"
  fi
}

# =============================================================================
# AUDITORIA — só leitura; aponta onde o código foge de CONVENTIONS.md
# =============================================================================
# relatar roda no fim de pipelines (subshell): a contagem vai para um arquivo.
ARQUIVO_ACHADOS="$(mktemp)"
trap 'rm -f "$ARQUIVO_ACHADOS"' EXIT

# Imprime as linhas recebidas (até LIMITE_LISTA) ou "nenhum".
relatar() {
  local titulo="$1" saida
  saida="$(cat)"
  echo; echo "$titulo"
  if [[ -z "$saida" ]]; then
    log_ok "nenhum"
    return
  fi
  local total
  total=$(printf '%s\n' "$saida" | wc -l | tr -d ' ')
  echo "$total" >> "$ARQUIVO_ACHADOS"
  printf '%s\n' "$saida" | head -n "$LIMITE_LISTA" | sed 's/^/  /'
  if (( total > LIMITE_LISTA )); then
    echo "  … e mais $((total - LIMITE_LISTA))"
  fi
}

# Lista (NUL) os fontes de um diretório com as extensões dadas, sem build/dependências.
fontes() {
  local dir="$1"; shift
  [[ -d "$dir" ]] || return 0
  local filtro=() ext
  for ext in "$@"; do
    filtro+=(-o -name "*.$ext")
  done
  find "$dir" -type f \( "${filtro[@]:1}" \) \
    -not -path '*/node_modules/*' -not -path '*/target/*' -not -path '*/dist/*' -print0
}

arquivos_grandes() {
  fontes "$@" | xargs -0 -r wc -l 2>/dev/null | grep -v ' total$' \
    | awk -v max="$MAX_FILE_LINES" '$1 > max {printf "%5d  %s\n", $1, $2}' | sort -rn || true
}

# Filtros que não derrubam o script (set -o pipefail) quando não sobra nada.
sem() { grep -vE "$1" || true; }
so() { grep -E "$1" || true; }

# grep nos fontes, com arquivo:linha; nunca falha a execução quando não acha nada.
procurar() {
  local padrao="$1"; shift
  fontes "$@" | xargs -0 -r grep -nHE "$padrao" 2>/dev/null || true
}

auditar_java() {
  local main="src/main/java"
  [[ -d "$main" ]] || return 0
  section "Auditoria do back-end (Java)"
  log_info "$(fontes "$main" java | tr -cd '\0' | wc -c | tr -d ' ') arquivos em $main"

  arquivos_grandes "$main" java | relatar "Arquivos com mais de $MAX_FILE_LINES linhas — candidatos a dividir:"

  # §1.1: core nunca depende de business.
  { if [[ -d "$main/${PACOTE_BASE//.//}/core" ]]; then procurar "^import ${PACOTE_BASE//./\\.}\.business\." "$main/${PACOTE_BASE//.//}/core" java; fi; } \
    | relatar "core importando business (CONVENTIONS.md §1.1 — dependência só de business para core):"

  # §4.1: interface sem prefixo I.
  procurar '^\s*(public\s+)?interface\s+I[A-Z][a-z]' "$main" java \
    | relatar "Interfaces com prefixo I (CONVENTIONS.md §4.1):"

  procurar 'System\.(out|err)\.print' "$main" java | relatar "System.out/err no código de produção (use Logger):"
  procurar '^import .*\.\*;' "$main" java | relatar "Imports com *:"

  # §2.3, pilar Ambiente: endereço de ambiente fixo no código.
  procurar 'https?://(localhost|127\.0\.0\.1)' "$main" java \
    | relatar "Endereço de ambiente fixo no código Java (CONVENTIONS.md §2.3 — use application-<env>.yml):"

  procurar '\b(TODO|FIXME)\b([^(]|$)' "$main" java | relatar "TODO/FIXME sem responsável — use TODO(nome): …"

  # Linha comentada que parece instrução (termina em ; e começa como chamada,
  # atribuição ou declaração) — o texto explicativo comum não entra.
  procurar '^\s*//\s*([A-Za-z_][A-Za-z0-9_.<>]*\s+)?[A-Za-z_][A-Za-z0-9_.]*\s*(\(.*\)|=[^=].*)\s*;\s*$' "$main" java \
    | relatar "Código comentado (provável código morto — o Git guarda o histórico):"

  auditar_migracoes
}

# §2.3, pilar Versão: migrações incrementais, sem versão repetida.
auditar_migracoes() {
  local dir="src/main/resources/db/migration"
  [[ -d "$dir" ]] || return 0
  local versoes
  versoes=$(find "$dir" -maxdepth 1 -name 'V*__*.sql' -printf '%f\n' | sed -E 's/^V([0-9.]+)__.*/\1/' | sort -V)
  echo; log_info "Migrações Flyway: $(printf '%s\n' "$versoes" | grep -c .) arquivo(s), última V$(printf '%s\n' "$versoes" | tail -n 1)"
  printf '%s\n' "$versoes" | uniq -d | sed 's/^/V/' \
    | relatar "Versões de migração repetidas (CONVENTIONS.md §2.3 — cada versão é única):"
  find "$dir" -maxdepth 1 -name '*.sql' -not -name 'V*__*.sql' -not -name 'R__*.sql' -printf '%f\n' \
    | relatar "Arquivos .sql fora do padrão de nome do Flyway (V<versão>__descricao.sql):"
}

auditar_react() {
  $IS_REACT && [[ -d src ]] || return 0
  section "Auditoria do front-end (React)"
  log_info "$(fontes src ts tsx | tr -cd '\0' | wc -c | tr -d ' ') arquivos .ts/.tsx em src"

  arquivos_grandes src ts tsx | relatar "Arquivos com mais de $MAX_FILE_LINES linhas — candidatos a dividir:"

  procurar 'console\.log\(' src ts tsx | sem '\.(test|spec)\.tsx?:' \
    | relatar "console.log esquecido:"

  procurar 'https?://(localhost|127\.0\.0\.1)' src ts tsx \
    | relatar "Endereço de ambiente fixo no código (CONVENTIONS.md §2.3 — use .env.<env>):"

  auditar_imports_entre_features

  procurar '\b(TODO|FIXME)\b([^(]|$)' src ts tsx | relatar "TODO/FIXME sem responsável — use TODO(nome): …"
}

# §1.2: uma feature não importa direto de dentro de outra feature; o que é
# compartilhado sobe para shared/. Com features/<app>/<feature>/ (§1.2, último item).
auditar_imports_entre_features() {
  local base="src/features"
  [[ -d "$base" ]] || return 0
  # Um grep + um awk (resolve "./" e "../" à mão): no Windows, abrir um
  # processo por import deixava a auditoria lenta demais.
  find "$base" -type f \( -name '*.ts' -o -name '*.tsx' \) -print0 \
    | xargs -0 -r grep -nHE "from ['\"]\.\.?/" 2>/dev/null \
    | awk '
      function resolver(dir, rel,    partes, n, i, pilha, topo, k, saida) {
        n = split(dir "/" rel, partes, "/")
        topo = 0
        for (i = 1; i <= n; i++) {
          if (partes[i] == "" || partes[i] == ".") continue
          if (partes[i] == "..") { if (topo > 0) topo--; continue }
          pilha[++topo] = partes[i]
        }
        saida = ""
        for (k = 1; k <= topo; k++) saida = saida (k > 1 ? "/" : "") pilha[k]
        return saida
      }
      # "src/features/<app>/<feature>/..." -> "<app>/<feature>"; vazio para a
      # moldura da aplicação (arquivo solto em features/<app>/ ou a pasta
      # layout/), que todas as features daquela aplicação usam.
      function feature(caminho,    p, n) {
        n = split(caminho, p, "/")
        if (p[1] != "src" || p[2] != "features" || n < 5 || p[4] == "layout") return ""
        return p[3] "/" p[4]
      }
      {
        arquivo = $0; sub(/:[0-9]+:.*/, "", arquivo)
        linha = $0
        if (!match(linha, /from ["\x27]\.\.?\/[^"\x27]+["\x27]/)) next
        importado = substr(linha, RSTART + 6, RLENGTH - 7)
        dir = arquivo; sub(/\/[^\/]+$/, "", dir)
        origem = feature(arquivo)
        destino = feature(resolver(dir, importado))
        if (origem != "" && destino != "" && origem != destino) print arquivo ": importa de " destino
      }' \
    | sort -u \
    | relatar "Feature importando de outra feature (CONVENTIONS.md §1.2 — mova o compartilhado para shared/):"
}

# §3: mensagens recentes fora do padrão e coautoria de IA.
auditar_commits() {
  git rev-parse --git-dir >/dev/null 2>&1 || return 0
  section "Auditoria dos commits recentes (CONVENTIONS.md §3)"
  git log --no-merges -50 --format='%h %s' 2>/dev/null \
    | sem "^[0-9a-f]+ (${TIPOS_COMMIT})(\([a-z0-9-]+\))?!?: ([^A-Z]|[A-Z][A-Z0-9]+[ /:,-]).*[^.]$" \
    | relatar "Mensagens fora do padrão entre os 50 últimos commits:"
  git log -50 --format='%h %(trailers:key=Co-authored-by,valueonly,separator=%x2C )' 2>/dev/null \
    | so ' .*([Cc]laude|[Aa]nthropic|[Cc]opilot|[Cc]hat[Gg][Pp][Tt]|[Oo]pen[Aa][Ii]|[Gg]emini)' \
    | relatar "Commits com rodapé de coautoria de IA (não permitido):"
}

run_audit() {
  : > "$ARQUIVO_ACHADOS"
  auditar_java
  auditar_react
  auditar_commits
  local achados
  achados=$(awk '{ soma += $1 } END { print soma + 0 }' "$ARQUIVO_ACHADOS")
  echo
  if (( achados == 0 )); then
    log_ok "Auditoria sem achados."
  else
    log_warn "Auditoria: $achados achado(s). São avisos para revisão, não erros."
  fi
}

# =============================================================================
# Execução
# =============================================================================
echo "${C_INFO}Padronizando projeto em:${C_RESET} $PROJECT_DIR"
echo "  Maven (Java):  $($IS_MAVEN && echo sim || echo não)"
echo "  React:         $($IS_REACT && echo sim || echo não)"
$DRY_RUN && log_warn "Modo dry-run: nada será gravado"

if ! $AUDIT_ONLY; then
  setup_editorconfig
  setup_gitattributes
  setup_gitignore
  setup_checkstyle
  setup_prettier
  setup_git_hooks
fi

run_audit

section "Pronto"
echo "Convenções: mile_bag_audite/CONVENTIONS.md (fonte única — este script não cria cópias)."
if ! $AUDIT_ONLY && ! $DRY_RUN; then
  echo "Próximos passos:"
  echo "  1. Revise o que foi criado: git status"
  $IS_MAVEN && echo "  2. Opcional: cole config/checkstyle/pom-snippet.xml no pom.xml"
  $IS_REACT && echo "  2. Opcional: npm i -D -E prettier && npx prettier --write src (revise o diff antes do commit)"
  echo "  3. Commit numa branch chore/ e PR (CONVENTIONS.md §5): chore: padroniza configuracao do projeto"
fi
