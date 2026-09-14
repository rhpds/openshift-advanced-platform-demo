# Roteiro executável: "Como turbinar sua Engenharia de Plataforma com IA"

Demonstração gravada. Instância `cluster-ql7cw` com as camadas opcionais instaladas (`post-provision.sh` com `WITH_RHCL=1 WITH_RHDH_PLUGINS=1 WITH_OBSERVABILITY=1 WITH_KIALI_PLUGIN=1`).
Personas: **Tanaka Developer** (`tanaka-dev`) e **Tanaka Platform Engineer** (`tanaka-pe`), senha comum do demo.
Mensagem: *Platform Engineering reduz a complexidade com self-service e Golden Paths; a IA torna a plataforma mais fácil de descobrir, entender, usar e estender.*

Duração estimada: **35 min** com Connectivity Link, **38 min** com Kafka no lugar (Ato 5: pedido 3 min, aprovação 3 min, uso 5 min, mais esperas de Argo cortadas na edição). Ensaiar com cronômetro antes de gravar.

## Antes de gravar (D-1 e no dia)

| Quando | O quê | Comando / onde |
|---|---|---|
| D-1 | Congelar: nenhum script de camada, nenhuma política RHCL, nenhum restart | |
| D-1 | Se o cluster foi reiniciado: fix-ups | `bash scripts/post-provision.sh` (sem flags) |
| Dia | Validar tudo | `WITH_RHCL=1 WITH_RHDH_PLUGINS=1 WITH_OBSERVABILITY=1 WITH_KIALI_PLUGIN=1 bash scripts/validate-instance.sh` (0 falhas) |
| Dia | Walk das personas no RHDH | `RHDH_USER=tanaka-dev RHDH_PASS=… node ~/.claude/skills/browser-automation/browser.mjs https://backstage-developer-hub-rhdh.<domínio>/ --script scripts/rhdh-kuadrant/walk-rhdh.mjs` (idem `tanaka-pe`) |
| Dia | Template de IA fora do catálogo (etapa 7 registra ao vivo) | `oc exec` no RHDH: `GET /api/catalog/entities/by-name/template/default/request-postgresql-database` deve dar 404 |
| Dia | Lightspeed do RHDH aquecido: fazer a pergunta da etapa 1 uma vez como tanaka-dev | histórico "Recent" com a resposta |
| Dia | Claude Code do apresentador ligado ao MCP governado | `claude mcp add --transport http --scope user rhdh-platform https://mcp-developer-hub.<domínio>/api/mcp-actions/v1 --header "X-API-Key: <platform-key-demo>"`; `claude mcp list` deve mostrar conectado |
| Dia | Um Chrome com a extensão do Claude, uma aba no RHDH logada na persona do ato (troca por Sign out / Sign In entre atos) | zoom 110%, sem abas extras, sem notificações |

Chaves: `oc get secret platform-key-demo -n kuadrant-system -o jsonpath='{.data.api_key}' | base64 -d`. Nunca mostrar na tela.

## Gravação em atos

A gravação é feita em quatro atos independentes, um por sessão de persona, executados pelo Cowork; os prompts e os resets estão em `webinar/cowork-prompts.md`. Ato 1 (descobrir, entender, Golden Path, primeiro commit) e Ato 1b (resultado, pedido de chave) como tanaka-dev. Ato 2: tanaka-pe (aprovação). Ato 3: tanaka-dev (chave e limite). Ato 4: tanaka-pe (agente cria o Golden Path). Ato 5 (a, b, c): Kafka como segundo Golden Path com aprovação por merge request; substitui os Atos 1b passo 2, 2 e 3 (Connectivity Link), que ficam como alternativa para públicos que conhecem RHCL. Sign out/Sign In entre atos, fora da gravação; validado que o Sign out do RHDH encerra a sessão SSO do Keycloak.

## Etapas

### 0. Abertura (3 min, fala, sobre a tela inicial do Developer Hub)
**Por que engenharia de plataforma.** "Pense no primeiro dia da Tanaka no time. Para entregar uma feature ela precisa de repositório, pipeline, imagem, deploy, banco, fila, chave de API, dashboards. Em muitas empresas isso são oito ferramentas, cinco tickets e duas semanas. Engenharia de plataforma existe para virar esse jogo: o time de plataforma trata a infraestrutura como produto, com clientes internos, e entrega Golden Paths, caminhos prontos e padronizados que um desenvolvedor usa em self-service. O dev recebe o padrão sem precisar entender cada peça; a plataforma garante segurança, observabilidade e governança por padrão, não por auditoria depois. O que vocês vão ver tem esse desenho: tudo que a Tanaka faz hoje passa por um portal, o Red Hat Developer Hub, e por Golden Paths que a plataforma publicou."

**Onde entra a IA.** "Mas uma plataforma só reduz carga cognitiva se o desenvolvedor consegue descobrir e entender o que ela oferece. É aqui que a IA entra, e entra de duas formas. Para o desenvolvedor, o Developer Lightspeed é o assistente dentro do portal: ele conhece este catálogo, estes templates e esta documentação, e responde a partir deles. Para o time de plataforma, um agente de IA usa as mesmas interfaces para estender a plataforma, criando um novo Golden Path a partir dos que já existem. A IA não substitui a plataforma; ela a torna descobrível, compreensível e mais rápida de evoluir. Vamos acompanhar a Tanaka em duas funções: desenvolvedora e engenheira de plataforma."

### 1. Descobrir com IA contextual (5 min)
- Estado inicial: RHDH como tanaka-dev, **Developer Lightspeed** aberto na tela inicial (saudação, três cards, seletor de modelo `qwen3-14b`).
- **Fala de contextualização (45 s, sobre a tela inicial, antes de clicar):**
  "Este é o Red Hat Developer Lightspeed, o assistente de IA embutido no Developer Hub. Três coisas importam aqui. Primeira: ele roda dentro da plataforma, ao lado do portal, e usa o modelo que a organização escolheu; aqui é um Qwen servido pela nossa própria infraestrutura de modelos, então nada do que o desenvolvedor pergunta sai para um serviço externo. Segunda: ele não responde de memória; antes de responder, consulta o próprio Developer Hub por MCP, o Model Context Protocol: o catálogo de serviços, os templates e a documentação desta instância. Por isso a resposta cita o serviço e o template que existem aqui, com os nomes certos. Terceira: os cards de sugestão são configurados pela plataforma; a equipe de plataforma decide quais perguntas guiam um desenvolvedor novo. É a IA como porta de entrada da plataforma, não como substituto dela."
- Ação: clicar no card **"Começar uma nova feature"** (o mais rápido). Opcional: **"Conhecer o Parasol Insurance"**.
- Resultado esperado: resposta em 40 a 70 s citando o template *Onboarding features on Parasol Insurance application*, o parâmetro `branch` e o que ele cria (branch, GitOps, Argo CD, componente no catálogo).
- Evidência: a resposta cita nomes que existem neste catálogo (Lightspeed usa as tools MCP do próprio RHDH).
- Fala durante a espera: "a resposta vem do catálogo desta instância, não da internet".
- Contingência: a mesma pergunta já respondida em **Recent**; cortar a espera na edição.

### 2. Entender pelo catálogo (5 min)
- Ação: Catalog → `parasol-insurance`. Percorrer Overview (owner, system, links), **Dependencies** (Kafka, banco), **API**, **CI**, **CD**, **Topology**, **Service Mesh**.
- Resultado esperado: todas as abas com dados; links Grafana/Kiali/Quay/Sonar/ACS/TPA.
- Fala: "tudo que o dev precisaria descobrir em dez ferramentas está aqui, com dono e estado".
- Contingência: se uma aba demorar, seguir; nenhuma aba depende de ação.

### 3. Golden Path (4 min)
- Ação: **Self-service** → *Onboarding features on Parasol Insurance application* → **Choose** → Branch Name `claims-ai` (qualquer nome novo, minúsculas e hífen) → Review → Create.
- Resultado esperado: 5 passos verdes em ~12 s, botão **Open in catalog**.
- Fala: "um campo; a plataforma criou branch, repositório GitOps, apps Argo, namespace, pipeline e o componente no catálogo".
- Atenção: o template usa um namespace por usuário (`parasol-insurance-secured-tanaka-dev`); antes de gravar de novo, `bash webinar/reset-tanaka-dev.sh tanaka-dev <branch>`.
- Contingência: se falhar (raro), rodar o reset e repetir.
- Nota: a pipeline só roda no primeiro push depois do bootstrap (~1 min após o template). Fazer um commit pelo GitLab web (`docs/nota.md` na branch) se quiser mostrar o gatilho; a pipeline leva 5 min.

### 4. Observar o resultado (6 min)
- Estado inicial: componente criado na etapa 3 (`parasol-insurance-secured-tanaka-dev-claims-ai`) com a pipeline concluída (gravado depois, mesma sessão).
- Ação: abas **CI** (PipelineRun Succeeded, contagem de vulnerabilidades), **CD** (Argo Synced/Healthy, 34 recursos), **Topology**, **Image Registry** (imagem assinada em `parasol/parasol-insurance-secured-tanaka-dev`), **Service Mesh**; link **Grafana: Parasol Platform Overview (this namespace)**.
- Fala: "o dev não configurou Tekton, Argo, Quay, ACS, SBOM nem mesh; recebeu tudo por padrão e vê tudo no mesmo lugar".
- Contingência: se a pipeline da etapa 3 já terminou, usar o componente novo; senão, o pronto.

### 5. Governança sem carga cognitiva (5 min)
- Ação como tanaka-dev: **Connectivity Link → API Products** → *Parasol Insurance Claims API* → **My API Keys → Request Access** (silver). Como tanaka-pe: **API Key Approval → Approve**. Voltar: chave **Active**.
- Terminal: `curl -sk -o /dev/null -w '%{http_code}\n' -H "Authorization: APIKEY <chave>" https://parasol-api-parasol-insurance-prod.<domínio>/api/claims` → `200`; 12 chamadas rápidas → `429`.
- Fala: "padrão da plataforma: chave, plano e limite no gateway; o dev não sabe o que é Authorino ou Limitador e não precisa".
- Contingência: chave `partner1` já existente; não alterar políticas (o gateway reinicia).

### 6. (cortada) OpenShift Lightspeed
Fora do escopo do webinar. Script mantido em `scripts/ai/openshift-lightspeed.sh` para outra ocasião.

### 7. PE + IA: o agente cria um Golden Path (7 min)
- Estado inicial: terminal com Claude Code conectado ao MCP governado; RHDH como tanaka-pe em **Self-service** (sem o template PostgreSQL).
- Ação: pedir ao agente: *"Usando as tools do Developer Hub, veja como o template request-kafka-topic é feito e crie um Golden Path 'Request PostgreSQL Database' com o mesmo fluxo de aprovação. Publique no branch ai-golden-path-postgresql do repositório rhdh/rhdh-templates e registre o template no catálogo."*
- Resultado esperado: o agente lê os templates via `fetch-template-metadata`, escreve os arquivos, faz push e chama `register-catalog-entities`; ao recarregar **Self-service** aparece **Request PostgreSQL Database**.
- Fala: "o PE descreve o padrão; o agente aprende com os Golden Paths existentes e publica um novo; a chamada passou pelo gateway com chave e limite, como qualquer cliente".
- Contingência (branch e MR !1 já existem em `rhdh/rhdh-templates`): registrar em 20 s
  ```
  curl -sk -X POST https://mcp-developer-hub.<domínio>/api/mcp-actions/v1 -H "X-API-Key: <platform-key-demo>" \
    -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"register-catalog-entities","arguments":{"locationURL":"https://gitlab-gitlab.<domínio>/rhdh/rhdh-templates/-/blob/ai-golden-path-postgresql/templates/request-postgresql-database/template.yaml"}}}'
  ```
  ou **Bulk import → Add** com a mesma URL. Depois da gravação, desregistrar pela tool `unregister-catalog-entities` (`type.locationId`) ou pela página da Location no catálogo.

### 8. Fechamento (2 min, fala)
"Recapitulando pelo que a Tanaka fez: descobriu com o Lightspeed, entendeu pelo catálogo, usou um Golden Path, observou o resultado, pediu um tópico Kafka aprovado pela plataforma e viu a feature consumindo. Ela não abriu ticket, não escreveu YAML de pipeline, não configurou Argo, Quay, ACS nem mesh. Isso é engenharia de plataforma: o padrão vem pronto e a governança está embutida. E a IA teve dois papéis: o Lightspeed, que fez o portal responder em linguagem natural a partir do próprio catálogo, e o agente que criou um novo Golden Path a partir dos existentes. Plataforma reduz a complexidade; IA reduz a distância entre o desenvolvedor e a plataforma. Comecem pela plataforma: sem catálogo, templates e documentação, a IA não tem em que se ancorar."

## Pontos frágeis e recuperação

| Sintoma | Causa | Recuperação |
|---|---|---|
| Lightspeed "Loading" por mais de 90 s | MaaS lento | usar histórico Recent; cortar na edição |
| RHDH login 500 após restart do cluster | RHDH subiu antes do Keycloak | `oc rollout restart deployment/backstage-developer-hub -n rhdh` (4 min) |
| Parasol 503 | app crash-loop após restart | `bash scripts/post-provision.sh` |
| API responde 503 em vez de 429 | gateway reiniciando após mudança de política | esperar 60 s; não mudar políticas |
| Template falha em "Publish to GitLab" | GitLab indisponível | esperar; usar componente pronto |
| Aba CD vazia | Argo demorou | recarregar após 10 s |
| Etapa 7: agente não conecta ao MCP | chave ou TLS | contingência curl/Bulk import |
