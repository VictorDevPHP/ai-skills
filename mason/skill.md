# mason:new-skill

Guia interativo para criar uma nova skill no padrão do projeto. Pergunta escopo (global ou local), nome, descrição e estrutura desejada, depois gera o `skill.md` no lugar certo.

## Uso

```
/mason:new-skill [<nome>]
```

- Sem argumentos: modo interativo completo
- `<nome>`: pula a pergunta de nome e já usa o fornecido

## Comportamento

### 1. Coletar informações

Perguntar ao usuário (apenas o que não foi fornecido via argumento):

**a) Escopo**

```
Onde essa skill deve ficar?
  [1] Global — disponível em todos os projetos (~/.claude/skills/)
  [2] Local  — apenas neste projeto (.claude/skills/)
```

**b) Nome**

- Formato para skills simples: `kebab-case` (ex: `lint-fix`, `new-plan`)
- Formato para skills com namespace: `namespace:nome` (ex: `mason:new-skill`, `codex:rescue`)
- Perguntar se deve ter namespace. Se sim, qual namespace.

**c) Descrição de uma linha**

Usada no `skill.md` como subtítulo e para o usuário entender rapidamente o propósito.

**d) Trigger**

Como a skill deve ser invocada?
- Slash command (`/nome`)
- Contexto automático (Claude carrega quando relevante)
- Ambos

**e) Estrutura**

Perguntar se a skill terá:
- Apenas comportamento (instruções de como agir)
- Uso com argumentos (ex: `/new-plan <slug> "<titulo>"`)
- Subcomandos

### 2. Determinar destino

Skills com namespace `namespace:nome` ficam em um diretório nomeado pelo namespace:
- Global: `C:\Users\victo\.claude\skills\<namespace>\skill.md`
- Local: `.claude/skills\<namespace>\skill.md`

Skills sem namespace ficam em diretório próprio:
- Global: `C:\Users\victo\.claude\skills\<nome>\skill.md`
- Local: `.claude/skills\<nome>\skill.md`

Verificar se já existe. Se sim, perguntar se quer sobrescrever.

### 3. Gerar o skill.md

Usar o template abaixo, preenchendo com as informações coletadas:

```markdown
# <trigger>

<Descrição de uma linha.>

## Uso

\`\`\`
/<nome> [argumentos]
\`\`\`

## Comportamento

### 1. <Primeira etapa>

<Descrição do que fazer.>

### 2. <Segunda etapa>

<Descrição do que fazer.>

## Regras

- <Regra importante 1>
- <Regra importante 2>
```

Adaptar o template conforme a estrutura escolhida:
- Skill sem argumentos: omitir seção `## Uso`
- Skill com subcomandos: adicionar seção `## Subcomandos`
- Skill de contexto automático: substituir `## Uso` por `## Quando aplicar`

### 4. Criar o arquivo

Criar o `skill.md` no destino determinado.

### 5. Confirmar

Exibir:
- Caminho do arquivo criado
- Escopo (global ou local)
- Como invocar: `/<nome>` ou contexto automático
- Próximo passo: editar o `skill.md` para detalhar o comportamento

## Regras

- Nunca sobrescrever sem confirmar
- O `skill.md` gerado é um ponto de partida — instruir o usuário a revisá-lo
- Skills globais vão para `C:\Users\victo\.claude\skills\`, nunca para repositórios intermediários
- Skills locais vão para `.claude/skills/` do projeto atual e são versionadas com o projeto
