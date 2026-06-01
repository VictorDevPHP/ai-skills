# /new-plan

Cria um novo plano de implementação no padrão do projeto, com `plan.md` e `backlog.md` prontos para uso com `/execute-phase`.

## Uso

```
/new-plan <slug> "<titulo>"
```

- `<slug>`: nome curto em kebab-case (ex: `air-tracking`, `vision-agent`)
- `<titulo>`: título legível da feature (ex: `"Vision Agent para Tracking"`)

Se chamado sem argumentos, pergunte ao usuário pelo slug e título antes de continuar.

## Comportamento

### 1. Verificar se já existe

Verifique se `.claude/plans/<slug>/` já existe.
- Se sim, pergunte se o usuário quer sobrescrever ou escolher outro slug.
- Se não, continue.

### 2. Coletar informações

Se ainda não tiver todas as informações necessárias, pergunte ao usuário:
- **Objetivo**: o que será construído e por quê?
- **Fases**: quantas fases e qual o objetivo de cada uma? (pode ser rascunho — refinamos depois)
- **Restrições e decisões já tomadas**: existe alguma decisão de arquitetura fixada?

Você pode usar o contexto da conversa atual para preencher campos automaticamente se as informações já foram discutidas.

### 3. Criar os arquivos

Crie `.claude/plans/<slug>/plan.md` em **prosa**, no estilo do plan mode nativo do Claude — um documento narrativo que se lê de cima a baixo, **não** uma lista de checkboxes. Os checkboxes de rastreamento vivem apenas no `backlog.md`.

Siga este template:

```markdown
# <Titulo>

## Contexto
<Parágrafo(s) descrevendo a situação atual e por que esta mudança é necessária. Referencie arquivos/linhas relevantes como `caminho/arquivo.php:linha`.>

## Objetivo
<O que será construído e o resultado esperado, em prosa.>

## Abordagem

### Fase 1 — <Nome da Fase>
<Um a três parágrafos descrevendo o que será feito nesta fase: quais arquivos serão criados/modificados (com caminhos), a lógica envolvida e as decisões. Escreva como você explicaria a um colega — não como checklist.>

**Verificação:** <Como confirmar que a fase está correta — comando concreto ou comportamento observável.>

### Fase 2 — <Nome da Fase>
<Idem.>

**Verificação:** <...>

[...demais fases]

## Decisões e Restrições
<Decisões de arquitetura fixadas, restrições, referências a outros planos se houver.>
```

Crie `.claude/plans/<slug>/backlog.md` seguindo este template:

```markdown
# Backlog — <Titulo>

## Pendente

### Fase 1 — <Nome da Fase>
- [ ] <espelha os steps do plan.md>

[...demais fases]

---

## Log de Execução

### <YYYY-MM-DD> — Criação do plano
**Feito:** plano criado via `/new-plan`.
**Decisões:** <decisões já tomadas, se houver>
**Bloqueios:** nenhum.
```

### 4. Confirmar

Exiba um resumo do que foi criado:
- Caminho dos arquivos gerados
- Número de fases e steps totais
- Comando para começar: `/execute-phase <slug>`

## Regras

- O `plan.md` é **narrativo** (prosa, estilo plan mode nativo) e é a fonte da verdade do *porquê* e do *como*. Não usar checkboxes nele.
- O `backlog.md` é o **rastreador de execução**: traduz cada fase do `plan.md` em steps **atômicos e verificáveis** com checkboxes (`[ ]`), e é o único arquivo que o `/execute-phase` marca como concluído.
- Cada step do backlog descreve uma ação concreta (criar arquivo, mover classe, atualizar import, rodar migration). Nunca steps vagos como "refatorar X" sem dizer o que muda em qual arquivo.
- Cada fase deve terminar com um step de **verificação** (`Verificação Fase N`) descrevendo como confirmar que a fase está correta — esse step é marcado manualmente pelo usuário.
- Steps de implementação longa/complexa em arquivo(s) isolado(s) podem ser sinalizados como candidatos ao Codex (ex: `[codex]`) para que o `/execute-phase` priorize delegar ao Codex quando disponível.