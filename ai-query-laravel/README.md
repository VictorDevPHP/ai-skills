# AI Query Laravel

Esta skill documenta como usar o pacote `eloquent-dsl/ai-query` em projetos Laravel para que agentes de IA gerem consultas por meio de uma DSL segura, validada e executável.

O objetivo dela e simples: evitar que copilotos e assistentes escrevam queries Eloquent diretamente, fora das regras do dominio ou sem validacao. Em vez disso, o agente deve primeiro inspecionar o schema exposto pelo projeto e depois montar um payload `actions` compativel com a DSL do pacote.

## O que e a skill

A skill e um contexto publicado em Markdown para ferramentas de IA, como:

- GitHub Copilot
- Cursor
- Claude
- qualquer integracao generica

Esse contexto ensina a ferramenta a:

- entender por que o pacote existe;
- descobrir os models disponiveis com `php artisan ai:schema`;
- usar o schema retornado como contrato;
- montar consultas somente com a DSL suportada;
- nunca escrever Eloquent direto para atender uma solicitacao.

## Regra principal

Nunca escrever Eloquent direto para responder um pedido.

Sempre usar a DSL do `eloquent-dsl/ai-query`.

## O que foi adicionado

## Novo comando `ai:schema`

Arquivo:

- `src/Commands/AiSchemaCommand.php`

Suporta:

```bash
php artisan ai:schema
php artisan ai:schema "App\Models\User"
```

Comportamento:

- sem argumento, descobre models em `App\Models\*`;
- com argumento, gera o schema de um model especifico;
- usa reflection para montar:
  - `table`;
  - `fields`, priorizando `fillable` com fallback para schema/colunas;
  - `relations`, no formato `tipo -> ClasseRelacionada`, por exemplo `hasMany -> App\Models\Post`;
- imprime JSON no `stdout`;
- usa o FQCN do model como chave principal do JSON.

Exemplo de uso esperado:

```bash
php artisan ai:schema
php artisan ai:schema "App\Models\User"
```

## Novo comando `ai:install`

Arquivo:

- `src/Commands/AiInstallCommand.php`

Flags implementadas:

```bash
php artisan ai:install --all
php artisan ai:install --copilot
php artisan ai:install --cursor
php artisan ai:install --claude
php artisan ai:install --generic
```

Comportamento:

- sem flags, abre selecao interativa por ferramenta;
- confirma antes de cada escrita;
- se o destino ja existir, faz append no final;
- se o destino nao existir, cria o arquivo;
- exibe no output o caminho publicado ou anexado.

## Templates criados

Diretorio:

- `resources/ai-skills/`

Arquivos:

- `copilot.md`
- `cursor.mdc`
- `claude.md`
- `generic.md`

Todos os templates incluem:

- explicacao do pacote e da motivacao;
- instrucao para rodar `ai:schema`;
- DSL completa com todos os tipos suportados;
- exemplos reais;
- regra explicita de nunca usar Eloquent direto e sempre usar a DSL.

## Service Provider atualizado

Arquivo:

- `src/AIQueryServiceProvider.php`

Atualizacoes:

- registro dos comandos `AiSchemaCommand` e `AiInstallCommand`;
- `vendor:publish` com a tag `ai-skills` para publicar os templates das ferramentas;
- publicacao de `config/ai-query.php`, alem da tag ja existente `ai-query-config`.

## Como instalar

## 1. Instale o pacote

Se o pacote ainda nao estiver no projeto Laravel:

```bash
composer require eloquent-dsl/ai-query
```

## 2. Publique a configuracao e os templates

Para publicar a configuracao:

```bash
php artisan vendor:publish --tag=ai-query-config
```

Para publicar os templates de skill:

```bash
php artisan vendor:publish --tag=ai-skills
```

Se quiser publicar tudo que o provider expoe:

```bash
php artisan vendor:publish --provider="EloquentDsl\AIQuery\AIQueryServiceProvider"
```

## 3. Instale a skill para a ferramenta desejada

Escolha uma das opcoes abaixo:

```bash
php artisan ai:install --copilot
php artisan ai:install --cursor
php artisan ai:install --claude
php artisan ai:install --generic
```

Ou instale todas:

```bash
php artisan ai:install --all
```

Se preferir escolher interativamente:

```bash
php artisan ai:install
```

## Fluxo obrigatorio para qualquer agente

Antes de gerar uma query:

1. Rode `php artisan ai:schema` para obter o mapa atual de models.
2. Se necessario, rode `php artisan ai:schema "App\Models\User"`.
3. Use o schema retornado como contrato.
4. Monte o payload `actions` com base apenas nos campos e relacoes permitidos.
5. Execute a consulta via `AIQuery`.

## DSL suportada

```php
[
    'model' => App\Models\User::class,
    'actions' => [
        ['type' => 'select', 'fields' => ['id', 'name', 'email']],
        ['type' => 'where', 'field' => 'email', 'operator' => 'like', 'value' => '%gmail%'],
        ['type' => 'orWhere', 'field' => 'name', 'operator' => 'like', 'value' => '%Ana%'],
        ['type' => 'whereIn', 'field' => 'id', 'values' => [1, 2, 3]],
        ['type' => 'whereBetween', 'field' => 'created_at', 'values' => ['2026-01-01', '2026-12-31']],
        ['type' => 'join', 'table' => 'posts'],
        ['type' => 'with', 'relation' => 'posts'],
        [
            'type' => 'whereHas',
            'relation' => 'posts',
            'filters' => [
                ['field' => 'title', 'operator' => 'like', 'value' => '%Laravel%'],
            ],
        ],
        ['type' => 'orderBy', 'field' => 'created_at', 'direction' => 'desc'],
        ['type' => 'limit', 'value' => 10],
        ['type' => 'paginate', 'value' => 15],
    ],
]
```

## Exemplos reais

Exemplo 1: usuarios corporativos com posts carregados e limite de retorno.

```php
use App\Models\User;
use EloquentDsl\AIQuery\AIQuery;

$dsl = [
    'model' => User::class,
    'actions' => [
        ['type' => 'select', 'fields' => ['id', 'name', 'email']],
        ['type' => 'where', 'field' => 'email', 'operator' => 'like', 'value' => '%@empresa.com'],
        ['type' => 'with', 'relation' => 'posts'],
        ['type' => 'orderBy', 'field' => 'created_at', 'direction' => 'desc'],
        ['type' => 'limit', 'value' => 20],
    ],
];

$users = AIQuery::for(User::class)->fromArray($dsl)->get();
```

Exemplo 2: paginacao de posts por intervalo de data.

```php
use App\Models\Post;
use EloquentDsl\AIQuery\AIQuery;

$dsl = [
    'model' => Post::class,
    'actions' => [
        ['type' => 'whereBetween', 'field' => 'created_at', 'values' => ['2026-01-01', '2026-01-31']],
        ['type' => 'orderBy', 'field' => 'id', 'direction' => 'desc'],
        ['type' => 'paginate', 'value' => 15],
    ],
];

$posts = AIQuery::for(Post::class)->fromArray($dsl)->get();
```

## Testes

Os testes foram atualizados para cobrir:

- saida JSON do `ai:schema` para model especifico;
- `ai:install --generic` criando arquivo;
- `ai:install --generic` fazendo append quando o destino ja existe.

Execucao informada:

```bash
vendor/bin/phpunit
```

Resultado:

```text
OK (6 tests, 23 assertions)
```

## Resumo pratico

Se voce estiver configurando uma ferramenta de IA para esse pacote, o caminho recomendado e:

1. publicar os templates com `vendor:publish`;
2. instalar a skill com `ai:install`;
3. rodar `ai:schema` antes de qualquer solicitacao de consulta;
4. exigir sempre o uso da DSL;
5. bloquear consultas Eloquent escritas manualmente pelo agente.
