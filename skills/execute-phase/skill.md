# /execute-phase

Orquestrador de fases do plano de implementação. Lê o backlog, decide o que executar, e coordena sub-agents — paralelo onde possível, sequencial onde necessário.

---

# Uso

```bash
/execute-phase <slug-do-plano>
```

- `<slug-do-plano>`: slug do plano em `.claude/plans/`
- Exemplo:

```bash
/execute-phase browser-tracking-refactor
```

## Resolução automática

- Se o slug for omitido e houver apenas um plano disponível, usar automaticamente.
- Se houver mais de um plano, listar opções e solicitar escolha do usuário.

---

# Comportamento

## 1. Carregar contexto

Ler obrigatoriamente:

```txt
.claude/plans/<slug>/plan.md
.claude/plans/<slug>/backlog.md
```

---

## 2. Decidir o que executar

Analisar o estado atual do backlog.

### Regras

- Se houver steps `[ ]` na fase atual:
  - executar apenas a fase atual

- Se existir apenas o step de verificação pendente:
  - NÃO executar nada
  - informar que a fase está pronta para validação
  - listar comandos de verificação do `plan.md`

- Se todas as fases estiverem `[x]`:
  - informar que o plano está completo

---

## Regra crítica

Nunca avançar para a próxima fase sem que:

- todos os steps estejam `[x]`
- o step de verificação da fase esteja concluído

---

# 3. Analisar dependências da fase

Para cada step `[ ]`:

## Determinar

- arquivos lidos
- arquivos criados
- arquivos modificados
- dependências entre steps

---

## Montar grupos de execução

### Grupo paralelo

Usar quando:

- os steps não possuem dependência entre si
- os arquivos são disjuntos

### Grupo sequencial

Usar quando:

- um step depende do resultado do anterior
- existe compartilhamento crítico de arquivos/contexto

---

# 4. Escolher modelo por step

## Usar `haiku`

Quando o step for puramente mecânico.

### Exemplos

- mover arquivo
- renomear arquivo
- atualizar namespace/import
- apagar diretório vazio
- editar config simples
- grep/verificação de referência

---

## Usar `sonnet`

Quando houver:

- criação de código
- refatoração
- lógica de negócio
- integração entre componentes
- decisões arquiteturais
- algoritmos
- services/agentes/comandos

---

## Regra de segurança

Em caso de dúvida:
- usar `sonnet`

---

# 5. Naming dos Sub-Agents

Cada sub-agent deve receber um nome amigável, técnico e contextual baseado no nome da fase atual.

---

## Padrão obrigatório

```txt
Fase {N}: {Nome do Agente}
```

Onde:

- `{N}` = número da fase atual
- `{Nome do Agente}` = responsabilidade principal do sub-agent

---

## Exemplos

### Fase 1 — Reorganização de namespaces

```txt
Fase 1: Agente Reorganizador de Namespaces
Fase 1: Agente Atualizador de Imports
Fase 1: Agente Removedor de Estruturas Legadas
```

### Fase 2 — Refatoração de services

```txt
Fase 2: Agente Refatorador de Services
Fase 2: Agente Extrator de Interfaces
Fase 2: Agente Integrador de Dependências
```

---

## Regras de naming

### Clareza

O nome deve deixar explícita a responsabilidade do sub-agent.

✅ Bom:

```txt
Fase 2: Agente Migrador de Configurações
```

❌ Ruim:

```txt
Fase 2: Worker 1
Fase 2: Agent A
Fase 2: Executor
```

---

### Paralelismo

Em grupos paralelos:

- todos os agents devem possuir nomes distintos
- evitar nomes ambíguos

---

### Consistência

Todos os nomes devem:

- iniciar com `Fase {N}:`
- usar linguagem técnica
- manter padrão previsível

---

# 6. Executar grupos

Executar grupos na ordem correta.

---

## Grupo paralelo

Disparar todos os sub-agents simultaneamente:

```txt
run_in_background: true
```

Aguardar TODOS concluírem antes de continuar.

---

## Grupo sequencial

Executar:

- 1 sub-agent por vez
- aguardando conclusão antes do próximo

---

# Payload do Sub-Agent

Cada sub-agent recebe:

- Nome amigável do agent
- Step exato a executar
- Descrição completa do `plan.md`
- Arquivos relevantes
- Estado atual do projeto
- Resultado dos steps anteriores
- Instrução de retorno padronizada
- Proibição explícita de commit/push

---

## Estrutura obrigatória

```txt
Nome do Agent:
Fase {N}: {Nome do Agente}

Retorne:
{
  status: ok|erro,
  arquivos: [],
  observacoes: ""
}
```

---

## Regras críticas

- NÃO commitar
- NÃO fazer push
- NÃO alterar backlog diretamente
- NÃO executar steps fora da fase atual

---

# 7. Revisão e aprovação pelo orquestrador

Após cada grupo concluir, o orquestrador (você, executando a skill) **DEVE revisar** o trabalho de cada sub-agent antes de marcar qualquer step como concluído. Nunca confie apenas no relatório do sub-agent.

---

## Como revisar

Para cada sub-agent do grupo:

- **Ler de fato os arquivos alterados** (campo `arquivos` do retorno) — não basta ler `observacoes`.
- Confrontar o que foi feito com o step e com a descrição do `plan.md`.

### Critérios de aprovação

- O step foi implementado de fato (não parcial, sem stubs/TODOs deixados para trás).
- Os arquivos certos foram tocados; nada fora do escopo do step.
- Segue os padrões e convenções do projeto (estilo do código vizinho).
- Não introduz regressão óbvia nem quebra contratos existentes.
- Coerente com os resultados dos steps anteriores e com decisões do `plan.md`.

---

## Decisão

### Aprovado

- Seguir para o próximo grupo (ou para a atualização do backlog, se for o último).

### Reprovado

- **NÃO** marcar o step no backlog.
- Reenviar o **mesmo step** ao sub-agent — via `SendMessage` no agent existente (preserva contexto) ou novo `Agent` — apontando de forma **concreta** o que está errado e as melhorias necessárias.
- Re-revisar o resultado.
- Repetir até aprovar, com **limite de 3 tentativas**.
- Se após 3 tentativas ainda estiver reprovado, tratar como `status: erro` (seção 8): parar, não atualizar backlog, reportar ao usuário.

---

## Regra crítica

O backlog só é atualizado (seção 9) após **todos** os steps da fase terem sido **aprovados** na revisão.

---

# 8. Tratar erros

Se qualquer sub-agent retornar:

```txt
status: erro
```

Ou se um step for reprovado após 3 tentativas de revisão (seção 7):

Então:

- parar imediatamente
- não continuar outros grupos
- não atualizar backlog
- reportar erro detalhado ao usuário
- aguardar instruções

---

# 9. Atualizar backlog

Após sucesso completo da fase:

## Atualizar

Marcar como `[x]`:

- todos os steps executados

### EXCETO

- step de verificação da fase

Esse deve ser marcado manualmente pelo usuário.

---

## Atualizar Log de Execução

Adicionar:

- data/hora
- fase executada
- groups paralelos/sequenciais
- agents executados
- modelo usado (`haiku`/`sonnet`)
- resultado da revisão (aprovado direto / nº de retrabalhos por step)
- arquivos alterados
- decisões importantes

---

# 10. Relatório final

Exibir obrigatoriamente:

## Execução

- quantidade de steps executados
- quantidade de grupos
- grupos paralelos
- grupos sequenciais

---

## Agents executados

Exemplo:

```txt
Grupo Paralelo 1
- Fase 1: Agente Reorganizador de Namespaces → sonnet
- Fase 1: Agente Atualizador de Imports → haiku

Grupo Sequencial 2
- Fase 1: Agente Removedor de Legados → haiku
```

---

## Arquivos

Listar:

- arquivos criados
- arquivos modificados
- arquivos movidos
- arquivos removidos

---

## Verificação

Exibir:

- comandos de verificação da fase
- checklist manual do usuário

---

## Próximo passo

Exibir sempre:

```txt
Após verificar, marque:

[ ] Verificação Fase N

como:

[x] Verificação Fase N

no backlog e execute novamente:

/execute-phase <slug>
```

---

# Regras finais

## Nunca

- commitar
- fazer push
- executar próxima fase automaticamente
- ignorar step de verificação
- atualizar backlog parcialmente após erro

---

# Objetivo do fluxo

Garantir:

- execução previsível
- isolamento de responsabilidade
- paralelismo seguro
- rastreabilidade
- facilidade de debugging
- controle manual do usuário
- execução incremental confiável