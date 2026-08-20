# Constituição do Projeto — mile_bag_audite

Este documento é a carta fundamental do projeto: define missão, princípios,
escopo e regras de governança. Diferente de `CONVENTIONS.md` (que trata de
padrões técnicos de código), este documento trata do **porquê** e dos
**limites** do projeto. Mudanças aqui têm peso maior e exigem revisão
cuidadosa.

## 1. Missão

Desenvolver o **Milebag**, sistema web em modelo SaaS multi-tenant para a
gestão da última milha da devolução de bagagens extraviadas no transporte
aéreo brasileiro — do momento em que a companhia aérea libera a bagagem
irregular (BDO) até a entrega comprovada ao passageiro e o fechamento
financeiro do motorista —, ligando em um único registro auditável o
documento da companhia aérea, o percurso realizado, a prova de entrega e o
valor pago, o que hoje é feito manualmente em planilhas e mensagens.

Este repositório (`mile_bag_audite`) não é um produto à parte: é onde vivem
a constituição e as convenções técnicas **compartilhadas** por todos os
repositórios do projeto Milebag (`mile_bag_api`, `mile_bag_app`,
`mile_bag_infra`, `mile_bag_documentacao`). O nome "audite" reflete o
princípio 2 abaixo — auditabilidade —, que continua central ao Milebag:
rota congelada no início da viagem, comprovante de entrega geolocalizado e
histórico de ocorrências são, na prática, a trilha de auditoria do
processo de devolução de bagagem.

> Ver `mile_bag_documentacao/evidencias/Projeto_de_software_-_ADS_com_TAP.md`
> para a descrição completa do problema, dos objetivos e do escopo do
> projeto (o Termo de Abertura do Projeto — TAP).

## 2. Princípios

1. **Confiabilidade dos dados acima de tudo.** Toda informação usada no
   cálculo do pagamento (quilometragem, pedágio, tempo) deve ser
   congelada no início da viagem e nunca alterada por uma consulta
   posterior; nenhuma alteração silenciosa em dado já congelado é aceitável.
2. **Auditabilidade do próprio sistema.** Toda entrega deve manter uma
   trilha rastreável desde o BDO capturado até o comprovante de entrega
   ou a ocorrência que a reabriu — quem, o quê, quando — para sustentar a
   prestação de contas à companhia aérea contratante.
3. **Simplicidade antes de generalidade.** Resolver o problema real da
   devolução de bagagem irregular primeiro; evitar abstrações
   especulativas para casos de uso hipotéticos.
4. **Segurança e privacidade por padrão.** Dados pessoais do passageiro e
   de identificação de motoristas/usuários são sensíveis; tratados com o
   mínimo de exposição necessário e em conformidade com a LGPD. O
   isolamento de dados entre tenants é responsabilidade explícita da
   camada de dados e de autenticação, verificado por testes automatizados.
5. **Transparência nas decisões.** Mudanças de escopo, arquitetura ou
   regras de negócio relevantes são documentadas, não apenas implementadas.

## 3. Escopo

**Dentro do escopo:**
- Cadastro de empresas assinantes (tenants), planos, assinaturas e usuários,
  com provisionamento sem implantação dedicada.
- Captura do BDO por fotografia, com extração automática dos campos por
  OCR e conferência assistida obrigatória.
- Autoatribuição da entrega pelo motorista, cálculo de rota (com escolha
  de alternativa ou rota própria) e congelamento (snapshot) da rota como
  base do pagamento.
- Tratamento de bagagem carona (quilometragem complementar) e registro de
  ocorrências padronizadas, com reabertura do BDO.
- Registro do comprovante de entrega (POD) com foto, recebedor, data,
  hora e geolocalização.
- Motor de tarifas parametrizável por tenant/motorista/região, cadastro
  de praças de pedágio e fechamento financeiro periódico (entregas e
  pedágios apurados separadamente).
- Operação offline da aplicação do motorista, com sincronização
  automática ao restabelecer a conexão.

**Fora do escopo (por ora):**
- Integração eletrônica direta com os sistemas das companhias aéreas — o
  BDO continua sendo capturado por fotografia do documento impresso.
- Emissão de documentos fiscais e cobrança automática das assinaturas por
  gateway de pagamento.
- Roteirização automática com otimização de múltiplas paradas.
- Aplicativo destinado ao passageiro final.
- Tratamento de indenizações por extravio definitivo e demais etapas
  anteriores da cadeia (check-in, manuseio em solo, localização da
  bagagem pela companhia aérea) — fora do recorte operacional do TAP.

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
- A autoria dos commits é sempre humana; commits não incluem rodapé de
  coautoria de IA (ex: `Co-Authored-By: Claude`).

---

## Histórico de revisões

- **2026-08-20** — Missão e Escopo reescritos para descrever o produto
  Milebag (gestão da última milha de devolução de bagagens extraviadas,
  conforme o TAP em `mile_bag_documentacao/evidencias/`), substituindo a
  descrição original ("auditar bagagens vinculadas a programas de
  milhas/viagem"), anterior ao pivô do projeto e já desalinhada da
  documentação de requisitos, HUs e specs produzida desde então. Os
  Princípios e a seção de Governança não mudaram de sentido — só foram
  reformulados para citar exemplos concretos do domínio atual em vez de
  termos genéricos de "auditoria".

---

*Esta constituição deve ser revisada quando o entendimento da missão ou do
escopo do projeto mudar de forma relevante — não a cada sprint.*
