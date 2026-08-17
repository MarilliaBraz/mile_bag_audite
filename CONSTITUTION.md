# Constituição do Projeto — mile_bag_audite

Este documento é a carta fundamental do projeto: define missão, princípios,
escopo e regras de governança. Diferente de `CONVENTIONS.md` (que trata de
padrões técnicos de código), este documento trata do **porquê** e dos
**limites** do projeto. Mudanças aqui têm peso maior e exigem revisão
cuidadosa.

## 1. Missão

Auditar bagagens (malas) vinculadas a programas de milhas/viagem, garantindo
conferência, validação e controle confiável dos itens e informações
associadas — reduzindo divergências, fraudes ou erros no processo de
auditoria.

## 2. Princípios

1. **Confiabilidade dos dados acima de tudo.** Toda informação de auditoria
   deve ser rastreável e verificável; nenhuma alteração silenciosa em dados
   de auditoria é aceitável.
2. **Auditabilidade do próprio sistema.** Toda ação relevante (quem, o quê,
   quando) deve ficar registrada — o sistema que audita também deve ser
   auditável.
3. **Simplicidade antes de generalidade.** Resolver o problema real de
   auditoria de bagagem/milhas primeiro; evitar abstrações especulativas
   para casos de uso hipotéticos.
4. **Segurança e privacidade por padrão.** Dados de viagem e identificação
   de usuários são sensíveis; tratados com o mínimo de exposição necessário.
5. **Transparência nas decisões.** Mudanças de escopo, arquitetura ou regras
   de negócio relevantes são documentadas, não apenas implementadas.

## 3. Escopo

**Dentro do escopo:**
- Registro e conferência de bagagens associadas a programas de milhas.
- Validação de regras de negócio (limites, elegibilidade, consistência).
- Trilhas de auditoria (logs/histórico) das operações realizadas.
- Relatórios e consultas sobre o estado das auditorias.

**Fora do escopo (por ora):**
- Emissão ou gestão direta de milhas (integra-se com sistemas de milhas,
  não os substitui).
- Funcionalidades não relacionadas a bagagem/auditoria (ex: reservas,
  pagamentos), a menos que decidido explicitamente em revisão futura deste
  documento.

## 4. Governança e decisões

- Mudanças em **CONVENTIONS.md** (padrões técnicos) podem ser propostas e
  aprovadas via Pull Request normal.
- Mudanças neste documento (**CONSTITUTION.md** — missão, princípios,
  escopo) exigem:
  1. Um PR dedicado, explicando o motivo da mudança.
  2. Justificativa explícita de por que a mudança está alinhada (ou
     conscientemente altera) a missão do projeto.
- Em caso de conflito entre uma convenção técnica e um princípio deste
  documento, o princípio prevalece.

---

*Esta constituição deve ser revisada quando o entendimento da missão ou do
escopo do projeto mudar de forma relevante — não a cada sprint.*
