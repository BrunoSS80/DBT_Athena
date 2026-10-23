# DBT Athena - Projeto de Estudo em Engenharia de Dados

Bem-vindo ao projeto **DBT Athena**!

Este repositório é um projeto de estudo para praticar o **dbt (Data Build Tool)** com o adapter **dbt-athena**, utilizando o Amazon Athena como engine de consultas e o AWS Glue Data Catalog como catálogo de dados. O fluxo demonstra como declarar fontes, organizar transformações SQL em modelos reutilizáveis, documentar colunas e validar regras de qualidade com testes.

---

# 🏗️ Arquitetura do Projeto

```text
  Arquivos de exemplo (CSV)                   Amazon S3
  data/jaffle_shop_*.csv                       │
  data/stripe_payments.csv                     │
          │                                    │
          └── Preparação e carga dos dados ────┘
                         │
                         ▼
              AWS Glue Data Catalog
              awsdatacatalog.db-dbt
              ├── customers_data
              ├── orders_data
              └── payments_data
                         │
                         ▼
                 Amazon Athena
                         │
                         ▼
               dbt-athena / DBT
                 ┌───────┴────────┐
                 ▼                ▼
             Staging          Modelos analíticos
          stg_customers       customers_360
          stg_orders          customers_payments
          stg_payments        month_sales
                 │                │
                 └───────┬────────┘
                         ▼
                     Testes dbt
            unicidade, nulos, relacionamentos
                  e valores aceitos
```

### Fontes

As fontes são declaradas em `athena/models/schema.yml` e apontam para o catálogo `awsdatacatalog`, schema `db-dbt` e tabelas `customers_data`, `orders_data` e `payments_data`. Essas tabelas precisam existir no Glue Data Catalog e estar acessíveis pelo Athena antes da execução dos modelos.

Os CSVs do diretório `data/` são dados utilizados no projeto. O dbt não carrega esses arquivos automaticamente: é necessário armazená-los em um bucket S3 e criar as tabelas externas correspondentes no Glue utilizando o Glue Crawler.

### Modelos

- **`stg_customers`**: padroniza o identificador do cliente para `customer_id`.
- **`stg_orders`**: padroniza os identificadores do pedido e do cliente.
- **`stg_payments`**: padroniza os campos de pagamento e relacionamento com pedidos.
- **`customers_360`**: reúne dados do cliente, primeira e última compra e quantidade de pedidos.
- **`customers_payments`**: agrega o valor de pagamentos bem-sucedidos associados a pedidos válidos por cliente.
- **`month_sales`**: conta os pedidos por mês e ano.

Os modelos analíticos utilizam `ref()` para explicitar dependências entre modelos. Os modelos de staging usam `source()` para referenciar as tabelas de origem.

### Testes de qualidade

O schema declara testes para verificar unicidade e ausência de nulos em identificadores, integridade dos relacionamentos entre pedidos, clientes e pagamentos, e os status permitidos para pedidos. Execute `dbt test` para validar essas regras no Athena.

---

# 📚 O que este projeto permite estudar

- Organização de um projeto dbt e configuração do adapter `dbt-athena`.
- Declaração de fontes com `source()` e dependências entre modelos com `ref()`.
- Separação entre modelos de staging e modelos de negócio.
- Transformações SQL executadas no Amazon Athena.
- Documentação de modelos e testes de dados em YAML.
- Customização de macro SQL para criação de tabelas no Athena.
- Configuração de credenciais AWS e local de staging de consultas.

---

# ▶️ Como Executar

## 1. Pré-requisitos

- Python compatível com as versões instaladas pelo ambiente do projeto.
- Uma conta AWS com acesso ao Amazon Athena, AWS Glue Data Catalog e a um bucket S3.
- As tabelas de origem `customers_data`, `orders_data` e `payments_data` criadas no database/schema do Glue.
- Um workgroup do Athena e um diretório S3 para os resultados intermediários das consultas.

O usuário ou role AWS precisa ter permissão para executar consultas no Athena, ler as tabelas e os objetos de origem no S3, acessar o Glue Data Catalog e gravar/ler os resultados no bucket de staging.

## 2. Instale as dependências

Na raiz do repositório, crie e ative um ambiente virtual e instale o dbt Core com o adapter Athena:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Confirme a instalação:

```bash
dbt --version
```

## 3. Configure as credenciais AWS

Configure as credenciais por um perfil AWS local, por exemplo com `AWS CLI` utilizando `aws configure`. Não coloque chaves AWS no repositório.

Crie o arquivo `~/.dbt/profiles.yml` com o profile `athena`, correspondente ao valor `profile` em `athena/dbt_project.yml`. Substitua os exemplos pelos valores da sua conta:

```yaml
athena:
  outputs:
    dev:
      database: awsdatacatalog
      region_name: us-east-1
      s3_data_dir: s3://[SEU-BUCKET]/[PASTA DADOS BRUTOS]
      s3_staging_dir: s3://[SEU-BUCKET]/[PASTA DOS RESULTADOS DE QUERY ATHENA]/
      schema: dbt_dev
      threads: 1
      type: athena
  target: dev
```

`database` identifica o catálogo Athena e `schema` define o schema de destino dos modelos. Ajuste a região, o workgroup, o catálogo, o schema e o perfil AWS conforme sua infraestrutura. O bucket de staging precisa existir e ser gravável pelas credenciais utilizadas.

Podemos executar fora da pasta de trabalho do projeto o comando `dbt init` para gerar o arquivo `profiles.yml` de forma mais prática na pasta `~/.dbt/`

## 4. Valide a conexão

Execute a partir da raiz do repositório:

```bash
dbt debug --project-dir athena
```

O comando verifica a configuração do projeto, encontra o profile e testa a conexão com o Athena.

## 5. Execute os modelos

Com as fontes configuradas e acessíveis, execute:

```bash
dbt run --project-dir athena 
```

O dbt compila os modelos SQL e os executa no Athena, criando ou atualizando as relações no schema de destino configurado no profile.

## 6. Execute os testes

```bash
dbt test --project-dir athena
```

Também é possível executar modelos e testes em um único comando:

```bash
dbt build --project-dir athena
```

## Comandos úteis

```bash
# Visualizar o grafo e a documentação local do projeto
dbt docs generate --project-dir athena
dbt docs serve --project-dir athena
```

---

# 📁 Estrutura do Repositório

```text
.
├── data/                         # CSVs para preparar as fontes
├── athena/
│   ├── dbt_project.yml            # Configuração do projeto e nome do profile
│   ├── macros/                    # Macros SQL, incluindo customização para Athena
│   ├── models/
│   │   ├── staging/               # Modelos de preparação das fontes
│   │   ├── customers_360.sql
│   │   ├── customers_payments.sql
│   │   ├── month_sales.sql
│   │   └── schema.yml              # Fontes, documentação e testes
│   └── README.md                  # README inicial do scaffold dbt
└── requirements.txt               # dbt Core e dbt-athena
```

---

# 🛠️ Tecnologias Utilizadas

- **dbt Core**
- **dbt-athena**
- **Amazon Athena**
- **AWS Glue Data Catalog**
- **Amazon S3**
- **SQL e YAML**
- **Python**

---

# 🎯 Objetivo

Aprender os conceitos fundamentais do dbt por meio de um fluxo analítico executado no Amazon Athena: conectar dados de origem, criar transformações SQL modulares e documentadas, gerenciar dependências entre modelos e aplicar testes para aumentar a confiança nos dados.

---

## 🧑‍💻 Autor

Desenvolvido por **Bruno Severgnini da Silva**

📌 Conecte-se comigo:
- LinkedIn: https://www.linkedin.com/in/bruno-severgnini/
- GitHub: https://github.com/BrunoSS80