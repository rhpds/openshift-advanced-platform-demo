> Superseded: os roteiros definitivos de gravação estão em `recording-takes.md` (takes T01 a T09c e A01 a A03). Este arquivo fica como histórico dos atos.

# Atos da gravação: roteiros individuais para o Cowork

Cada ato é autocontido: tem pré-condição, persona, passos com URL direta, critério de "pronto" e contingência. Grave um ato por vez; a troca de persona (Sign out → Sign In) acontece fora da gravação, feita por você. Cole no Cowork apenas o bloco **Prompt** do ato.

Domínio da instância: `apps.cluster-ql7cw.dyn.redhatworkshops.io` (abreviado `<domínio>` nas URLs abaixo; substituir se a instância mudar).
RHDH: `https://backstage-developer-hub-rhdh.<domínio>`

Regras comuns a todos os atos (já embutidas nos prompts):
- Nunca clicar em **Sign In** nem em **Sign out**. Se a página pedir login, parar e avisar.
- Antes de qualquer ação, confirmar o nome no canto superior direito (a persona do ato).
- Nunca digitar, colar ou ler em voz alta chaves, tokens ou senhas. Onde um valor secreto é necessário, ele já está no ambiente (variável ou arquivo indicado).
- Navegar por URL direta; esperar o conteúdo aparecer antes de seguir; não abrir outras abas.

---

## Ato 1 · Tanaka Developer descobre, entende e usa a plataforma

**Destaque de IA (desenvolvedor)**: passo 1, o Lightspeed indica o Golden Path a partir do catálogo; passo 3 executa exatamente esse template.

**Pré-condição**: `bash webinar/reset-tanaka-dev.sh tanaka-dev <branch-anterior>` executado (a persona não pode ter uma feature ativa: o template usa um namespace por usuário). Chrome com a extensão do Claude, uma aba no RHDH logada como **Tanaka Developer** e o GitLab (`https://gitlab-gitlab.<domínio>`) também logado como `tanaka-dev` na mesma janela; Lightspeed com a pergunta do passo 1 já respondida uma vez hoje (aquecimento). Duração alvo: 11 min.

**Prompt**

```
Você vai executar uma demonstração gravada no Red Hat Developer Hub (RHDH) no papel de Tanaka Developer. Faça exatamente os passos abaixo, na ordem, com calma (pausa de 2 segundos entre cliques). Nunca clique em "Sign In" ou "Sign out". Se aparecer uma tela de login, pare e me avise. Antes de começar, confirme que o canto superior direito mostra "Tanaka Developer".

1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/lightspeed
   Aguarde a tela inicial carregar (saudação "Hello, Tanaka Developer", três cards e o seletor de modelo no canto superior direito). Fique parado nesta tela por 45 segundos sem mover o mouse (narração sobre o Lightspeed). Depois clique no card "Começar uma nova feature". Aguarde até a resposta terminar (o texto para de mudar e o indicador de carregamento some; pode levar até 90 segundos). Não faça mais nada enquanto carrega. Quando terminar, role a resposta devagar até o fim.

2. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/component/parasol-insurance
   Aguarde a página carregar. Role devagar até "Links" e pare 3 segundos. Depois abra, nesta ordem, esperando cada uma carregar por completo (5 a 10 segundos) e pausando 3 segundos em cada:
   - aba "Dependencies"
   - aba "API"
   - aba "CI"
   - aba "CD"
   - aba "Topology"
   - aba "Service Mesh" (esta demora até 15 segundos)

3. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/create/templates/default/parasol-insurance-secured-dev
   No campo "Branch Name" digite: claims-ai
   Clique em "Review". Pause 3 segundos. Clique em "Create".
   Aguarde os cinco passos ficarem verdes (cerca de 15 segundos). Pause 3 segundos. Clique em "Open in catalog" e pause 5 segundos na página do novo componente (parasol-insurance-secured-tanaka-dev-claims-ai).

4. Na página do componente, em "Links", clique em "View Source" (abre o GitLab na branch claims-ai). Aguarde 60 segundos nessa página (a plataforma ainda está criando a pipeline da branch). Depois clique em "Add to tree" (botão "+") → "New file", nome do arquivo: docs/claims-ai.md, conteúdo: "# Claims AI\n\nPrimeira alteração da feature." e confirme o commit na branch claims-ai (botão "Commit changes"). Se o GitLab pedir login, pare e me avise.

5. Volte para https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/component/parasol-insurance-secured-tanaka-dev-claims-ai/ci
   Aguarde até 40 segundos e recarregue uma vez: deve aparecer um Pipeline Run em execução. Pause 5 segundos.

Ao terminar, diga "Ato 1 concluído" e liste qualquer passo que não tenha funcionado como descrito.
```

**Pronto quando**: Pipeline Run em execução na aba CI do componente novo. A pipeline leva 5 min; o Ato 1b começa depois que ela termina (não precisa de logout).
**Contingência**: passo 1 lento → chat em "Recent"; passo 3 falhar → parar, rodar o reset e repetir; passo 4 sem login no GitLab → você faz o commit pelo GitLab (ou `git push` de um arquivo) e o agente segue no passo 5.

---

## Ato 1b · Tanaka Developer observa o resultado e pede acesso à API

**Pré-condição**: mesma sessão do Ato 1; pipeline do componente `parasol-insurance-secured-tanaka-dev-claims-ai` concluída (aba CI: Succeeded). Duração alvo: 7 min.

**Prompt**

```
Você continua como Tanaka Developer no Red Hat Developer Hub. Nunca clique em "Sign In" ou "Sign out". Confirme "Tanaka Developer" no canto superior direito.

1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/component/parasol-insurance-secured-tanaka-dev-claims-ai
   Abra as abas nesta ordem, esperando carregar (5 a 15 segundos) e pausando 3 segundos em cada: "CI" (Pipeline Run Succeeded), "CD" (Synced, Healthy), "Topology", "Image Registry", "Service Mesh".
   Volte para "Overview", role até "Links" e clique em "Grafana: Parasol Platform Overview (this namespace)". Aguarde o painel carregar (10 segundos), role até o fim devagar e volte para a aba do RHDH.

2. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/api-products
   Clique em "Parasol Insurance Claims API". Pause 3 segundos na visão geral e abra a aba "Policies". Pause 3 segundos.
   Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/my-api-keys
   Clique em "Request Access". Selecione a API "Parasol Insurance Claims API" e o tier "silver". No campo de caso de uso escreva: "Integração do portal de sinistros da corretora". Aceite os termos e clique em "Request". Confirme que o pedido aparece com estado pendente.

Ao terminar, diga "Ato 1b concluído".
```

**Pronto quando**: pedido de chave pendente. **Contingência**: aba CD vazia → recarregar após 10 s; sem "Request Access" → recarregar.

---

## Ato 2 · Tanaka Platform Engineer aprova o acesso

**Pré-condição**: Sign out do ato anterior, Sign In como **Tanaka Platform Engineer** (feito por você). Duração alvo: 2 min.

**Prompt**

```
Você vai executar uma demonstração gravada no Red Hat Developer Hub no papel de Tanaka Platform Engineer. Nunca clique em "Sign In" ou "Sign out". Confirme que o canto superior direito mostra "Tanaka Platform Engineer" antes de começar.

1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/api-key-approval
   Aguarde a lista carregar. Localize o pedido de "Tanaka Developer" para "Parasol Insurance Claims API", tier silver. Pause 3 segundos sobre ele.
2. Clique em "Approve" nesse pedido e confirme se for pedido. Aguarde o estado mudar para aprovado. Pause 3 segundos.
3. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/api-products e clique em "Parasol Insurance Claims API", aba "Policies". Pause 5 segundos mostrando a AuthPolicy, a RateLimitPolicy e a PlanPolicy.

Ao terminar, diga "Ato 2 concluído".
```

**Pronto quando**: pedido aprovado. **Contingência**: sem pedido na lista → recarregar; se ainda assim não aparecer, o pedido do Ato 1 não foi criado; usar o pedido já aprovado de dev1 como exemplo na tela.

---

## Ato 3 · Tanaka Developer usa a chave e encontra o limite

**Pré-condição**: Sign out, Sign In como **Tanaka Developer**. A chave aprovada no Ato 2 está em My API Keys. Se o Cowork não executa comandos, pular o passo 2 e usar o Postman (pastas 3 e 4 da coleção em `tests/postman/`) ou o painel do Grafana. Duração alvo: 4 min.

**Prompt**

```
Você vai executar uma demonstração gravada no papel de Tanaka Developer. Nunca clique em "Sign In" ou "Sign out". Confirme "Tanaka Developer" no canto superior direito.

1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/my-api-keys
   Recarregue a página uma vez. Confirme que a chave da "Parasol Insurance Claims API" está "Active". Pause 3 segundos. Clique no botão de copiar a chave (não a mostre nem a leia em voz alta).

2. Em um terminal, execute, substituindo <chave> pela chave copiada (não exibir o valor):
   curl -sk -o /dev/null -w 'sem chave: HTTP %{http_code}\n' https://parasol-api-parasol-insurance-prod.apps.cluster-ql7cw.dyn.redhatworkshops.io/api/claims
   curl -sk -o /dev/null -w 'com chave: HTTP %{http_code}\n' -H "Authorization: APIKEY <chave>" https://parasol-api-parasol-insurance-prod.apps.cluster-ql7cw.dyn.redhatworkshops.io/api/claims
   for i in $(seq 1 12); do curl -sk -o /dev/null -w '%{http_code} ' -H "Authorization: APIKEY <chave>" https://parasol-api-parasol-insurance-prod.apps.cluster-ql7cw.dyn.redhatworkshops.io/api/claims; done; echo
   Resultado esperado: 401, depois 200, depois dez 200 seguidos de 429.

3. Abra https://grafana-route-observability.apps.cluster-ql7cw.dyn.redhatworkshops.io/d/parasol-rhcl/connectivity-link-parasol-api-and-llm-gateway?orgId=1&from=now-15m&to=now
   Aguarde 10 segundos e pause sobre o painel "Responses by code and destination", onde aparecem os 401, 200 e 429 de agora.

Ao terminar, diga "Ato 3 concluído" e informe os códigos HTTP obtidos.
```

**Pronto quando**: 401 / 200 / 429 exibidos. **Contingência**: sem terminal → Postman desktop, environment "Parasol demo instance" com `partner_api_key` preenchida, Runner na pasta "4. Connectivity Link: rate limit" com 14 iterações; ou só o painel do Grafana com o tráfego da validação do dia.

---

## Ato 4 · Tanaka Platform Engineer estende a plataforma com um agente

**Destaque de IA (engenheiro de plataforma)**: o agente lê os Golden Paths existentes pelo MCP do Developer Hub, escreve um novo e o registra pelo mesmo endpoint governado.

**Pré-condição**: Sign out, Sign In como **Tanaka Platform Engineer**. Terminal com Claude Code conectado ao MCP governado do RHDH (`claude mcp list` mostra `rhdh-platform` conectado) e um clone local de `rhdh/rhdh-templates` com credencial de push. O template "Request PostgreSQL Database" não está no catálogo (Self-service mostra 5 templates). Duração alvo: 8 min.

**Prompt (para o Claude Code no terminal, gravado na tela)**

```
Usando as tools do Developer Hub (fetch-template-metadata), estude como o template request-kafka-topic é construído: parâmetros, passos e o fluxo de merge request para aprovação da plataforma. Crie um novo Golden Path "Request PostgreSQL Database" com o mesmo padrão (mesmo repositório de destino do MR, mesmos revisores, um Resource no catálogo, storage escolhido por ambiente). Escreva os arquivos em templates/request-postgresql-database/ neste clone, faça commit no branch ai-golden-path-postgresql, faça push e abra o merge request. Em seguida registre o template no catálogo com a tool register-catalog-entities usando a URL do template.yaml nesse branch. Me diga a URL do merge request e confirme o registro.
```

**Prompt (para o Cowork no navegador, depois que o agente confirmar o registro)**

```
Você está no Red Hat Developer Hub como Tanaka Platform Engineer. Nunca clique em "Sign In" ou "Sign out".
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/create
   Recarregue a página. Localize o card "Request PostgreSQL Database". Pause 3 segundos sobre ele e clique em "Choose".
2. Preencha: Database Name "claims-db", Owning Team "devteam1", Target Namespace "parasol-insurance-secured-tanaka-dev", Storage "5 GiB (development)". Clique em "Review" e pause 5 segundos. Não clique em "Create".
3. Abra https://gitlab-gitlab.apps.cluster-ql7cw.dyn.redhatworkshops.io/rhdh/rhdh-templates/-/merge_requests e pause 5 segundos sobre o merge request "Golden Path: Request PostgreSQL Database".
Ao terminar, diga "Ato 4 concluído".
```

**Pronto quando**: o card aparece no Self-service e o MR existe.
**Contingência** (branch `ai-golden-path-postgresql` e MR !1 já existem): registrar em 20 s pelo RHDH em **Bulk import → Add** com a URL
`https://gitlab-gitlab.<domínio>/rhdh/rhdh-templates/-/blob/ai-golden-path-postgresql/templates/request-postgresql-database/template.yaml`,
ou pelo terminal com o comando de registro do `webinar/roteiro.md`. Depois da gravação, desregistrar (Catalog → Location correspondente → Unregister, ou tool `unregister-catalog-entities` com `type.locationId`) para poder gravar de novo.

---

## Ato 5 · Kafka: um segundo Golden Path, com aprovação por merge request

Substitui a governança via Connectivity Link (Atos 1b passo 2, 2 e 3) quando o público não conhece RHCL; esses três ficam como alternativa. Três takes: dev pede, PE aprova, dev usa e observa.

### Ato 5a · Tanaka Developer pede um tópico Kafka

**Pré-condição**: sessão do Ato 1b (Tanaka Developer). O tópico `claims-ai-intake` não existe (reset abaixo). Duração alvo: 3 min.

**Prompt**

```
Você continua como Tanaka Developer no Red Hat Developer Hub. Nunca clique em "Sign In" ou "Sign out". Confirme "Tanaka Developer" no canto superior direito.

1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/create/templates/default/request-kafka-topic
   Aguarde o formulário carregar (até 15 segundos). Preencha:
   - Topic Name: claims-ai-intake
   - Owning Team: clique no campo, digite devteam1 e escolha a opção "devteam1" na lista
   - Partitions: 3
   - Retention: deixe "Infinite"
   - Description: Emails de sinistro da feature claims-ai
   Clique em "Review", pause 3 segundos, clique em "Create". Aguarde os dois passos ficarem verdes (cerca de 10 segundos).
2. Clique no link "Merge Request" que aparece ao final. Na página do GitLab, pause 5 segundos na descrição do MR e abra a aba "Changes"; pause 5 segundos sobre os dois arquivos (o KafkaTopic e o registro no catálogo). Não faça merge.

Ao terminar, diga "Ato 5a concluído" e informe a URL do merge request.
```

**Pronto quando**: MR aberto em `rhdh/infra-app-of-apps` com dois arquivos. **Contingência**: formulário sem a opção devteam1 → digitar `group:default/devteam1`; GitLab pedindo login → você faz login como tanaka-dev fora da gravação.

### Ato 5b · Tanaka Platform Engineer aprova o tópico

**Nota**: não perguntar ao Lightspeed sobre o tópico recém-criado; entidades novas demoram para entrar no índice de busca e a resposta sai como "não encontrado" (testado). O destaque de IA para o engenheiro de plataforma fica no Ato 4.

**Pré-condição**: Sign out, Sign In como **Tanaka Platform Engineer**; GitLab logado como `tanaka-pe`. Duração alvo: 3 min (mais 1 a 3 min de espera do Argo CD, cortada na edição).

**Prompt**

```
Você está no papel de Tanaka Platform Engineer. Nunca clique em "Sign In" ou "Sign out".

1. Abra https://gitlab-gitlab.apps.cluster-ql7cw.dyn.redhatworkshops.io/rhdh/infra-app-of-apps/-/merge_requests e clique no merge request "Request Kafka Topic: claims-ai-intake". Abra a aba "Changes", pause 5 segundos, volte para "Overview" e clique em "Merge". Confirme se for pedido.
2. Abra https://streams-console.apps.cluster-ql7cw.dyn.redhatworkshops.io/ e, se aparecer "Click to login anonymously", clique. Vá em "Topics". Recarregue a página a cada 30 segundos até o tópico "claims-ai-intake" aparecer (até 3 minutos). Pause 5 segundos sobre ele.
3. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog?filters%5Bkind%5D=resource e localize "kafka-topic-claims-ai-intake". Clique nele e pause 5 segundos (dono devteam1, tipo kafka-topic, depende de kafka-cluster).
Ao terminar, diga "Ato 5b concluído".
```

**Pronto quando**: tópico no Streams console e no catálogo. **Contingência**: tópico não aparece em 3 min → `oc annotate application.argoproj.io infra-kafka-topics -n openshift-gitops argocd.argoproj.io/refresh=normal --overwrite` (força o Argo); catálogo sem o Resource → esperar 2 min (processamento do catálogo).

### Ato 5c · Tanaka Developer liga a feature ao tópico e vê as mensagens

**Pré-condição**: Sign out, Sign In como **Tanaka Developer**; GitLab logado como `tanaka-dev`. Duração alvo: 5 min (mais 1 a 2 min de rollout, cortado).

**Prompt**

```
Você está no papel de Tanaka Developer. Nunca clique em "Sign In" ou "Sign out".

1. Abra https://gitlab-gitlab.apps.cluster-ql7cw.dyn.redhatworkshops.io/tanaka-dev/parasol-insurance-secured-claims-ai-gitops/-/blob/main/helm/templates/deployment.yaml e clique em "Edit" → "Edit single file". Logo acima da linha "- name: DEV_KAFKA_PASSWORD" insira duas linhas com a mesma indentação:
            - name: KAFKA_TOPIC
              value: claims-ai-intake
   Mensagem do commit: "feature consome e produz no tópico claims-ai-intake". Clique em "Commit changes" (na branch main).
2. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/component/parasol-insurance-secured-tanaka-dev-claims-ai/cd
   Recarregue a cada 30 segundos até a aplicação mostrar "Synced" e "Healthy" com o novo commit (até 3 minutos). Pause 3 segundos.
3. Abra https://streams-console.apps.cluster-ql7cw.dyn.redhatworkshops.io/ (login anônimo se pedido) → "Topics" → "claims-ai-intake" → "Messages". Recarregue a cada 30 segundos até aparecerem mensagens (emails de sinistro em JSON; a aplicação publica um a cada 45 segundos). Pause 8 segundos sobre as mensagens.

Ao terminar, diga "Ato 5c concluído" e informe quantas mensagens apareceram.
```

**Pronto quando**: mensagens JSON no tópico novo. **Contingência**: Argo demora → `oc annotate application.argoproj.io parasol-insurance-secured-tanaka-dev-claims-ai -n rhdh-gitops argocd.argoproj.io/refresh=normal --overwrite`; editor do GitLab confuso → você faz o commit e o agente segue no passo 2.

**Reset do Ato 5**: apagar os dois arquivos do tópico em `rhdh/infra-app-of-apps` (`kafka-topics/claims-ai-intake.yaml` e `catalog/kafka-topics/claims-ai-intake.yaml`) com um commit; como a pasta fica vazia, o Argo CD **não** faz o prune (proteção contra apagar tudo): rodar `oc delete kafkatopic claims-ai-intake -n kafka` e depois `oc annotate application.argoproj.io infra-kafka-topics -n openshift-gitops argocd.argoproj.io/refresh=normal --overwrite`. O Resource some do catálogo em 1 a 2 min. Reverter a linha `KAFKA_TOPIC` no repositório GitOps da feature.

---

## Depois de cada gravação (reset para regravar)

| Ato | Reset |
|---|---|
| 1, 1b, 2 | `bash webinar/reset-tanaka-dev.sh tanaka-dev claims-ai` (apps Argo, namespace, projeto GitOps, branch, webhook, Location do catálogo e pedido de chave da persona); leva 2 min; validado |
| 3 | nada (a chave continua válida; o contador de 429 zera em 10 s). A chave aparece mascarada com um ícone de olho; para o curl, ler do cluster: `oc get secret -n kuadrant-system -l app=parasol-api` (o secret `devportal-kuadrant-tanaka-dev-…`) sem exibir na tela |
| 5 | ver "Reset do Ato 5" acima |
| 4 | desregistrar o template (acima); fechar ou manter o MR |
