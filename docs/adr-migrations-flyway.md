# ADR 001: Estratégia de Banco de Dados Compartilhado (EF Core Migrations vs. Flyway)

## 1. O Contexto
O projeto KURA possui dois backends distintos que compartilham o mesmo banco de dados Oracle 19c:
- **API .NET (Clínica):** Gerencia o domínio operacional (Pets, Clínicas, Eventos).
- **API Java (Tutor):** Gerencia identidade e agendamentos (Tutor, Contas, Consentimentos).

## 2. O Problema (Conflito de Ownership)
Na arquitetura padrão, frameworks modernos como o Entity Framework Core (no .NET) e o Hibernate (no Java) tentam assumir o controle total da estrutura do banco de dados (gerenciamento de DDL). 

Se ambas as aplicações rodarem suas ferramentas de migração de forma isolada e autônoma, ocorrerão graves conflitos de concorrência. O .NET não saberá das tabelas criadas pelo Java, o Java tentará sobrescrever regras do .NET, resultando em corrupção do schema e tabelas duplicadas.

## 3. O Critério de Avaliação (FIAP) e o Risco
A rubrica de avaliação do Challenge FIAP exige explicitamente na disciplina de .NET:
> **".NET | Uso de Migrations → 5 pts"**

Abandonar completamente o EF Core Migrations em favor de uma ferramenta externa custaria 5 pontos na avaliação da disciplina. Precisamos comprovar o domínio da ferramenta técnica exigida na ementa, sem comprometer a estabilidade arquitetural do projeto integrado.

## 4. A Decisão Arquitetural: Abordagem Híbrida
Para garantir a estabilidade do banco compartilhado (padrão de mercado) **E** assegurar a pontuação máxima na rubrica de avaliação, adotaremos um fluxo híbrido: **EF Core Migrations (Gerador) + Flyway (Executor)**.

### O que é o Flyway?
É uma ferramenta de versionamento de banco de dados agnóstica de linguagem. Ele lê arquivos `.sql` puros (ex: `V3__add_tabela_invite.sql`) e aplica as mudanças no Oracle de forma estritamente sequencial, atuando como o único "árbitro" da base de dados.

### Como usar: O Novo Fluxo Híbrido
O .NET continuará criando e mapeando as Migrations localmente, mantendo a pasta `Migrations` populada no repositório para fins de avaliação, mas **NÃO** aplicará as mudanças diretamente no banco (não usaremos `Database.Migrate()` em runtime).

**Passo a passo do desenvolvedor (.NET):**
1. **Alteração do Domínio:** O desenvolvedor altera as Entities e os arquivos de Configuration.
2. **Geração da Migration:** Executa o comando padrão:
   `dotnet ef migrations add AdicionaTabelaInvite`
   *(Isso gera o arquivo `.cs` na pasta Migrations, garantindo a prova acadêmica de uso da ferramenta e os 5 pontos).*
3. **Extração do SQL:** Em vez de rodar o update direto, o desenvolvedor extrai o script DDL:
   `dotnet ef migrations script {MigrationAnterior} AdicionaTabelaInvite`
4. **Entrega ao Flyway:** O desenvolvedor copia o código SQL gerado pelo EF Core, cria um arquivo versionado (ex: `V4__Adiciona_Tabela_Invite.sql`) e entrega para a pipeline do Flyway.

## 5. Impactos e Responsabilidades no Time

* **Felipe (.NET):** Mantém as configurations atualizadas e gera as migrations em C#. A chamada `context.Database.Migrate()` deve ser estritamente removida do `Program.cs` para evitar execução acidental em produção.
* **Nikolas (Java):** Deve configurar a propriedade `spring.jpa.hibernate.ddl-auto=validate` (ou `none`). O Hibernate apenas validará se o schema gerado pelo Flyway está de acordo com as entidades Java, sem tentar criar ou alterar tabelas.
* **Clayton (DevOps/BD):** Assume a responsabilidade de centralizar os scripts `.sql` versionados e rodar o Flyway contra o Oracle (local ou na FIAP) antes da inicialização das APIs.

## 6. Conclusão
Esta decisão arquitetural resolve o problema técnico de banco de dados compartilhado através de uma ferramenta madura (Flyway), ao mesmo tempo em que cumpre rigorosamente os critérios da rubrica de avaliação da FIAP, demonstrando capacidade de abstração e aplicação real de engenharia de software em um ecossistema com múltiplos backends.
