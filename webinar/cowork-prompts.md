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

**Pré-condição**: Chrome com a extensão do Claude, uma aba no RHDH logada como **Tanaka Developer**; Lightspeed com a pergunta do passo 1 já respondida uma vez hoje (aquecimento). Duração alvo: 12 min.

**Prompt**

```
Você vai executar uma demonstração gravada no Red Hat Developer Hub (RHDH) como a desenvolvedora Tanaka Developer. Faça exatamente os passos abaixo, na ordem, com calma (pausa de 2 segundos entre cliques). Nunca clique em "Sign In" ou "Sign out". Se aparecer uma tela de login, pare e me avise. Antes de começar, confirme que o canto superior direito mostra "Tanaka Developer".

1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/lightspeed
   Clique no card "Começar uma nova feature". Aguarde até a resposta terminar (o texto para de mudar e o indicador de carregamento some; pode levar até 90 segundos). Não faça mais nada enquanto carrega. Quando terminar, role a resposta devagar até o fim.

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
   Aguarde os cinco passos ficarem verdes (cerca de 15 segundos). Pause 3 segundos. Clique em "Open in catalog" e pause 5 segundos na página do novo componente.

4. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/component/parasol-insurance-secured-tanaka-dev-webinar-feature
   Este é um componente igual ao que acabou de ser criado, mas com a pipeline já concluída. Abra as abas nesta ordem, esperando carregar e pausando 3 segundos em cada: "CI", "CD", "Topology", "Image Registry", "Service Mesh".
   Volte para "Overview", role até "Links" e clique em "Grafana: Parasol Platform Overview (this namespace)". Aguarde o painel carregar (10 segundos), role até o fim devagar e volte para a aba do RHDH.

5. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/api-products
   Clique em "Parasol Insurance Claims API". Pause 3 segundos na visão geral e abra a aba "Policies". Pause 3 segundos.
   Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/my-api-keys
   Clique em "Request Access". Selecione a API "Parasol Insurance Claims API" e o tier "silver". No campo de caso de uso escreva: "Integração do portal de sinistros da corretora". Aceite os termos e clique em "Request". Confirme que o pedido aparece com estado pendente.

Ao terminar, diga "Ato 1 concluído" e liste qualquer passo que não tenha funcionado como descrito.
```

**Pronto quando**: pedido de chave em estado pendente em My API Keys.
**Contingência**: passo 1 lento → usar o chat em "Recent" (mesma pergunta respondida); passo 3 falhar → seguir para o passo 4, que já mostra o resultado; passo 5 sem "Request Access" → recarregar a página.

---

## Ato 2 · Tanaka Platform Engineer aprova o acesso

**Pré-condição**: Sign out do ato anterior, Sign In como **Tanaka Platform Engineer** (feito por você). Duração alvo: 2 min.

**Prompt**

```
Você vai executar uma demonstração gravada no Red Hat Developer Hub como a engenheira de plataforma Tanaka Platform Engineer. Nunca clique em "Sign In" ou "Sign out". Confirme que o canto superior direito mostra "Tanaka Platform Engineer" antes de começar.

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
Você vai executar uma demonstração gravada como a desenvolvedora Tanaka Developer. Nunca clique em "Sign In" ou "Sign out". Confirme "Tanaka Developer" no canto superior direito.

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

## Depois de cada gravação (reset para regravar)

| Ato | Reset |
|---|---|
| 1 | apagar a branch `claims-ai` e o namespace/apps criados: `oc delete application.argoproj.io -n rhdh-gitops -l backstage-name=parasol-insurance-secured-tanaka-dev-claims-ai-bootstrap`, `oc delete ns parasol-insurance-secured-tanaka-dev` **não** (é o namespace pronto do passo 4); apagar o projeto GitLab `tanaka-dev/parasol-insurance-secured-claims-ai-gitops` e a branch `claims-ai` de `parasol/parasol-insurance`; remover o componente do catálogo (Location do catalog-info do projeto apagado) |
| 1 e 2 | remover o pedido de chave: `oc delete apikey -n kuadrant-tanaka-dev-lab --all` (namespace criado pelo portal para tanaka-dev) |
| 3 | nada (a chave continua válida; o contador de 429 zera em 10 s) |
| 4 | desregistrar o template (acima); fechar ou manter o MR |
