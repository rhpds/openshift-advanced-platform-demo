# Recording Takes — "Como turbinar sua Engenharia de Plataforma com IA"

Gravação com **Claude Cowork** (interfaces gráficas), **Claude Code** (T09a) e **Screen Studio** (captura e edição). Narração gravada depois. Substitui `cowork-prompts.md` como roteiro de gravação; `roteiro.md` continua sendo a fonte das falas.

Instância: `apps.cluster-ql7cw.dyn.redhatworkshops.io`. RHDH: `https://backstage-developer-hub-rhdh.<domínio>`. GitLab: `https://gitlab-gitlab.<domínio>`. Streams console: `https://streams-console.<domínio>`.
Personas: **Tanaka Developer** (`tanaka-dev`) e **Tanaka Platform Engineer** (`tanaka-pe`), o apresentador nos dois papéis.

## Recording Mode (preâmbulo colado antes de cada prompt do Cowork)

```
RECORDING MODE. Esta é uma gravação de tela, não uma exploração.
- Antes da primeira ação, confirme que o canto superior direito mostra exatamente a persona indicada. Se não mostrar, pare imediatamente e responda "ABORT TAKE: persona incorreta". Nunca clique em "Sign In" ou "Sign out".
- Faça apenas os passos listados, na ordem. Não explore, não abra outras abas ou aplicações, não repita cliques durante esperas, não faça troubleshooting.
- Movimentos deliberados: mova o cursor direto ao alvo; durante esperas, deixe o cursor parado onde está.
- Depois de cada mudança de tela, aguarde a página carregar e mais 2 segundos antes de agir.
- Em cada evidência marcada como HOLD, deixe a tela parada de 4 a 6 segundos sem mover o cursor.
- Role devagar e só quando indicado; nunca role para "procurar".
- Se algo divergir do descrito (tela diferente, erro, botão ausente, mais de 90 segundos de espera não prevista), execute no máximo a contingência indicada no próprio passo; se não houver ou ela falhar, pare e responda "ABORT TAKE: <motivo>".
- Ao chegar ao último passo, atinja o estado final descrito, deixe a tela parada 5 segundos e responda "TAKE OK".
```

Legenda das notas de edição: **KEEP** manter em tempo real · **CUT** remover · **SPEED UP** acelerar · **BRIDGE** espaço para narração/transição · **HOLD** imagem limpa para zoom ou narração.

---

## MAIN DEMO — Kafka

### T01 — Developer descobre o Golden Path com IA

- **Persona**: Tanaka Developer.
- **Narrative purpose**: a IA responde a partir desta plataforma (catálogo e templates), não de memória; indica o Golden Path que T03 vai usar.
- **Preconditions**: Chrome logado no RHDH como tanaka-dev; Lightspeed com a pergunta já feita uma vez hoje (chat de aquecimento fechado); nenhum chat aberto na tela inicial.
- **Start frame**: `/lightspeed`, tela inicial com "Hello, Tanaka Developer", os três cards e o seletor `qwen3-14b`.
- **Evidence**: resposta citando "Onboarding features on Parasol Insurance application", o parâmetro branch e o que o template cria.
- **Visual holds**: tela inicial (8 s, abertura da narração sobre o Lightspeed); resposta completa (6 s).
- **End frame**: resposta completa visível, rolada até o fim.
- **Ready when**: resposta terminou e menciona o template.
- **Abort**: resposta com erro, chat vazio após 120 s, resposta sem citar template.
- **Editing**: espera da resposta SPEED UP (manter 3 s de "loading"); tela inicial BRIDGE para a explicação do Lightspeed; zoom no seletor de modelo e nos cards.
- **Raw / final**: 3 min / 1,5 min.
- **Reset**: nenhum (abrir "New chat" antes de repetir).

```
Persona: Tanaka Developer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/lightspeed
   Aguarde a tela inicial (saudação, três cards, seletor de modelo). HOLD 8 segundos.
2. Clique no card "Começar uma nova feature". Deixe o cursor parado. Aguarde a resposta terminar: o indicador de carregamento some e o texto para de mudar (até 120 segundos).
3. Role a resposta devagar do início ao fim, uma vez. HOLD 6 segundos no fim da resposta.
Estado final: resposta completa visível.
```

### T01b — (opcional) Como a IA sabe: as ferramentas MCP

- **Persona**: Tanaka Developer. **Purpose**: tornar visível a ancoragem por MCP. **Preconditions**: T01 concluído; chat novo.
- **Start frame**: `/lightspeed`, tela inicial. **Evidence**: lista das sete tools (fetch-catalog-entities, fetch-template-metadata, TechDocs, register/unregister). **End frame**: resposta. **Ready when**: resposta lista as tools. **Abort**: resposta sem lista. **Editing**: SPEED UP na espera; zoom na lista. **Raw / final**: 2 min / 0,7 min. **Reset**: nenhum.

```
Persona: Tanaka Developer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/lightspeed e clique em "New chat" se houver um chat aberto.
2. Clique no campo "Enter a prompt for Lightspeed", digite: Quais ferramentas você consulta neste Developer Hub para responder minhas perguntas? Liste cada uma com uma frase.
   Pressione Enter. Cursor parado. Aguarde a resposta terminar (até 120 segundos).
3. Role a resposta devagar até o fim. HOLD 6 segundos.
Estado final: lista de ferramentas visível.
```

### T02 — Developer entende o serviço pelo catálogo

- **Persona**: Tanaka Developer.
- **Purpose**: o catálogo é a fonte de verdade (dono, sistema, links) e mostra que o serviço depende de Kafka, o que T06 vai resolver.
- **Preconditions**: logado como tanaka-dev.
- **Start frame**: Overview de `parasol-insurance` (cabeçalho com owner devteam1, system parasol-insurance).
- **Evidence**: card "About" e "Links" (Argo, Quay, Sonar, Kafka console, Grafana); aba Dependencies com `kafka-cluster`, `parasol-db` e a API.
- **Visual holds**: Overview após rolar até Links (5 s); Dependencies (6 s).
- **End frame**: aba Dependencies.
- **Ready when**: Dependencies mostra kafka-cluster.
- **Abort**: componente não encontrado, aba sem conteúdo após 30 s.
- **Editing**: carregamento CUT; zoom em kafka-cluster; BRIDGE para a fala "tudo que o dev precisaria descobrir em dez ferramentas".
- **Raw / final**: 1,5 min / 1 min. **Reset**: nenhum.

```
Persona: Tanaka Developer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/component/parasol-insurance
   Aguarde carregar. HOLD 4 segundos no topo. Role devagar até a seção "Links". HOLD 5 segundos.
2. Role de volta ao topo e clique na aba "Dependencies". Aguarde o grafo carregar. HOLD 6 segundos.
Estado final: aba Dependencies visível.
```

### T03 — Developer executa o Golden Path

- **Persona**: Tanaka Developer.
- **Purpose**: um campo, e a plataforma cria branch, GitOps, Argo, pipeline e o componente no catálogo.
- **Preconditions**: reset master executado (a persona não tem feature ativa; `parasol-insurance-secured-tanaka-dev` não existe); logado como tanaka-dev.
- **Start frame**: formulário do template com o campo "Branch Name" vazio.
- **Evidence**: página de Review com `claims-ai`; os 5 passos verdes; componente `parasol-insurance-secured-tanaka-dev-claims-ai` com owner Tanaka Developer e system parasol-insurance.
- **Visual holds**: Review (3 s); passos verdes (5 s); Overview do componente novo (6 s).
- **End frame**: Overview do componente novo.
- **Ready when**: "Open in catalog" levou ao componente com owner Tanaka Developer.
- **Abort**: qualquer passo vermelho; formulário sem o campo; erro ao criar.
- **Editing**: execução dos passos KEEP (12 s); carregamentos CUT; zoom nos passos e no owner.
- **Raw / final**: 1,5 min / 1,2 min.
- **Reset**: `bash webinar/reset-tanaka-dev.sh tanaka-dev claims-ai` (2 min).

```
Persona: Tanaka Developer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/create/templates/default/parasol-insurance-secured-dev
   Aguarde o formulário (até 15 segundos). HOLD 3 segundos.
2. Clique no campo "Branch Name" e digite: claims-ai
3. Clique em "Review". HOLD 3 segundos na revisão.
4. Clique em "Create". Cursor parado. Aguarde os cinco passos ficarem verdes (cerca de 15 segundos). HOLD 5 segundos.
5. Clique em "Open in catalog". Aguarde a página do componente. HOLD 6 segundos no topo (nome, owner, system).
Estado final: Overview de parasol-insurance-secured-tanaka-dev-claims-ai.
```

### T04 — Developer altera o código e a pipeline dispara

- **Persona**: Tanaka Developer.
- **Purpose**: o dev só escreve código; a pipeline segura é gatilho automático da plataforma.
- **Preconditions**: T03 concluído há pelo menos 2 min (listener da branch no ar: `oc get pods -n parasol-insurance-secured-tanaka-dev | grep el-`); GitLab logado como tanaka-dev na mesma janela.
- **Start frame**: GitLab, `parasol/parasol-insurance` na branch `claims-ai` (chegando pelo link "View Source" do componente).
- **Evidence**: commit criado na branch; aba CI do componente com PipelineRun "Running".
- **Visual holds**: editor com o arquivo antes do commit (3 s); confirmação do commit (4 s); CI com run em execução (6 s).
- **End frame**: aba CI com o PipelineRun em execução.
- **Ready when**: PipelineRun visível com status Running.
- **Abort**: GitLab pede login; botão "Commit changes" ausente; nenhum PipelineRun após 90 s (contingência: recarregar a aba CI uma vez).
- **Editing**: digitação SPEED UP; espera do run CUT; zoom no status Running; BRIDGE final para "a pipeline leva 5 minutos".
- **Raw / final**: 2,5 min / 1,2 min.
- **Reset**: reset master (apaga a branch).

```
Persona: Tanaka Developer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/component/parasol-insurance-secured-tanaka-dev-claims-ai
   Role até "Links" e clique em "View Source" (abre o GitLab na branch claims-ai, na mesma aba ou em nova aba; se abrir em nova aba, continue nela). Aguarde. HOLD 3 segundos.
2. Clique no botão "+" ("Add to tree") ao lado do nome da branch e escolha "New file".
3. Em "Filename" digite: docs/claims-ai.md
   No editor digite:
   # Claims AI
   Primeira alteração da feature claims-ai.
   Em "Commit message" digite: docs: início da feature claims-ai
   Confirme que a branch de destino é claims-ai. HOLD 3 segundos.
4. Clique em "Commit changes". Aguarde a confirmação. HOLD 4 segundos.
5. Volte para https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/component/parasol-insurance-secured-tanaka-dev-claims-ai/ci
   Aguarde 30 segundos com o cursor parado; se não houver um Pipeline Run, recarregue a página uma única vez e aguarde mais 30 segundos. HOLD 6 segundos com o run em execução.
Estado final: aba CI com o Pipeline Run "Running".
```

### T05 — Developer observa o resultado

- **Persona**: Tanaka Developer.
- **Purpose**: build, análise estática, scans de segurança, SBOM e deploy por GitOps vieram de graça com o Golden Path.
- **Preconditions**: pipeline de T04 concluída (`Succeeded`, ~6 min após T04); logado como tanaka-dev.
- **Start frame**: aba CI do componente.
- **Evidence**: PipelineRun Succeeded com a lista de tarefas (clone, maven, sonar, build, ACS, SBOM, TPA, rollout); aba CD Synced/Healthy; Topology com `parasol-insurance-secured` e `parasol-db` rodando.
- **Visual holds**: tarefas da pipeline (6 s); CD (5 s); Topology (6 s).
- **End frame**: Topology.
- **Ready when**: CI Succeeded, CD Healthy, Topology com dois workloads.
- **Abort**: run ainda Running (esperar fora da gravação e reiniciar o take); CD vazia após recarregar uma vez.
- **Editing**: trocas de aba CUT; zoom na lista de tarefas e no "Healthy"; BRIDGE para "o dev não configurou nada disso".
- **Raw / final**: 2 min / 1,5 min. **Reset**: nenhum (depende do reset de T03).

```
Persona: Tanaka Developer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/component/parasol-insurance-secured-tanaka-dev-claims-ai/ci
   Aguarde. Clique na seta de expandir do Pipeline Run "Succeeded" para ver as tarefas, se houver. HOLD 6 segundos.
2. Clique na aba "CD". Aguarde até 15 segundos; se ficar vazia, recarregue uma única vez. HOLD 5 segundos sobre "Synced" e "Healthy".
3. Clique na aba "Topology". Aguarde o grafo. HOLD 6 segundos.
Estado final: Topology com a aplicação e o banco.
```

### T06 — Developer pede um tópico Kafka pelo Golden Path

- **Persona**: Tanaka Developer.
- **Purpose**: infraestrutura por Golden Path com aprovação humana: o pedido vira um merge request revisável.
- **Preconditions**: tópico `claims-ai-intake` não existe (reset de T06); GitLab logado como tanaka-dev; logado no RHDH como tanaka-dev.
- **Start frame**: formulário "Request Kafka Topic".
- **Evidence**: Review com nome, dono devteam1, 3 partições; dois passos verdes; MR aberto em `rhdh/infra-app-of-apps` com dois arquivos (KafkaTopic e Resource do catálogo).
- **Visual holds**: Review (3 s); passos (4 s); MR Overview (4 s); aba Changes (6 s).
- **End frame**: MR, aba Changes.
- **Ready when**: MR "Request Kafka Topic: claims-ai-intake" aberto com dois arquivos.
- **Abort**: opção devteam1 não aparece (contingência: digitar `group:default/devteam1` e Enter); passo vermelho; MR sem arquivos.
- **Editing**: preenchimento KEEP; zoom nos dois arquivos do diff; BRIDGE para "aprovação humana, mas sem ticket".
- **Raw / final**: 2,5 min / 1,5 min.
- **Reset**: apagar os dois arquivos do tópico em `rhdh/infra-app-of-apps` (commit), `oc delete kafkatopic claims-ai-intake -n kafka`, refresh do app Argo `infra-kafka-topics`; se o MR não foi mesclado, fechá-lo e apagar o branch `request/kafka-topic-claims-ai-intake`.

```
Persona: Tanaka Developer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/create/templates/default/request-kafka-topic
   Aguarde o formulário (até 15 segundos). HOLD 3 segundos.
2. Preencha, nesta ordem:
   - "Topic Name": claims-ai-intake
   - "Owning Team": clique no campo, digite devteam1 e escolha "devteam1" na lista que aparece (se a lista não aparecer em 5 segundos, apague, digite group:default/devteam1 e pressione Enter)
   - "Partitions": apague o valor e digite 3
   - "Retention": deixe como está
   - "Description": Emails de sinistro da feature claims-ai
3. Clique em "Review". HOLD 3 segundos.
4. Clique em "Create". Cursor parado. Aguarde os dois passos ficarem verdes (cerca de 10 segundos). HOLD 4 segundos.
5. Clique no link "Merge Request". Aguarde o GitLab. HOLD 4 segundos na descrição do MR.
6. Clique na aba "Changes". Aguarde. HOLD 6 segundos sobre os dois arquivos.
Estado final: MR "Request Kafka Topic: claims-ai-intake", aba Changes.
```

### T07a — Platform Engineer aprova pelo merge request

- **Persona**: Tanaka Platform Engineer.
- **Purpose**: o PE governa por Git: revisa e aprova em um lugar auditável.
- **Preconditions**: troca de persona feita fora da gravação (RHDH e GitLab logados como tanaka-pe); MR de T06 aberto.
- **Start frame**: lista de MRs de `rhdh/infra-app-of-apps`.
- **Evidence**: aba Changes com os dois arquivos; botão Merge; estado "Merged".
- **Visual holds**: Changes (5 s); Merged (5 s).
- **End frame**: MR com o selo "Merged".
- **Ready when**: MR merged.
- **Abort**: MR ausente; conflito; botão Merge desabilitado.
- **Editing**: KEEP curto; zoom no Merge e no Merged; BRIDGE "o Argo CD aplica em instantes" (a espera real fica fora).
- **Raw / final**: 1 min / 0,7 min. **Reset**: o de T06.

```
Persona: Tanaka Platform Engineer (no GitLab, o nome no menu do usuário).
1. Abra https://gitlab-gitlab.apps.cluster-ql7cw.dyn.redhatworkshops.io/rhdh/infra-app-of-apps/-/merge_requests
   Clique no merge request "Request Kafka Topic: claims-ai-intake". Aguarde. HOLD 3 segundos.
2. Clique na aba "Changes". Aguarde. HOLD 5 segundos.
3. Clique na aba "Overview". Clique em "Merge". Se aparecer uma confirmação, confirme. Aguarde o selo "Merged". HOLD 5 segundos.
Estado final: MR merged.
```

### T07b — GitOps entregou o tópico

- **Persona**: Tanaka Platform Engineer.
- **Purpose**: ninguém tocou no cluster: o Argo CD criou o tópico e o catálogo já o conhece com dono.
- **Preconditions**: T07a há pelo menos 3 min, ou refresh manual do Argo feito fora da gravação (`oc annotate application.argoproj.io infra-kafka-topics -n openshift-gitops argocd.argoproj.io/refresh=normal --overwrite`); `oc get kafkatopic claims-ai-intake -n kafka` Ready; Resource `kafka-topic-claims-ai-intake` já no catálogo (até 2 min após o tópico).
- **Start frame**: Streams console, lista de tópicos (login anônimo já feito).
- **Evidence**: `claims-ai-intake` com 3 partições; página do Resource no RHDH com owner devteam1 e dependência kafka-cluster.
- **Visual holds**: linha do tópico (5 s); Resource (6 s).
- **End frame**: página do Resource `kafka-topic-claims-ai-intake`.
- **Ready when**: tópico listado e Resource aberto.
- **Abort**: tópico ausente (voltar ao prep, não recarregar em loop); Resource ausente (esperar fora da gravação).
- **Editing**: troca de app CUT; zoom no tópico e no owner; BRIDGE "GitOps: o que está no Git é o que está no cluster".
- **Raw / final**: 1,5 min / 1 min. **Reset**: o de T06.

```
Persona: Tanaka Platform Engineer.
1. Abra https://streams-console.apps.cluster-ql7cw.dyn.redhatworkshops.io/ e, se aparecer "Click to login anonymously", clique. Clique em "Topics". Aguarde a lista. HOLD 5 segundos com "claims-ai-intake" visível (se não estiver visível, pare e responda "ABORT TAKE: tópico ausente").
2. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/resource/kafka-topic-claims-ai-intake
   Aguarde. HOLD 6 segundos no topo (owner, type, dependsOn).
Estado final: página do Resource kafka-topic-claims-ai-intake.
```

### T08a — Developer liga a feature ao tópico

- **Persona**: Tanaka Developer.
- **Purpose**: consumir a infraestrutura aprovada é uma linha no GitOps, sem kubectl.
- **Preconditions**: troca de persona fora da gravação (GitLab e RHDH como tanaka-dev); T07b concluído.
- **Start frame**: GitLab, arquivo `helm/templates/deployment.yaml` do repositório `tanaka-dev/parasol-insurance-secured-claims-ai-gitops`.
- **Evidence**: as duas linhas `KAFKA_TOPIC` no editor; commit na main.
- **Visual holds**: linhas inseridas (5 s); commit confirmado (4 s).
- **End frame**: página do commit ou do arquivo já alterado.
- **Ready when**: commit na main com a alteração.
- **Abort**: editor não abre; branch de destino diferente de main.
- **Editing**: digitação SPEED UP; zoom nas duas linhas; BRIDGE "o Argo CD reconcilia em instantes".
- **Raw / final**: 1,5 min / 0,8 min. **Reset**: reset master (o repositório é recriado por T03).

```
Persona: Tanaka Developer (no GitLab, o nome no menu do usuário).
1. Abra https://gitlab-gitlab.apps.cluster-ql7cw.dyn.redhatworkshops.io/tanaka-dev/parasol-insurance-secured-claims-ai-gitops/-/blob/main/helm/templates/deployment.yaml
   Aguarde. HOLD 3 segundos.
2. Clique em "Edit" e escolha "Edit single file". Aguarde o editor.
3. Localize a linha "- name: DEV_KAFKA_PASSWORD". Posicione o cursor no início dessa linha e insira, com a mesma indentação dela, estas duas linhas antes:
            - name: KAFKA_TOPIC
              value: claims-ai-intake
   HOLD 5 segundos com as linhas visíveis.
4. Em "Commit message" digite: feature consome e produz no tópico claims-ai-intake
   Confirme que a branch de destino é main. Clique em "Commit changes". Aguarde a confirmação. HOLD 4 segundos.
Estado final: commit confirmado na main.
```

### T08b — A feature já usa o tópico

- **Persona**: Tanaka Developer.
- **Purpose**: resultado observável: o app reconciliado pelo Argo publica e consome no tópico aprovado.
- **Preconditions**: T08a há 2 a 3 min (ou refresh manual do app Argo `parasol-insurance-secured-tanaka-dev-claims-ai` fora da gravação); `oc get deployment parasol-insurance-secured -n parasol-insurance-secured-tanaka-dev` com `KAFKA_TOPIC` e rollout concluído; já existem mensagens no tópico (o app publica uma a cada 45 s).
- **Start frame**: aba CD do componente.
- **Evidence**: CD Synced/Healthy com o commit novo; Streams console, tópico `claims-ai-intake`, aba Messages com e-mails JSON.
- **Visual holds**: CD (5 s); Messages (8 s).
- **End frame**: Messages do tópico.
- **Ready when**: pelo menos uma mensagem visível.
- **Abort**: CD OutOfSync após recarregar uma vez; sem mensagens após 60 s (contingência: recarregar Messages uma única vez).
- **Editing**: trocas CUT; zoom no JSON de um e-mail; se uma mensagem nova chegar durante o hold, KEEP; fechamento do movimento "Governar".
- **Raw / final**: 2 min / 1,2 min. **Reset**: reset master + reset de T06.

```
Persona: Tanaka Developer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/catalog/default/component/parasol-insurance-secured-tanaka-dev-claims-ai/cd
   Aguarde até 15 segundos; se vazia, recarregue uma única vez. HOLD 5 segundos sobre "Synced" e "Healthy".
2. Abra https://streams-console.apps.cluster-ql7cw.dyn.redhatworkshops.io/ (login anônimo se pedido). Clique em "Topics", depois em "claims-ai-intake", depois na aba "Messages". Aguarde a lista (até 30 segundos; se vazia, recarregue uma única vez e aguarde 45 segundos). HOLD 8 segundos com as mensagens visíveis.
Estado final: mensagens JSON no tópico claims-ai-intake.
```

### T09a — Platform Engineer evolui a plataforma com Claude Code + MCP

- **Persona**: Tanaka Platform Engineer (Claude Code no terminal).
- **Purpose**: a IA ajuda o PE a estender a plataforma: entende os Golden Paths existentes pelo MCP do Developer Hub e publica um novo, governado (Git, MR, registro).
- **Preconditions**: rehearsal completo feito e reset executado (template fora do catálogo; branch `ai-golden-path-postgresql` apagado no remoto e MR fechado, para o agente criar do zero; clone local em `main` atualizado; `claude mcp list` com `rhdh-platform ✔ Connected`); terminal limpo em `~/work/active/webinar/rhdh-templates`, fonte grande, tema legível; RHDH aberto em outra janela como tanaka-pe em `/create` (5 templates) para T09b.
- **Start frame**: terminal com `claude` recém-aberto, prompt vazio.
- **Evidence**: chamadas às tools `fetch-template-metadata` / `fetch-catalog-entities`; criação dos arquivos em `templates/request-postgresql-database/`; `git push`; MR criado; chamada a `register-catalog-entities` com `locationID` de resposta.
- **Visual holds**: prompt digitado (4 s); primeira chamada MCP (4 s); resultado final com URL do MR e locationID (8 s).
- **End frame**: mensagem final do agente com a URL do MR e a confirmação do registro.
- **Ready when**: `oc`/RHDH confirmam o template `request-postgresql-database` no catálogo (T09b verifica na tela).
- **Abort**: agente pede credenciais; push recusado; agente não consegue registrar após duas tentativas (contingência: encerrar o take após o push e registrar via Bulk import em T09b, que passa a começar por `/bulk-import`).
- **Editing**: SPEED UP forte no trabalho do agente (manter velocidade real só nas chamadas MCP, no push e no registro); captions com "fetch-template-metadata", "git push", "register-catalog-entities"; BRIDGE para a fala "o agente aprendeu com os Golden Paths existentes".
- **Raw / final**: 6 a 10 min / 2,5 min.
- **Reset**: no clone, `git checkout main && git pull`; apagar branch remoto `ai-golden-path-postgresql` e local; fechar o MR; unregister do template no RHDH (tool `unregister-catalog-entities` com `type.locationId`, ou página da Location no catálogo).

Prompt para o Claude Code (colar como primeira mensagem; não é um prompt de Cowork):

```
Você é o agente do time de plataforma. Use o servidor MCP rhdh-platform (Developer Hub) para trabalhar.
1. Com fetch-template-metadata, estude como o template request-kafka-topic é construído: parâmetros, passos (fetch:template + publish:gitlab:merge-request), repositório de destino do MR, revisores, e como ele registra um Resource no catálogo.
2. Crie neste repositório um novo Golden Path "Request PostgreSQL Database" em templates/request-postgresql-database/ seguindo exatamente o mesmo padrão: parâmetros (nome, time dono via EntityPicker, namespace, tamanho de storage por ambiente, versão 15 ou 16, descrição), skeleton com os manifests do PostgreSQL (Secret, PVC, Deployment, Service) e o Resource de catálogo, docs/index.md, mesmo fluxo de merge request para rhdh/infra-app-of-apps com revisores pe1 e pe2.
3. Faça commit no branch ai-golden-path-postgresql, push, e abra o merge request para main com título "Golden Path: Request PostgreSQL Database (AI-authored)".
4. Registre o template no catálogo com register-catalog-entities usando a URL do template.yaml nesse branch (formato https://gitlab-gitlab.apps.cluster-ql7cw.dyn.redhatworkshops.io/rhdh/rhdh-templates/-/blob/ai-golden-path-postgresql/templates/request-postgresql-database/template.yaml).
Ao final, responda só com: a URL do merge request e o locationID retornado pelo registro. Não peça confirmações intermediárias; não altere outros arquivos.
```

### T09b — A nova capacidade aparece no Self-service

- **Persona**: Tanaka Platform Engineer.
- **Purpose**: a capacidade criada com IA está disponível, governada, para qualquer desenvolvedor.
- **Preconditions**: T09a concluído com registro (ou contingência via Bulk import feita fora da gravação); RHDH como tanaka-pe.
- **Start frame**: `/create` com os cinco templates (antes do reload).
- **Evidence**: após recarregar, card "Request PostgreSQL Database"; formulário com os campos; Review preenchido.
- **Visual holds**: card novo (6 s); Review (6 s, frame final, fechamento da narração).
- **End frame**: página de Review do novo template (sem clicar em Create).
- **Ready when**: card visível e Review exibido.
- **Abort**: card ausente após dois reloads espaçados de 30 s.
- **Editing**: zoom no card novo; BRIDGE final para o fechamento; não cortar o hold final.
- **Raw / final**: 1,5 min / 1 min. **Reset**: unregister (ver T09a).

```
Persona: Tanaka Platform Engineer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/create
   Aguarde a lista de templates. HOLD 3 segundos. Recarregue a página uma vez e aguarde. Localize o card "Request PostgreSQL Database" (se não aparecer, aguarde 30 segundos e recarregue uma segunda vez; se ainda não aparecer, pare e responda "ABORT TAKE: template ausente"). HOLD 6 segundos com o card visível.
2. Clique em "Choose" nesse card. Aguarde o formulário. Preencha:
   - "Database Name": claims-db
   - "Owning Team": clique, digite devteam1 e escolha "devteam1"
   - "Target Namespace": parasol-insurance-secured-tanaka-dev
   - "Storage Size": 5 GiB (development)
   - "Description": Banco de dados da feature claims-ai
3. Clique em "Review". Não clique em "Create". HOLD 6 segundos.
Estado final: página de Review do template Request PostgreSQL Database.
```

### T09c — (opcional) O merge request do agente

- **Persona**: Tanaka Platform Engineer. **Purpose**: trilha auditável do que a IA produziu. **Start frame**: MRs de `rhdh/rhdh-templates`. **Evidence**: MR "Golden Path: Request PostgreSQL Database (AI-authored)", aba Changes com template.yaml, skeleton e docs. **End frame**: Changes. **Raw / final**: 1 min / 0,5 min.

```
Persona: Tanaka Platform Engineer.
1. Abra https://gitlab-gitlab.apps.cluster-ql7cw.dyn.redhatworkshops.io/rhdh/rhdh-templates/-/merge_requests e clique em "Golden Path: Request PostgreSQL Database (AI-authored)". HOLD 4 segundos.
2. Clique em "Changes". Aguarde. Role devagar pelos arquivos uma vez. HOLD 5 segundos.
Estado final: aba Changes do MR.
```

---

## Ordem de gravação, trocas de persona e esperas fora da gravação

| Ordem | Take | Persona | Antes do take (fora da gravação) |
|---|---|---|---|
| 1 | T01, T01b, T02 | dev | Lightspeed aquecido; chat fechado |
| 2 | T03 | dev | reset master |
| 3 | T04 | dev | esperar 2 min (listener) |
| 4 | T05 | dev | esperar a pipeline (5 a 6 min) |
| 5 | T06 | dev | reset de T06 se houver tópico anterior |
| 6 | T07a | pe | Sign out / Sign In (RHDH e GitLab) |
| 7 | T07b | pe | esperar Argo (até 3 min) ou refresh; Resource no catálogo |
| 8 | T08a | dev | Sign out / Sign In (RHDH e GitLab) |
| 9 | T08b | dev | esperar Argo + rollout (2 a 3 min) ou refresh; 1 min de mensagens |
| 10 | T09a | pe + Claude Code | Sign out / Sign In; reset de T09; terminal pronto |
| 11 | T09b, T09c | pe | catálogo com o template (até 30 s) |

Duração bruta total de captura: ~29 min (sem T01b/T09c: ~26). Duração final estimada: 20 a 23 min com abertura e fechamento narrados sobre holds.

## Rehearsal

1. Rehearsal completo na ordem acima com o Cowork, cronometrando e anotando cada divergência de prompt; troubleshooting permitido.
2. T09a: rehearsal próprio antes de tudo, com o mesmo prompt; anotar o que o agente pergunta ou deixa de fazer; ajustar o prompt; reset de T09.
3. Reset master + reset de T06 + reset de T09 após o rehearsal.
4. Só então os Recording Takes, um por vez, ABORT e regravação quando divergir.

## Resets

- **Master** (T03 a T08): `bash webinar/reset-tanaka-dev.sh tanaka-dev claims-ai`.
- **T06 a T08b (tópico)**: commit apagando `kafka-topics/claims-ai-intake.yaml` e `catalog/kafka-topics/claims-ai-intake.yaml` em `rhdh/infra-app-of-apps`; `oc delete kafkatopic claims-ai-intake -n kafka`; `oc annotate application.argoproj.io infra-kafka-topics -n openshift-gitops argocd.argoproj.io/refresh=normal --overwrite`; se o MR não foi mesclado, fechar e apagar o branch `request/kafka-topic-claims-ai-intake`.
- **T09**: unregister do template; apagar branch `ai-golden-path-postgresql` (remoto e local) e fechar o MR; clone em `main` atualizado.
- **Validação após reset**: `validate-instance.sh` com as quatro flags (0 falhas), Lightspeed aquecido.

---

## ALTERNATIVE / EXTENDED DEMO — Connectivity Link (RHCL)

Preservado para versão estendida ou demo dedicada. Mesmo Recording Mode. Não gravar no mesmo dia dos takes principais se envolver mudança de política (o gateway reinicia).

### A01 — Developer pede acesso à API pelo portal

- **Persona**: Tanaka Developer. **Purpose**: chave self-service com plano, sem ticket. **Preconditions**: persona sem pedido pendente; RHDH como tanaka-dev. **Start frame**: `/kuadrant/api-products`. **Evidence**: produto com route e policies; pedido pendente em My API Keys. **End frame**: My API Keys com o pedido. **Raw / final**: 2 min / 1,2 min. **Reset**: apagar `apikey` no namespace `kuadrant-tanaka-dev-*` e os `apikeyrequest`/`apikeyapproval` correspondentes.

```
Persona: Tanaka Developer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/api-products e clique em "Parasol Insurance Claims API". HOLD 4 segundos. Clique na aba "Policies". HOLD 5 segundos.
2. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/my-api-keys e clique em "Request Access".
3. No campo "API" escolha "parasol-claims-api"; em "Tiers" escolha "silver"; no campo de caso de uso digite: Integração do portal de sinistros da corretora. Marque as caixas de aceite. HOLD 3 segundos. Clique em "Request". Aguarde. HOLD 5 segundos com o pedido "Pending".
Estado final: My API Keys com o pedido pendente.
```

### A02 — Platform Engineer aprova

- **Persona**: Tanaka Platform Engineer. **Start frame**: `/kuadrant/api-key-approval`. **Evidence**: diálogo "Approve API Key" com usuário, API, tier e caso de uso; estado Approved. **End frame**: lista com Approved. **Raw / final**: 1 min / 0,7 min.

```
Persona: Tanaka Platform Engineer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/api-key-approval e aguarde a lista. HOLD 3 segundos sobre o pedido de user:default/tanaka-dev.
2. Clique em "Approve" nesse pedido. No diálogo "Approve API Key", HOLD 4 segundos, depois clique em "Approve". Aguarde "API key approved". HOLD 5 segundos.
Estado final: pedido aprovado.
```

### A03 — Developer usa a chave e encontra o limite

- **Persona**: Tanaka Developer (RHDH + terminal). **Evidence**: chave Active; terminal com 401, 200 e 429; Grafana "Responses by code". **End frame**: painel do Grafana. **Raw / final**: 3 min / 1,5 min. A chave pode aparecer na captura; ofuscar no security pass.
- **Narração (observação curta)**: "Aqui usamos uma API key para simplificar e tornar o fluxo visual. Em produção, o mecanismo de autenticação segue os requisitos de segurança e governança, de preferência credenciais de curta duração e baseadas em identidade quando aplicável."

```
Persona: Tanaka Developer.
1. Abra https://backstage-developer-hub-rhdh.apps.cluster-ql7cw.dyn.redhatworkshops.io/kuadrant/my-api-keys e recarregue uma vez. HOLD 4 segundos sobre "Active". Clique no ícone de olho da chave para revelá-la e depois no ícone de copiar (se houver); se não houver botão de copiar, selecione o texto da chave e copie.
2. No terminal já aberto, execute (cole a chave no lugar de <chave>):
   curl -sk -o /dev/null -w 'sem chave: HTTP %{http_code}\n' https://parasol-api-parasol-insurance-prod.apps.cluster-ql7cw.dyn.redhatworkshops.io/api/claims
   curl -sk -o /dev/null -w 'com chave: HTTP %{http_code}\n' -H "Authorization: APIKEY <chave>" https://parasol-api-parasol-insurance-prod.apps.cluster-ql7cw.dyn.redhatworkshops.io/api/claims
   for i in $(seq 1 12); do curl -sk -o /dev/null -w '%{http_code} ' -H "Authorization: APIKEY <chave>" https://parasol-api-parasol-insurance-prod.apps.cluster-ql7cw.dyn.redhatworkshops.io/api/claims; done; echo
   HOLD 6 segundos com os resultados (401, 200, dez 200 e depois 429).
3. Abra https://grafana-route-observability.apps.cluster-ql7cw.dyn.redhatworkshops.io/d/parasol-rhcl/connectivity-link-parasol-api-and-llm-gateway?orgId=1&from=now-15m&to=now
   Aguarde 10 segundos. HOLD 6 segundos sobre o painel "Responses by code and destination".
Estado final: painel do Grafana com 401, 200 e 429.
```
