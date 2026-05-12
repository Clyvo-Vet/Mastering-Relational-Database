-- ============================================================================
-- KURA — Sistema de Gestão Veterinária
-- Cliente: Clyvo Vet (Challenge FIAP 2026)
-- Banco: Oracle 19c+
-- Notação: 3FN | Constraints nomeadas | Sequences para PKs
-- ============================================================================
-- VERSÃO: v3 (merged — DDL v3 + Carga/Procedures/Blocos da v2)
-- ALTERAÇÕES DA v3 EM RELAÇÃO À v2 (DDL):
--   [1] AGENDAMENTO       → coluna NR_VERSION (optimistic locking JPA @Version)
--   [2] CONTA_TUTOR       → colunas DS_REFRESH_TOKEN_HASH, DT_REFRESH_EXPIRA,
--                           ID_INVITE_USADO + FK/UK para INVITE_TUTOR
--   [3] IDEMPOTENCY_KEY   → nova tabela + SEQ_IDEMPOTENCY_KEY
--   [4] INVITE_TUTOR      → nova tabela + SEQ_INVITE_TUTOR (invite-based onboarding)
-- RESTAURADO DA v2 (merge):
--   [5] CARGA DE DADOS    → INSERTs iniciais (CLINICA, ESPECIE, RACA, VET, TUTOR,
--                           PET, TUTOR_PET, TIPO_EVENTO, EVENTO_CLINICO, VACINA,
--                           MEDICAMENTO, PRESCRICAO, PRESCRICAO_MED, EXAME,
--                           DOCUMENTO, NOTIFICACAO, CONTA_TUTOR, CONSENTIMENTO,
--                           AGENDAMENTO, DISPOSITIVO_IOT, LEITURA_TEMP, ALERTA_TEMP)
--   [6] PROCEDURES        → PRC_LOG_ERRO, PRC_INSERIR_CLINICA, PRC_INSERT_ESPECIE,
--                           PRC_INSERT_MEDICAMENTO, PRC_INSERT_TIPO_EVENTO,
--                           PRC_INSERT_VETERINARIO, PRC_INSERIR_TUTOR,
--                           PRC_INSERT_RACA, PRC_INSERIR_PET,
--                           PRC_INSERT_TUTOR_PET, PRC_INSERT_EVENTO,
--                           PRC_INSERT_VACINA, PRC_INSERT_PRESCRICAO, PRC_INSERT_EXAME
--   [7] BLOCOS ANÔNIMOS   → Relatórios 1 e 2, leitura de pets, cursores explícitos
-- ============================================================================
-- ARQUITETURA DE DOMÍNIOS:
--   .NET (Backend Clínica - Felipe) — domínio operacional/clínico
--     CLINICA, VETERINARIO, TUTOR, PET, ESPECIE, RACA,
--     EVENTO_CLINICO, TIPO_EVENTO, VACINA, PRESCRICAO,
--     MEDICAMENTO, EXAME, DOCUMENTO, NOTIFICACAO, LOG_ERRO,
--     INVITE_TUTOR (gerado pela clínica, consultado pelo Java)
--
--   Java (Backend Tutor - Nikolas) — domínio identidade/agendamento
--     CONTA_TUTOR, CONSENTIMENTO, AGENDAMENTO, IDEMPOTENCY_KEY
--
--   Compartilhada (ambos leem, ninguém isolado escreve):
--     TUTOR (cadastro pelo .NET, conta pelo Java via CONTA_TUTOR)
-- ============================================================================

-- ============================================================================
-- 0. LIMPEZA (executar em ambiente de dev — ordem reversa de dependência)
-- ============================================================================

-- DROP TABLE IDEMPOTENCY_KEY          CASCADE CONSTRAINTS;
-- DROP TABLE LOG_ERRO                 CASCADE CONSTRAINTS;
-- DROP TABLE NOTIFICACAO              CASCADE CONSTRAINTS;
-- DROP TABLE CONSENTIMENTO            CASCADE CONSTRAINTS;
-- DROP TABLE AGENDAMENTO              CASCADE CONSTRAINTS;
-- DROP TABLE CONTA_TUTOR              CASCADE CONSTRAINTS;
-- DROP TABLE INVITE_TUTOR             CASCADE CONSTRAINTS;
-- DROP TABLE DOCUMENTO                CASCADE CONSTRAINTS;
-- DROP TABLE PRESCRICAO_MEDICAMENTO   CASCADE CONSTRAINTS;
-- DROP TABLE PRESCRICAO               CASCADE CONSTRAINTS;
-- DROP TABLE EXAME                    CASCADE CONSTRAINTS;
-- DROP TABLE VACINA                   CASCADE CONSTRAINTS;
-- DROP TABLE EVENTO_CLINICO           CASCADE CONSTRAINTS;
-- DROP TABLE TIPO_EVENTO              CASCADE CONSTRAINTS;
-- DROP TABLE TUTOR_PET                CASCADE CONSTRAINTS;
-- DROP TABLE PET                      CASCADE CONSTRAINTS;
-- DROP TABLE RACA                     CASCADE CONSTRAINTS;
-- DROP TABLE ESPECIE                  CASCADE CONSTRAINTS;
-- DROP TABLE TUTOR                    CASCADE CONSTRAINTS;
-- DROP TABLE VETERINARIO              CASCADE CONSTRAINTS;
-- DROP TABLE CLINICA                  CASCADE CONSTRAINTS;
-- DROP TABLE MEDICAMENTO              CASCADE CONSTRAINTS;
-- DROP TABLE ALERTA_TEMPERATURA       CASCADE CONSTRAINTS;
-- DROP TABLE LEITURA_TEMPERATURA      CASCADE CONSTRAINTS;
-- DROP TABLE DISPOSITIVO_IOT          CASCADE CONSTRAINTS;

-- DROP SEQUENCE SEQ_CLINICA;
-- DROP SEQUENCE SEQ_VETERINARIO;
-- DROP SEQUENCE SEQ_TUTOR;
-- DROP SEQUENCE SEQ_ESPECIE;
-- DROP SEQUENCE SEQ_RACA;
-- DROP SEQUENCE SEQ_PET;
-- DROP SEQUENCE SEQ_TIPO_EVENTO;
-- DROP SEQUENCE SEQ_EVENTO_CLINICO;
-- DROP SEQUENCE SEQ_VACINA;
-- DROP SEQUENCE SEQ_MEDICAMENTO;
-- DROP SEQUENCE SEQ_PRESCRICAO;
-- DROP SEQUENCE SEQ_EXAME;
-- DROP SEQUENCE SEQ_DOCUMENTO;
-- DROP SEQUENCE SEQ_AGENDAMENTO;
-- DROP SEQUENCE SEQ_NOTIFICACAO;
-- DROP SEQUENCE SEQ_CONTA_TUTOR;
-- DROP SEQUENCE SEQ_CONSENTIMENTO;
-- DROP SEQUENCE SEQ_LOG_ERRO;
-- DROP SEQUENCE SEQ_DISPOSITIVO_IOT;
-- DROP SEQUENCE SEQ_LEITURA_TEMP;
-- DROP SEQUENCE SEQ_ALERTA_TEMP;
-- DROP SEQUENCE SEQ_IDEMPOTENCY_KEY;
-- DROP SEQUENCE SEQ_INVITE_TUTOR;

-- ============================================================================
-- 1. SEQUENCES (auto-incremento)
-- ============================================================================

CREATE SEQUENCE SEQ_CLINICA          START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_VETERINARIO      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_TUTOR            START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_ESPECIE          START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_RACA             START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_PET              START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_TIPO_EVENTO      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_EVENTO_CLINICO   START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_VACINA           START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_MEDICAMENTO      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_PRESCRICAO       START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_EXAME            START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_DOCUMENTO        START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_AGENDAMENTO      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_NOTIFICACAO      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_CONTA_TUTOR      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_CONSENTIMENTO    START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_LOG_ERRO         START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_DISPOSITIVO_IOT  START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_LEITURA_TEMP     START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_ALERTA_TEMP      START WITH 1 INCREMENT BY 1 NOCACHE;
-- [v3] Novas sequences
CREATE SEQUENCE SEQ_IDEMPOTENCY_KEY  START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_INVITE_TUTOR     START WITH 1 INCREMENT BY 1 NOCACHE;

-- ============================================================================
-- 2. ENTIDADES INDEPENDENTES (sem FKs)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CLINICA
-- Domínio: .NET (Felipe) | Acessada também por Java em leituras
-- Razão: instituição que opera o sistema. Pai de Veterinario.
-- ----------------------------------------------------------------------------
CREATE TABLE CLINICA (
    ID_CLINICA       NUMBER(10)       DEFAULT SEQ_CLINICA.NEXTVAL NOT NULL,
    NM_CLINICA       VARCHAR2(120)    NOT NULL,
    NR_CNPJ          VARCHAR2(18)     NOT NULL,
    NM_RAZAO_SOCIAL  VARCHAR2(150),
    DS_ENDERECO      VARCHAR2(200)    NOT NULL,
    NM_CIDADE        VARCHAR2(80)     NOT NULL,
    SG_UF            CHAR(2)          NOT NULL,
    NR_CEP           VARCHAR2(9)      NOT NULL,
    DS_TELEFONE      VARCHAR2(20),
    DS_EMAIL         VARCHAR2(120),
    DT_CADASTRO      TIMESTAMP        DEFAULT SYSTIMESTAMP NOT NULL,
    ST_ATIVA         CHAR(1)          DEFAULT 'S' NOT NULL,
    CONSTRAINT PK_CLINICA          PRIMARY KEY (ID_CLINICA),
    CONSTRAINT UK_CLINICA_CNPJ     UNIQUE (NR_CNPJ),
    CONSTRAINT CK_CLINICA_ATIVA    CHECK (ST_ATIVA IN ('S','N')),
    CONSTRAINT CK_CLINICA_UF       CHECK (LENGTH(SG_UF) = 2)
);

COMMENT ON TABLE  CLINICA            IS 'Clínicas e hospitais veterinários cadastrados no KURA';
COMMENT ON COLUMN CLINICA.ID_CLINICA IS 'PK auto-incremento via SEQ_CLINICA';
COMMENT ON COLUMN CLINICA.NR_CNPJ    IS 'CNPJ formatado XX.XXX.XXX/0001-XX — UNIQUE para evitar duplicidade';
COMMENT ON COLUMN CLINICA.ST_ATIVA   IS 'S=ativa, N=inativa (soft delete)';

-- ----------------------------------------------------------------------------
-- ESPECIE
-- Domínio: .NET | Tabela de domínio (lookup table)
-- Razão: separar de RACA pois muitas raças por espécie
-- ----------------------------------------------------------------------------
CREATE TABLE ESPECIE (
    ID_ESPECIE       NUMBER(5)        DEFAULT SEQ_ESPECIE.NEXTVAL NOT NULL,
    NM_ESPECIE       VARCHAR2(50)     NOT NULL,
    CONSTRAINT PK_ESPECIE      PRIMARY KEY (ID_ESPECIE),
    CONSTRAINT UK_ESPECIE_NOME UNIQUE (NM_ESPECIE)
);

COMMENT ON TABLE ESPECIE IS 'Tipos de animais atendidos: Cão, Gato, Ave, Réptil etc.';

-- ----------------------------------------------------------------------------
-- MEDICAMENTO
-- Domínio: .NET | Tabela de domínio
-- Razão: catálogo central de medicamentos. Prescrição referencia, não duplica.
-- ----------------------------------------------------------------------------
CREATE TABLE MEDICAMENTO (
    ID_MEDICAMENTO   NUMBER(10)       DEFAULT SEQ_MEDICAMENTO.NEXTVAL NOT NULL,
    NM_MEDICAMENTO   VARCHAR2(120)    NOT NULL,
    NM_PRINCIPIO     VARCHAR2(120),
    DS_APRESENTACAO  VARCHAR2(80),
    ST_CONTROLADO    CHAR(1)          DEFAULT 'N' NOT NULL,
    CONSTRAINT PK_MEDICAMENTO    PRIMARY KEY (ID_MEDICAMENTO),
    CONSTRAINT CK_MED_CONTROLADO CHECK (ST_CONTROLADO IN ('S','N'))
);

COMMENT ON COLUMN MEDICAMENTO.NM_PRINCIPIO    IS 'Princípio ativo (ex: Oclacitinib)';
COMMENT ON COLUMN MEDICAMENTO.DS_APRESENTACAO IS 'Apresentação (ex: comprimido 16mg, frasco 50ml)';
COMMENT ON COLUMN MEDICAMENTO.ST_CONTROLADO   IS 'S=requer receita controlada (ANVISA)';

-- ----------------------------------------------------------------------------
-- TIPO_EVENTO
-- Domínio: .NET | Tabela de domínio
-- Razão: tipa o evento clínico (consulta, vacina, exame etc) sem hardcode
-- ----------------------------------------------------------------------------
CREATE TABLE TIPO_EVENTO (
    ID_TIPO_EVENTO   NUMBER(5)        DEFAULT SEQ_TIPO_EVENTO.NEXTVAL NOT NULL,
    NM_TIPO_EVENTO   VARCHAR2(50)     NOT NULL,
    DS_TIPO_EVENTO   VARCHAR2(200),
    CONSTRAINT PK_TIPO_EVENTO      PRIMARY KEY (ID_TIPO_EVENTO),
    CONSTRAINT UK_TIPO_EVENTO_NOME UNIQUE (NM_TIPO_EVENTO)
);

COMMENT ON TABLE TIPO_EVENTO IS 'Tipos: CONSULTA, TELEORIENTACAO, VACINA, PRESCRICAO, EXAME, PROCEDIMENTO, RETORNO';

-- ============================================================================
-- 3. ENTIDADES DEPENDENTES — NÍVEL 1
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VETERINARIO
-- Domínio: .NET | FK CLINICA
-- Razão: profissional vinculado a uma clínica. CRMV é único por UF.
-- ----------------------------------------------------------------------------
CREATE TABLE VETERINARIO (
    ID_VETERINARIO   NUMBER(10)       DEFAULT SEQ_VETERINARIO.NEXTVAL NOT NULL,
    ID_CLINICA       NUMBER(10)       NOT NULL,
    NM_VETERINARIO   VARCHAR2(120)    NOT NULL,
    NR_CRMV          VARCHAR2(15)     NOT NULL,
    SG_UF_CRMV       CHAR(2)          NOT NULL,
    DS_EMAIL         VARCHAR2(120)    NOT NULL,
    DS_TELEFONE      VARCHAR2(20),
    DS_ESPECIALIDADE VARCHAR2(100),
    DT_CADASTRO      TIMESTAMP        DEFAULT SYSTIMESTAMP NOT NULL,
    ST_ATIVO         CHAR(1)          DEFAULT 'S' NOT NULL,
    CONSTRAINT PK_VETERINARIO PRIMARY KEY (ID_VETERINARIO),
    CONSTRAINT FK_VET_CLINICA FOREIGN KEY (ID_CLINICA) REFERENCES CLINICA(ID_CLINICA),
    CONSTRAINT UK_VET_CRMV    UNIQUE (NR_CRMV, SG_UF_CRMV),
    CONSTRAINT UK_VET_EMAIL   UNIQUE (DS_EMAIL),
    CONSTRAINT CK_VET_ATIVO   CHECK (ST_ATIVO IN ('S','N'))
);

CREATE INDEX IDX_VET_CLINICA ON VETERINARIO(ID_CLINICA);

COMMENT ON COLUMN VETERINARIO.NR_CRMV    IS 'Numero do CRMV (registro profissional)';
COMMENT ON COLUMN VETERINARIO.SG_UF_CRMV IS 'UF do CRMV — CRMV é único por UF';

-- ----------------------------------------------------------------------------
-- TUTOR
-- Domínio: .NET (cadastro) | Java (lê para vincular CONTA_TUTOR)
-- Razão: dado pessoal do responsável pelo pet. NÃO contém credenciais — essas
--        ficam em CONTA_TUTOR (Java) para separar identidade (PII) de acesso.
-- ----------------------------------------------------------------------------
CREATE TABLE TUTOR (
    ID_TUTOR             NUMBER(10)   DEFAULT SEQ_TUTOR.NEXTVAL NOT NULL,
    ID_CLINICA           NUMBER(10)   NOT NULL,
    NM_TUTOR             VARCHAR2(120) NOT NULL,
    NR_CPF               VARCHAR2(14) NOT NULL,
    DT_NASCIMENTO        DATE,
    DS_EMAIL             VARCHAR2(120) NOT NULL,
    DS_TELEFONE          VARCHAR2(20) NOT NULL,
    DS_WHATSAPP          VARCHAR2(20),
    DS_ENDERECO          VARCHAR2(200),
    NM_CIDADE            VARCHAR2(80),
    SG_UF                CHAR(2),
    NR_CEP               VARCHAR2(9),
    DT_CADASTRO          TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL,
    ST_ATIVO             CHAR(1)      DEFAULT 'S' NOT NULL,
    -- Transparência LGPD (informação prestada no balcão durante cadastro presencial)
    -- Base legal de tratamento: art. 7º, V (execução de contrato) e VI (obrigação legal CFMV)
    -- Consentimentos para finalidades adicionais ficam em CONSENTIMENTO (Java)
    ST_AVISO_PRIVACIDADE CHAR(1)      DEFAULT 'N' NOT NULL,
    DT_AVISO_PRIVACIDADE TIMESTAMP,
    DS_VERSAO_AVISO      VARCHAR2(20),
    CONSTRAINT PK_TUTOR         PRIMARY KEY (ID_TUTOR),
    CONSTRAINT FK_TUTOR_CLINICA FOREIGN KEY (ID_CLINICA) REFERENCES CLINICA(ID_CLINICA),
    CONSTRAINT UK_TUTOR_CPF     UNIQUE (NR_CPF),
    CONSTRAINT UK_TUTOR_EMAIL   UNIQUE (DS_EMAIL),
    CONSTRAINT CK_TUTOR_ATIVO   CHECK (ST_ATIVO IN ('S','N')),
    CONSTRAINT CK_TUTOR_AVISO   CHECK (ST_AVISO_PRIVACIDADE IN ('S','N'))
);

CREATE INDEX IDX_TUTOR_CLINICA ON TUTOR(ID_CLINICA);

COMMENT ON TABLE  TUTOR                      IS 'Pessoa responsável pelo pet. Cadastrado pela clínica (.NET). Pode ou não ter conta no portal (CONTA_TUTOR).';
COMMENT ON COLUMN TUTOR.DS_WHATSAPP          IS 'Numero usado pela Luna (bot) para comunicação. Pode ser igual ao telefone.';
COMMENT ON COLUMN TUTOR.ST_AVISO_PRIVACIDADE IS 'S = tutor recebeu aviso de privacidade no cadastro presencial (transparência LGPD art. 6º VI)';
COMMENT ON COLUMN TUTOR.DS_VERSAO_AVISO      IS 'Versão do aviso de privacidade apresentado (ex: v1.0, v1.1) — rastreabilidade quando termo é atualizado';

-- ----------------------------------------------------------------------------
-- RACA
-- Domínio: .NET | FK ESPECIE
-- Razão: raça pertence a uma espécie. Importante para predisposições genéticas.
-- ----------------------------------------------------------------------------
CREATE TABLE RACA (
    ID_RACA          NUMBER(5)        DEFAULT SEQ_RACA.NEXTVAL NOT NULL,
    ID_ESPECIE       NUMBER(5)        NOT NULL,
    NM_RACA          VARCHAR2(80)     NOT NULL,
    DS_PREDISPOSICAO VARCHAR2(500),
    CONSTRAINT PK_RACA              PRIMARY KEY (ID_RACA),
    CONSTRAINT FK_RACA_ESPECIE      FOREIGN KEY (ID_ESPECIE) REFERENCES ESPECIE(ID_ESPECIE),
    CONSTRAINT UK_RACA_NOME_ESPECIE UNIQUE (NM_RACA, ID_ESPECIE)
);

CREATE INDEX IDX_RACA_ESPECIE ON RACA(ID_ESPECIE);

COMMENT ON COLUMN RACA.DS_PREDISPOSICAO IS 'Doenças/condições com predisposição (ex: Labrador → displasia coxofemoral, obesidade)';

-- ============================================================================
-- 4. ENTIDADE CENTRAL — PET
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PET
-- Domínio: .NET | FKs ESPECIE, RACA, VETERINARIO (responsável)
-- Razão: ID_PET é o "prontuário" — é a chave que tudo referencia.
-- DECISÃO: tutor vinculado via TUTOR_PET (associativa N:N) e não FK direta,
--          pois um pet pode ter mais de um tutor (casal, divisão de guarda).
-- ----------------------------------------------------------------------------
CREATE TABLE PET (
    ID_PET                NUMBER(10)   DEFAULT SEQ_PET.NEXTVAL NOT NULL,
    ID_ESPECIE            NUMBER(5)    NOT NULL,
    ID_RACA               NUMBER(5),
    ID_VETERINARIO_RESP   NUMBER(10),
    NM_PET                VARCHAR2(80) NOT NULL,
    DT_NASCIMENTO         DATE,
    SG_SEXO               CHAR(1)      NOT NULL,
    NR_PESO_KG            NUMBER(5,2),
    SG_PORTE              CHAR(1),
    ST_CASTRADO           CHAR(1)      DEFAULT 'N' NOT NULL,
    DS_PELAGEM            VARCHAR2(60),
    DS_ALERGIAS           VARCHAR2(500),
    DS_OBSERVACOES        VARCHAR2(1000),
    DT_CADASTRO           TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL,
    ST_ATIVO              CHAR(1)      DEFAULT 'S' NOT NULL,
    CONSTRAINT PK_PET               PRIMARY KEY (ID_PET),
    CONSTRAINT FK_PET_ESPECIE       FOREIGN KEY (ID_ESPECIE)          REFERENCES ESPECIE(ID_ESPECIE),
    CONSTRAINT FK_PET_RACA          FOREIGN KEY (ID_RACA)             REFERENCES RACA(ID_RACA),
    CONSTRAINT FK_PET_VETERINARIO   FOREIGN KEY (ID_VETERINARIO_RESP) REFERENCES VETERINARIO(ID_VETERINARIO),
    CONSTRAINT CK_PET_SEXO          CHECK (SG_SEXO IN ('M','F')),
    CONSTRAINT CK_PET_PORTE         CHECK (SG_PORTE IN ('P','M','G') OR SG_PORTE IS NULL),
    CONSTRAINT CK_PET_CASTRADO      CHECK (ST_CASTRADO IN ('S','N')),
    CONSTRAINT CK_PET_ATIVO         CHECK (ST_ATIVO IN ('S','N')),
    CONSTRAINT CK_PET_PESO_POSITIVO CHECK (NR_PESO_KG IS NULL OR NR_PESO_KG > 0)
);

CREATE INDEX IDX_PET_ESPECIE     ON PET(ID_ESPECIE);
CREATE INDEX IDX_PET_RACA        ON PET(ID_RACA);
CREATE INDEX IDX_PET_VETERINARIO ON PET(ID_VETERINARIO_RESP);

COMMENT ON TABLE  PET                     IS 'Animal atendido. ID_PET = prontuário único do paciente.';
COMMENT ON COLUMN PET.SG_PORTE            IS 'P=pequeno, M=médio, G=grande';
COMMENT ON COLUMN PET.ID_VETERINARIO_RESP IS 'Vet responsável principal — pode ser NULL (clínica em geral)';

-- ----------------------------------------------------------------------------
-- TUTOR_PET (associativa N:N entre TUTOR e PET)
-- Domínio: .NET | FKs TUTOR, PET
-- Razão: pet pode ter múltiplos tutores. Tutor pode ter múltiplos pets.
--        Modelar associativa desde o início evita refactor caro depois.
-- ----------------------------------------------------------------------------
CREATE TABLE TUTOR_PET (
    ID_TUTOR     NUMBER(10)  NOT NULL,
    ID_PET       NUMBER(10)  NOT NULL,
    DS_VINCULO   VARCHAR2(40) DEFAULT 'PROPRIETARIO' NOT NULL,
    DT_VINCULO   TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL,
    ST_PRINCIPAL CHAR(1)      DEFAULT 'S' NOT NULL,
    CONSTRAINT PK_TUTOR_PET       PRIMARY KEY (ID_TUTOR, ID_PET),
    CONSTRAINT FK_TUTOR_PET_TUTOR FOREIGN KEY (ID_TUTOR) REFERENCES TUTOR(ID_TUTOR),
    CONSTRAINT FK_TUTOR_PET_PET   FOREIGN KEY (ID_PET)   REFERENCES PET(ID_PET),
    CONSTRAINT CK_TP_PRINCIPAL    CHECK (ST_PRINCIPAL IN ('S','N')),
    CONSTRAINT CK_TP_VINCULO      CHECK (DS_VINCULO IN ('PROPRIETARIO','CO_TUTOR','CUIDADOR','TEMPORARIO'))
);

CREATE INDEX IDX_TP_PET ON TUTOR_PET(ID_PET);

COMMENT ON TABLE  TUTOR_PET              IS 'Vínculo N:N entre tutores e pets. Suporta casal compartilhando guarda.';
COMMENT ON COLUMN TUTOR_PET.ST_PRINCIPAL IS 'S=tutor principal (recebe notificações). Apenas 1 principal por pet recomendado via regra de negócio.';

-- ============================================================================
-- 5. EVENTOS CLÍNICOS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- EVENTO_CLINICO
-- Domínio: .NET | FKs PET, VETERINARIO, TIPO_EVENTO
-- Razão: tabela central de histórico longitudinal. Tudo que acontece com o
--        pet vira um evento. Vacina, Prescricao, Exame são "subtipos" via FKs.
-- DECISÃO: especialização por tabela — EVENTO_CLINICO tem dados comuns;
--          tabelas específicas (VACINA, PRESCRICAO, EXAME) detalham por tipo.
-- ----------------------------------------------------------------------------
CREATE TABLE EVENTO_CLINICO (
    ID_EVENTO        NUMBER(10)    DEFAULT SEQ_EVENTO_CLINICO.NEXTVAL NOT NULL,
    ID_PET           NUMBER(10)    NOT NULL,
    ID_VETERINARIO   NUMBER(10)    NOT NULL,
    ID_TIPO_EVENTO   NUMBER(5)     NOT NULL,
    DT_EVENTO        TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    DS_DIAGNOSTICO   VARCHAR2(500),
    DS_CID10_VET     VARCHAR2(20),
    DS_OBSERVACOES   VARCHAR2(2000),
    DS_MODALIDADE    VARCHAR2(20)  DEFAULT 'PRESENCIAL' NOT NULL,
    DT_REGISTRO      TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT PK_EVENTO_CLINICO PRIMARY KEY (ID_EVENTO),
    CONSTRAINT FK_EV_PET         FOREIGN KEY (ID_PET)           REFERENCES PET(ID_PET),
    CONSTRAINT FK_EV_VETERINARIO FOREIGN KEY (ID_VETERINARIO)   REFERENCES VETERINARIO(ID_VETERINARIO),
    CONSTRAINT FK_EV_TIPO        FOREIGN KEY (ID_TIPO_EVENTO)   REFERENCES TIPO_EVENTO(ID_TIPO_EVENTO),
    CONSTRAINT CK_EV_MODALIDADE  CHECK (DS_MODALIDADE IN ('PRESENCIAL','TELEORIENTACAO','TELEMONITORAMENTO'))
);

CREATE INDEX IDX_EV_PET         ON EVENTO_CLINICO(ID_PET);
CREATE INDEX IDX_EV_VETERINARIO ON EVENTO_CLINICO(ID_VETERINARIO);
CREATE INDEX IDX_EV_TIPO        ON EVENTO_CLINICO(ID_TIPO_EVENTO);
CREATE INDEX IDX_EV_DATA        ON EVENTO_CLINICO(DT_EVENTO DESC);

COMMENT ON TABLE  EVENTO_CLINICO               IS 'Núcleo da timeline do pet. Cada interação clínica = 1 evento.';
COMMENT ON COLUMN EVENTO_CLINICO.DS_CID10_VET  IS 'Classificação proprietária Clyvo CID-10-VET®';
COMMENT ON COLUMN EVENTO_CLINICO.DS_MODALIDADE IS 'Conformidade CFMV 1.465/2022 — tipo do atendimento';

-- ----------------------------------------------------------------------------
-- VACINA
-- Domínio: .NET | FK EVENTO_CLINICO (1:1 quando TIPO_EVENTO = VACINA)
-- Razão: dados específicos de aplicação de vacina (lote, validade, próxima dose)
-- ----------------------------------------------------------------------------
CREATE TABLE VACINA (
    ID_VACINA          NUMBER(10)    DEFAULT SEQ_VACINA.NEXTVAL NOT NULL,
    ID_EVENTO          NUMBER(10)    NOT NULL,
    NM_VACINA          VARCHAR2(80)  NOT NULL,
    NR_LOTE            VARCHAR2(40)  NOT NULL,
    NM_FABRICANTE      VARCHAR2(80),
    DT_APLICACAO       DATE          NOT NULL,
    DT_PROXIMA_DOSE    DATE,
    DS_LOCAL_APLICACAO VARCHAR2(80),
    CONSTRAINT PK_VACINA        PRIMARY KEY (ID_VACINA),
    CONSTRAINT FK_VACINA_EVENTO FOREIGN KEY (ID_EVENTO) REFERENCES EVENTO_CLINICO(ID_EVENTO) ON DELETE CASCADE,
    CONSTRAINT UK_VACINA_EVENTO UNIQUE (ID_EVENTO),
    CONSTRAINT CK_VACINA_PROX   CHECK (DT_PROXIMA_DOSE IS NULL OR DT_PROXIMA_DOSE > DT_APLICACAO)
);

CREATE INDEX IDX_VACINA_PROX ON VACINA(DT_PROXIMA_DOSE);

COMMENT ON COLUMN VACINA.DT_PROXIMA_DOSE IS 'Calculado pelo backend, alimenta lembretes da Luna';

-- ----------------------------------------------------------------------------
-- PRESCRICAO + PRESCRICAO_MEDICAMENTO
-- Domínio: .NET | FKs EVENTO_CLINICO, MEDICAMENTO
-- Razão: prescrição é cabeçalho. Itens da receita ficam em PRESCRICAO_MEDICAMENTO.
-- ----------------------------------------------------------------------------
CREATE TABLE PRESCRICAO (
    ID_PRESCRICAO      NUMBER(10)    DEFAULT SEQ_PRESCRICAO.NEXTVAL NOT NULL,
    ID_EVENTO          NUMBER(10)    NOT NULL,
    DT_EMISSAO         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    DT_VALIDADE        DATE,
    DS_OBSERVACOES     VARCHAR2(1000),
    ST_ASSINADA        CHAR(1)       DEFAULT 'N' NOT NULL,
    DS_HASH_ASSINATURA VARCHAR2(256),
    CONSTRAINT PK_PRESCRICAO   PRIMARY KEY (ID_PRESCRICAO),
    CONSTRAINT FK_PRESC_EVENTO FOREIGN KEY (ID_EVENTO) REFERENCES EVENTO_CLINICO(ID_EVENTO) ON DELETE CASCADE,
    CONSTRAINT UK_PRESC_EVENTO UNIQUE (ID_EVENTO),
    CONSTRAINT CK_PRESC_ASSIN  CHECK (ST_ASSINADA IN ('S','N'))
);

COMMENT ON COLUMN PRESCRICAO.DS_HASH_ASSINATURA IS 'Hash da assinatura digital (Lei 14.063/2020) — preenchido em fase 2';

CREATE TABLE PRESCRICAO_MEDICAMENTO (
    ID_PRESCRICAO  NUMBER(10)    NOT NULL,
    ID_MEDICAMENTO NUMBER(10)    NOT NULL,
    DS_DOSAGEM     VARCHAR2(100) NOT NULL,
    DS_FREQUENCIA  VARCHAR2(100) NOT NULL,
    NR_DURACAO_DIAS NUMBER(4),
    DS_INSTRUCOES  VARCHAR2(500),
    CONSTRAINT PK_PRESC_MED PRIMARY KEY (ID_PRESCRICAO, ID_MEDICAMENTO),
    CONSTRAINT FK_PM_PRESC  FOREIGN KEY (ID_PRESCRICAO)  REFERENCES PRESCRICAO(ID_PRESCRICAO) ON DELETE CASCADE,
    CONSTRAINT FK_PM_MED    FOREIGN KEY (ID_MEDICAMENTO) REFERENCES MEDICAMENTO(ID_MEDICAMENTO),
    CONSTRAINT CK_PM_DURACAO CHECK (NR_DURACAO_DIAS IS NULL OR NR_DURACAO_DIAS > 0)
);

CREATE INDEX IDX_PM_MED ON PRESCRICAO_MEDICAMENTO(ID_MEDICAMENTO);

COMMENT ON TABLE PRESCRICAO_MEDICAMENTO IS 'Itens da receita. Uma prescrição pode ter N medicamentos.';

-- ----------------------------------------------------------------------------
-- EXAME
-- Domínio: .NET | FK EVENTO_CLINICO
-- ----------------------------------------------------------------------------
CREATE TABLE EXAME (
    ID_EXAME        NUMBER(10)    DEFAULT SEQ_EXAME.NEXTVAL NOT NULL,
    ID_EVENTO       NUMBER(10)    NOT NULL,
    NM_EXAME        VARCHAR2(120) NOT NULL,
    DS_TIPO         VARCHAR2(60),
    DT_SOLICITACAO  DATE          DEFAULT SYSDATE NOT NULL,
    DT_REALIZACAO   DATE,
    DS_RESULTADO    CLOB,
    NM_LABORATORIO  VARCHAR2(120),
    ST_STATUS       VARCHAR2(20)  DEFAULT 'SOLICITADO' NOT NULL,
    CONSTRAINT PK_EXAME        PRIMARY KEY (ID_EXAME),
    CONSTRAINT FK_EXAME_EVENTO FOREIGN KEY (ID_EVENTO) REFERENCES EVENTO_CLINICO(ID_EVENTO) ON DELETE CASCADE,
    CONSTRAINT CK_EXAME_STATUS CHECK (ST_STATUS IN ('SOLICITADO','REALIZADO','CANCELADO','ENTREGUE'))
);

CREATE INDEX IDX_EXAME_STATUS ON EXAME(ST_STATUS);

COMMENT ON COLUMN EXAME.DS_TIPO IS 'Hemograma, ultrassom, raio-x, urina etc.';

-- ----------------------------------------------------------------------------
-- DOCUMENTO
-- Domínio: .NET | FK EVENTO_CLINICO (opcional)
-- Razão: anexos clínicos (PDFs, imagens) vinculados a um evento ou ao pet.
-- ----------------------------------------------------------------------------
CREATE TABLE DOCUMENTO (
    ID_DOCUMENTO     NUMBER(10)    DEFAULT SEQ_DOCUMENTO.NEXTVAL NOT NULL,
    ID_EVENTO        NUMBER(10),
    ID_PET           NUMBER(10)    NOT NULL,
    NM_DOCUMENTO     VARCHAR2(150) NOT NULL,
    DS_TIPO          VARCHAR2(40)  NOT NULL,
    DS_URL_STORAGE   VARCHAR2(500) NOT NULL,
    NR_TAMANHO_BYTES NUMBER(15),
    DS_MIME_TYPE     VARCHAR2(80),
    DT_UPLOAD        TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    NM_UPLOAD_POR    VARCHAR2(120),
    CONSTRAINT PK_DOCUMENTO   PRIMARY KEY (ID_DOCUMENTO),
    CONSTRAINT FK_DOC_EVENTO  FOREIGN KEY (ID_EVENTO) REFERENCES EVENTO_CLINICO(ID_EVENTO),
    CONSTRAINT FK_DOC_PET     FOREIGN KEY (ID_PET)    REFERENCES PET(ID_PET),
    CONSTRAINT CK_DOC_TIPO    CHECK (DS_TIPO IN ('LAUDO','RECEITA','ATESTADO','EXAME_PDF','IMAGEM','OUTRO'))
);

CREATE INDEX IDX_DOC_PET    ON DOCUMENTO(ID_PET);
CREATE INDEX IDX_DOC_EVENTO ON DOCUMENTO(ID_EVENTO);

COMMENT ON COLUMN DOCUMENTO.DS_URL_STORAGE IS 'URL no blob storage (Azure Blob, S3 etc) — não armazena binário no banco';

-- ============================================================================
-- 6. NOTIFICAÇÕES (canal Luna / WhatsApp)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- NOTIFICACAO
-- Domínio: .NET (gera) + Java (consome) | FKs TUTOR, PET (opcional), EVENTO (opcional)
-- Razão: registra todas as notificações enviadas ao tutor. Permite auditoria
--        e evita reenvio duplicado.
-- ----------------------------------------------------------------------------
CREATE TABLE NOTIFICACAO (
    ID_NOTIFICACAO NUMBER(10)     DEFAULT SEQ_NOTIFICACAO.NEXTVAL NOT NULL,
    ID_TUTOR       NUMBER(10)     NOT NULL,
    ID_PET         NUMBER(10),
    ID_EVENTO      NUMBER(10),
    DS_CANAL       VARCHAR2(20)   NOT NULL,
    DS_TIPO        VARCHAR2(40)   NOT NULL,
    DS_TITULO      VARCHAR2(200)  NOT NULL,
    DS_MENSAGEM    VARCHAR2(2000) NOT NULL,
    DT_AGENDADA    TIMESTAMP      NOT NULL,
    DT_ENVIADA     TIMESTAMP,
    DT_LIDA        TIMESTAMP,
    ST_STATUS      VARCHAR2(20)   DEFAULT 'PENDENTE' NOT NULL,
    DS_ERRO_ENVIO  VARCHAR2(500),
    CONSTRAINT PK_NOTIFICACAO   PRIMARY KEY (ID_NOTIFICACAO),
    CONSTRAINT FK_NOTIF_TUTOR   FOREIGN KEY (ID_TUTOR)  REFERENCES TUTOR(ID_TUTOR),
    CONSTRAINT FK_NOTIF_PET     FOREIGN KEY (ID_PET)    REFERENCES PET(ID_PET),
    CONSTRAINT FK_NOTIF_EVENTO  FOREIGN KEY (ID_EVENTO) REFERENCES EVENTO_CLINICO(ID_EVENTO),
    CONSTRAINT CK_NOTIF_CANAL   CHECK (DS_CANAL  IN ('WHATSAPP','EMAIL','PUSH','SMS')),
    CONSTRAINT CK_NOTIF_TIPO    CHECK (DS_TIPO   IN ('LEMBRETE_VACINA','RETORNO','PRESCRICAO_NOVA','RED_FLAG','BOAS_VINDAS','PESQUISA','OUTRO')),
    CONSTRAINT CK_NOTIF_STATUS  CHECK (ST_STATUS IN ('PENDENTE','ENVIADA','ENTREGUE','LIDA','FALHA','CANCELADA'))
);

CREATE INDEX IDX_NOTIF_TUTOR    ON NOTIFICACAO(ID_TUTOR);
CREATE INDEX IDX_NOTIF_STATUS   ON NOTIFICACAO(ST_STATUS);
CREATE INDEX IDX_NOTIF_AGENDADA ON NOTIFICACAO(DT_AGENDADA);

COMMENT ON TABLE NOTIFICACAO IS 'Fila de notificações. Job da Luna lê PENDENTE com DT_AGENDADA <= now() e dispara.';

-- ============================================================================
-- 7. DOMÍNIO JAVA — IDENTIDADE E AGENDAMENTO
-- ============================================================================
-- ORDEM DE DECLARAÇÃO (resolve dependências de FK sem ALTER TABLE):
--   INVITE_TUTOR → CONTA_TUTOR → CONSENTIMENTO → AGENDAMENTO
-- ============================================================================

-- ----------------------------------------------------------------------------
-- INVITE_TUTOR  [v3 — novo]
-- Domínio: .NET (gera o convite) | Java (apenas consulta para validar onboarding)
-- Razão: o cadastro de tutores no portal é invite-based. A clínica (.NET) gera
--        um token seguro e o envia ao tutor via WhatsApp/e-mail. O Java valida
--        o token durante a criação da CONTA_TUTOR.
-- ANTI-REUSO: CONTA_TUTOR.ID_INVITE_USADO tem UK — 1 invite gera exatamente 1 conta.
-- ----------------------------------------------------------------------------
CREATE TABLE INVITE_TUTOR (
    ID_INVITE       NUMBER(10)   DEFAULT SEQ_INVITE_TUTOR.NEXTVAL NOT NULL,
    ID_TUTOR        NUMBER(10)   NOT NULL,
    DS_TOKEN        VARCHAR2(64) NOT NULL,
    DT_GERACAO      TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL,
    DT_EXPIRACAO    TIMESTAMP    NOT NULL,
    DS_CANAL_ENVIO  VARCHAR2(20) DEFAULT 'WHATSAPP' NOT NULL,
    ST_ATIVO        CHAR(1)      DEFAULT 'S' NOT NULL,
    CONSTRAINT PK_INVITE_TUTOR      PRIMARY KEY (ID_INVITE),
    CONSTRAINT FK_INVITE_TUTOR      FOREIGN KEY (ID_TUTOR) REFERENCES TUTOR(ID_TUTOR),
    CONSTRAINT UK_INVITE_TOKEN      UNIQUE (DS_TOKEN),
    CONSTRAINT CK_INVITE_CANAL      CHECK (DS_CANAL_ENVIO IN ('WHATSAPP','EMAIL','SMS')),
    CONSTRAINT CK_INVITE_ATIVO      CHECK (ST_ATIVO IN ('S','N')),
    CONSTRAINT CK_INVITE_EXPIRACAO  CHECK (DT_EXPIRACAO > DT_GERACAO)
);

CREATE INDEX IDX_INVITE_TOKEN ON INVITE_TUTOR(DS_TOKEN);
CREATE INDEX IDX_INVITE_TUTOR ON INVITE_TUTOR(ID_TUTOR);

COMMENT ON TABLE  INVITE_TUTOR             IS 'Convite de onboarding gerado pela clínica (.NET). Java apenas consulta.';
COMMENT ON COLUMN INVITE_TUTOR.DS_TOKEN    IS 'Token opaco gerado com SecureRandom — UNIQUE. Enviado ao tutor via canal escolhido.';
COMMENT ON COLUMN INVITE_TUTOR.ST_ATIVO    IS 'S=válido para uso. N=expirado ou já utilizado (invalidado após criação da conta).';

-- ----------------------------------------------------------------------------
-- CONTA_TUTOR  [v3 — modificado]
-- Domínio: Java (Nikolas) | FK TUTOR, FK INVITE_TUTOR
-- Razão: separa credenciais de acesso (login/senha/token) dos dados pessoais.
--        Tutor existe sem conta. Conta só existe quando tutor usa o convite.
-- DECISÃO: 1:1 com TUTOR (UK em ID_TUTOR) e 1:1 com INVITE_TUTOR (UK em ID_INVITE_USADO).
-- ALTERAÇÕES v3:
--   + DS_REFRESH_TOKEN_HASH  — hash SHA-256 do refresh token JWT
--   + DT_REFRESH_EXPIRA      — expiração do refresh token
--   + ID_INVITE_USADO        — FK + UK para INVITE_TUTOR (anti-reuso de invite)
-- ----------------------------------------------------------------------------
CREATE TABLE CONTA_TUTOR (
    ID_CONTA              NUMBER(10)    DEFAULT SEQ_CONTA_TUTOR.NEXTVAL NOT NULL,
    ID_TUTOR              NUMBER(10)    NOT NULL,
    DS_EMAIL_LOGIN        VARCHAR2(120) NOT NULL,
    DS_SENHA_HASH         VARCHAR2(256) NOT NULL,
    DS_SALT               VARCHAR2(64),
    -- [v3] Refresh token — armazenado apenas como hash SHA-256
    DS_REFRESH_TOKEN_HASH VARCHAR2(256),
    DT_REFRESH_EXPIRA     TIMESTAMP,
    DT_CRIACAO            TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    DT_ULTIMO_LOGIN       TIMESTAMP,
    NR_TENTATIVAS_LOGIN   NUMBER(2)     DEFAULT 0 NOT NULL,
    DT_BLOQUEIO           TIMESTAMP,
    ST_ATIVA              CHAR(1)       DEFAULT 'S' NOT NULL,
    ST_EMAIL_VERIFICADO   CHAR(1)       DEFAULT 'N' NOT NULL,
    DS_TOKEN_RESET        VARCHAR2(256),
    DT_TOKEN_EXPIRA       TIMESTAMP,
    -- [v3] Vínculo com o invite que originou esta conta
    ID_INVITE_USADO       NUMBER(10),
    CONSTRAINT PK_CONTA_TUTOR       PRIMARY KEY (ID_CONTA),
    CONSTRAINT FK_CONTA_TUTOR       FOREIGN KEY (ID_TUTOR)        REFERENCES TUTOR(ID_TUTOR),
    CONSTRAINT FK_CONTA_INVITE      FOREIGN KEY (ID_INVITE_USADO) REFERENCES INVITE_TUTOR(ID_INVITE),
    CONSTRAINT UK_CONTA_TUTOR       UNIQUE (ID_TUTOR),
    CONSTRAINT UK_CONTA_EMAIL       UNIQUE (DS_EMAIL_LOGIN),
    CONSTRAINT UK_CONTA_INVITE_USED UNIQUE (ID_INVITE_USADO),
    CONSTRAINT CK_CONTA_ATIVA       CHECK (ST_ATIVA IN ('S','N')),
    CONSTRAINT CK_CONTA_EMAIL_VERIF CHECK (ST_EMAIL_VERIFICADO IN ('S','N')),
    CONSTRAINT CK_CONTA_TENTATIVAS  CHECK (NR_TENTATIVAS_LOGIN BETWEEN 0 AND 99)
);

COMMENT ON TABLE  CONTA_TUTOR                    IS 'Credenciais de acesso ao portal. Gerenciada exclusivamente pelo backend Java.';
COMMENT ON COLUMN CONTA_TUTOR.DS_SENHA_HASH      IS 'BCrypt ou Argon2 — NUNCA texto plano';
COMMENT ON COLUMN CONTA_TUTOR.DT_BLOQUEIO        IS 'Preenchido quando tentativas excedem limite — desbloqueio manual ou por tempo';
COMMENT ON COLUMN CONTA_TUTOR.DS_REFRESH_TOKEN_HASH IS 'SHA-256 do refresh token. Texto plano NUNCA é persistido.';
COMMENT ON COLUMN CONTA_TUTOR.DT_REFRESH_EXPIRA  IS 'Timestamp de expiração do refresh token. NULL = nenhum token ativo.';
COMMENT ON COLUMN CONTA_TUTOR.ID_INVITE_USADO    IS 'Invite que originou esta conta. UK garante que um invite gera exatamente 1 conta (anti-reuso).';

-- ----------------------------------------------------------------------------
-- CONSENTIMENTO
-- Domínio: Java | FK TUTOR
-- Razão: LGPD — registra cada consentimento dado pelo tutor com versão do termo,
--        data, IP e status. Histórico imutável (nunca UPDATE — sempre INSERT).
-- ----------------------------------------------------------------------------
CREATE TABLE CONSENTIMENTO (
    ID_CONSENTIMENTO NUMBER(10)    DEFAULT SEQ_CONSENTIMENTO.NEXTVAL NOT NULL,
    ID_TUTOR         NUMBER(10)    NOT NULL,
    DS_TIPO          VARCHAR2(40)  NOT NULL,
    DS_VERSAO_TERMO  VARCHAR2(20)  NOT NULL,
    DS_TEXTO_TERMO   CLOB,
    ST_ACEITO        CHAR(1)       NOT NULL,
    DT_ACEITE        TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    DS_IP_ACEITE     VARCHAR2(45),
    DT_REVOGACAO     TIMESTAMP,
    DS_IP_REVOGACAO  VARCHAR2(45),
    CONSTRAINT PK_CONSENTIMENTO PRIMARY KEY (ID_CONSENTIMENTO),
    CONSTRAINT FK_CONS_TUTOR    FOREIGN KEY (ID_TUTOR) REFERENCES TUTOR(ID_TUTOR),
    CONSTRAINT CK_CONS_TIPO     CHECK (DS_TIPO IN ('TELEORIENTACAO','LEMBRETES','DADOS_ANONIMOS','COMPARTILHAR_SEGURADORA','MARKETING')),
    CONSTRAINT CK_CONS_ACEITO   CHECK (ST_ACEITO IN ('S','N'))
);

CREATE INDEX IDX_CONS_TUTOR ON CONSENTIMENTO(ID_TUTOR);
CREATE INDEX IDX_CONS_TIPO  ON CONSENTIMENTO(DS_TIPO);

COMMENT ON TABLE CONSENTIMENTO IS 'Registro LGPD. Cada novo aceite/revogação = nova linha (histórico imutável).';

-- ----------------------------------------------------------------------------
-- AGENDAMENTO  [v3 — modificado]
-- Domínio: Java (Nikolas) | FKs TUTOR, PET, VETERINARIO, CLINICA
-- Razão: futuro/intenção. Diferente de EVENTO_CLINICO que é passado/realizado.
--        Quando agendamento é cumprido, pode gerar um EVENTO_CLINICO.
-- ALTERAÇÃO v3:
--   + NR_VERSION — optimistic locking via JPA @Version. Evita race condition
--                  quando dois usuários confirmam/cancelam o mesmo agendamento
--                  simultaneamente (ex: recepcionista + tutor no portal).
-- ----------------------------------------------------------------------------
CREATE TABLE AGENDAMENTO (
    ID_AGENDAMENTO     NUMBER(10)    DEFAULT SEQ_AGENDAMENTO.NEXTVAL NOT NULL,
    ID_TUTOR           NUMBER(10)    NOT NULL,
    ID_PET             NUMBER(10)    NOT NULL,
    ID_CLINICA         NUMBER(10)    NOT NULL,
    ID_VETERINARIO     NUMBER(10),
    DT_AGENDAMENTO     TIMESTAMP     NOT NULL,
    NR_DURACAO_MINUTOS NUMBER(4)     DEFAULT 30 NOT NULL,
    DS_TIPO            VARCHAR2(30)  NOT NULL,
    DS_OBSERVACOES     VARCHAR2(1000),
    ST_STATUS          VARCHAR2(20)  DEFAULT 'AGENDADO' NOT NULL,
    DS_ORIGEM          VARCHAR2(20)  DEFAULT 'PORTAL' NOT NULL,
    DT_CRIACAO         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    DT_CONFIRMACAO     TIMESTAMP,
    DT_CANCELAMENTO    TIMESTAMP,
    DS_MOTIVO_CANCEL   VARCHAR2(500),
    ID_EVENTO_GERADO   NUMBER(10),
    -- [v3] Optimistic locking
    NR_VERSION         NUMBER(10)    DEFAULT 0 NOT NULL,
    CONSTRAINT PK_AGENDAMENTO       PRIMARY KEY (ID_AGENDAMENTO),
    CONSTRAINT FK_AGEND_TUTOR       FOREIGN KEY (ID_TUTOR)          REFERENCES TUTOR(ID_TUTOR),
    CONSTRAINT FK_AGEND_PET         FOREIGN KEY (ID_PET)            REFERENCES PET(ID_PET),
    CONSTRAINT FK_AGEND_CLINICA     FOREIGN KEY (ID_CLINICA)        REFERENCES CLINICA(ID_CLINICA),
    CONSTRAINT FK_AGEND_VETERINARIO FOREIGN KEY (ID_VETERINARIO)    REFERENCES VETERINARIO(ID_VETERINARIO),
    CONSTRAINT FK_AGEND_EVENTO      FOREIGN KEY (ID_EVENTO_GERADO)  REFERENCES EVENTO_CLINICO(ID_EVENTO),
    CONSTRAINT CK_AGEND_TIPO        CHECK (DS_TIPO    IN ('CONSULTA','RETORNO','VACINA','EXAME','PROCEDIMENTO','TELEORIENTACAO')),
    CONSTRAINT CK_AGEND_STATUS      CHECK (ST_STATUS  IN ('INTENCAO','AGENDADO','CONFIRMADO','REALIZADO','CANCELADO','NAO_COMPARECEU')),
    CONSTRAINT CK_AGEND_ORIGEM      CHECK (DS_ORIGEM  IN ('PORTAL','WHATSAPP_LUNA','TELEFONE','BALCAO')),
    CONSTRAINT CK_AGEND_DURACAO     CHECK (NR_DURACAO_MINUTOS BETWEEN 5 AND 480),
    CONSTRAINT CK_AGEND_VERSION     CHECK (NR_VERSION >= 0)
);

CREATE INDEX IDX_AGEND_TUTOR  ON AGENDAMENTO(ID_TUTOR);
CREATE INDEX IDX_AGEND_PET    ON AGENDAMENTO(ID_PET);
CREATE INDEX IDX_AGEND_CLINICA ON AGENDAMENTO(ID_CLINICA);
CREATE INDEX IDX_AGEND_DATA   ON AGENDAMENTO(DT_AGENDAMENTO);
CREATE INDEX IDX_AGEND_STATUS ON AGENDAMENTO(ST_STATUS);

COMMENT ON TABLE  AGENDAMENTO                IS 'Agendamentos futuros/intenções. Quando realizado, ID_EVENTO_GERADO aponta para o EVENTO_CLINICO criado.';
COMMENT ON COLUMN AGENDAMENTO.DS_ORIGEM      IS 'Origem do agendamento (canal). WHATSAPP_LUNA = veio do bot.';
COMMENT ON COLUMN AGENDAMENTO.ID_EVENTO_GERADO IS 'Quando agendamento vira realidade, gera evento clínico — vínculo aqui';
COMMENT ON COLUMN AGENDAMENTO.NR_VERSION     IS 'Optimistic locking via JPA @Version. Incrementado em cada UPDATE.';

-- ============================================================================
-- 8. AUDITORIA E IDEMPOTÊNCIA
-- ============================================================================

-- ----------------------------------------------------------------------------
-- LOG_ERRO
-- Domínio: ambos (.NET e Java escrevem aqui)
-- Razão: requisito explícito da disciplina de Banco — toda procedure deve
--        gravar erro aqui no EXCEPTION WHEN OTHERS.
-- DECISÃO: sem FKs propositalmente — log não pode falhar por violação de
--          integridade referencial. Registro de erro deve sempre persistir.
-- ----------------------------------------------------------------------------
CREATE TABLE LOG_ERRO (
    ID_LOG           NUMBER(15)    DEFAULT SEQ_LOG_ERRO.NEXTVAL NOT NULL,
    NM_PROCEDURE     VARCHAR2(120) NOT NULL,
    NM_USUARIO       VARCHAR2(60)  NOT NULL,
    DT_ERRO          TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    NR_CODIGO_ERRO   NUMBER(10)    NOT NULL,
    DS_MENSAGEM_ERRO VARCHAR2(2000) NOT NULL,
    DS_PARAMETROS    VARCHAR2(2000),
    DS_STACK_TRACE   CLOB,
    CONSTRAINT PK_LOG_ERRO PRIMARY KEY (ID_LOG)
);

CREATE INDEX IDX_LOG_DATA      ON LOG_ERRO(DT_ERRO DESC);
CREATE INDEX IDX_LOG_PROCEDURE ON LOG_ERRO(NM_PROCEDURE);

COMMENT ON TABLE LOG_ERRO IS 'Registro centralizado de erros das procedures (requisito FIAP — disciplina Banco)';

-- ----------------------------------------------------------------------------
-- IDEMPOTENCY_KEY  [v3 — novo]
-- Domínio: Java (Nikolas) — escrita e leitura
-- Razão: garante que POSTs sensíveis (ex: aceite de consentimento LGPD,
--        criação de agendamento via Luna) sejam processados exatamente 1 vez.
--        Padrão: cliente gera UUID como Idempotency-Key no header HTTP.
--        Java persiste aqui antes de processar; se chave já existir, retorna
--        o resultado anterior sem reprocessar.
-- NOTA: ID_RESOURCE_CRIADO é polimórfico (armazena PK de qualquer recurso
--       criado) — sem FK por design, pois a tabela alvo varia por NM_RESOURCE.
-- ----------------------------------------------------------------------------
CREATE TABLE IDEMPOTENCY_KEY (
    ID_IDEMPOTENCY   NUMBER(10)    DEFAULT SEQ_IDEMPOTENCY_KEY.NEXTVAL NOT NULL,
    DS_KEY           VARCHAR2(64)  NOT NULL,
    NM_RESOURCE      VARCHAR2(60)  NOT NULL,
    ID_RESOURCE_CRIADO NUMBER(10)  NOT NULL,
    DT_CRIACAO       TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    DT_EXPIRACAO     TIMESTAMP     NOT NULL,
    CONSTRAINT PK_IDEMPOTENCY_KEY    PRIMARY KEY (ID_IDEMPOTENCY),
    CONSTRAINT UK_IDEMPOTENCY_CHAVE  UNIQUE (DS_KEY, NM_RESOURCE),
    CONSTRAINT CK_IDEMPOTENCY_EXPIRA CHECK (DT_EXPIRACAO > DT_CRIACAO)
);

CREATE INDEX IDX_IDEMPOT_EXPIRA ON IDEMPOTENCY_KEY(DT_EXPIRACAO);

COMMENT ON TABLE  IDEMPOTENCY_KEY                IS 'Garante idempotência de POSTs sensíveis (ex: aceite de consentimento LGPD).';
COMMENT ON COLUMN IDEMPOTENCY_KEY.DS_KEY         IS 'UUID gerado pelo cliente (header Idempotency-Key). Parte da chave única composta com NM_RESOURCE.';
COMMENT ON COLUMN IDEMPOTENCY_KEY.NM_RESOURCE    IS 'Nome do recurso alvo (ex: CONSENTIMENTO, AGENDAMENTO). Discrimina o contexto da chave.';
COMMENT ON COLUMN IDEMPOTENCY_KEY.ID_RESOURCE_CRIADO IS 'PK do registro criado na operação original. Retornado em chamadas duplicadas sem reprocessar.';
COMMENT ON COLUMN IDEMPOTENCY_KEY.DT_EXPIRACAO   IS 'TTL da chave. Job de limpeza pode deletar linhas expiradas sem impacto funcional.';

-- ============================================================================
-- 9. IoT — MONITORAMENTO DE TEMPERATURA DE VACINAS (Disruptive IoT/IA)
-- ============================================================================
-- Contexto: sensor físico/simulado (ESP32 + DHT11/DS18B20) monitora
-- temperatura da geladeira de armazenamento de vacinas. Vacinas perdem
-- eficácia fora da faixa 2-8°C (Anvisa RDC 197/2017). Alerta a clínica
-- antes da perda do lote.
-- Domínio: .NET (Felipe escreve via endpoint de ingestão); front clínica consome.

-- ----------------------------------------------------------------------------
-- DISPOSITIVO_IOT
-- Catálogo de sensores físicos. Cada geladeira da clínica = 1 dispositivo.
-- ----------------------------------------------------------------------------
CREATE TABLE DISPOSITIVO_IOT (
    ID_DISPOSITIVO       NUMBER(10)    DEFAULT SEQ_DISPOSITIVO_IOT.NEXTVAL NOT NULL,
    ID_CLINICA           NUMBER(10)    NOT NULL,
    DS_IDENTIFICADOR     VARCHAR2(60)  NOT NULL,
    NM_DISPOSITIVO       VARCHAR2(120) NOT NULL,
    DS_TIPO              VARCHAR2(40)  DEFAULT 'TERMOMETRO_VACINA' NOT NULL,
    DS_LOCALIZACAO       VARCHAR2(120),
    NR_TEMP_MINIMA       NUMBER(4,2)   DEFAULT 2.0  NOT NULL,
    NR_TEMP_MAXIMA       NUMBER(4,2)   DEFAULT 8.0  NOT NULL,
    NR_INTERVALO_LEITURA NUMBER(4)     DEFAULT 60   NOT NULL,
    DT_INSTALACAO        DATE          DEFAULT SYSDATE NOT NULL,
    DT_ULTIMA_LEITURA    TIMESTAMP,
    ST_STATUS            VARCHAR2(20)  DEFAULT 'ATIVO' NOT NULL,
    DS_FIRMWARE          VARCHAR2(40),
    CONSTRAINT PK_DISPOSITIVO_IOT   PRIMARY KEY (ID_DISPOSITIVO),
    CONSTRAINT FK_IOT_CLINICA       FOREIGN KEY (ID_CLINICA) REFERENCES CLINICA(ID_CLINICA),
    CONSTRAINT UK_IOT_IDENTIFICADOR UNIQUE (DS_IDENTIFICADOR),
    CONSTRAINT CK_IOT_TIPO          CHECK (DS_TIPO     IN ('TERMOMETRO_VACINA','UMIDADE','PRESENCA','OUTRO')),
    CONSTRAINT CK_IOT_STATUS        CHECK (ST_STATUS   IN ('ATIVO','INATIVO','MANUTENCAO','OFFLINE')),
    CONSTRAINT CK_IOT_TEMP_FAIXA    CHECK (NR_TEMP_MAXIMA > NR_TEMP_MINIMA),
    CONSTRAINT CK_IOT_INTERVALO     CHECK (NR_INTERVALO_LEITURA BETWEEN 10 AND 3600)
);

CREATE INDEX IDX_IOT_CLINICA ON DISPOSITIVO_IOT(ID_CLINICA);
CREATE INDEX IDX_IOT_STATUS  ON DISPOSITIVO_IOT(ST_STATUS);

COMMENT ON TABLE  DISPOSITIVO_IOT                      IS 'Sensores IoT instalados nas clínicas (geladeira de vacinas, etc)';
COMMENT ON COLUMN DISPOSITIVO_IOT.DS_IDENTIFICADOR     IS 'MAC address ou ID único do hardware (ESP32) — usado pelo dispositivo para autenticar';
COMMENT ON COLUMN DISPOSITIVO_IOT.NR_TEMP_MINIMA       IS 'Temp mínima aceitável em °C — Anvisa RDC 197/2017 = 2.0';
COMMENT ON COLUMN DISPOSITIVO_IOT.NR_TEMP_MAXIMA       IS 'Temp máxima aceitável em °C — Anvisa RDC 197/2017 = 8.0';
COMMENT ON COLUMN DISPOSITIVO_IOT.NR_INTERVALO_LEITURA IS 'Intervalo de leitura em segundos (default 60s = 1 leitura/min)';
COMMENT ON COLUMN DISPOSITIVO_IOT.DT_ULTIMA_LEITURA    IS 'Atualizado a cada leitura — usado para detectar dispositivo offline';

-- ----------------------------------------------------------------------------
-- LEITURA_TEMPERATURA
-- Time-series de leituras. Front clínica consome via endpoint /dispositivos/{id}/leituras
-- ATENÇÃO: tabela cresce rápido. ~1.440 leituras/dia/dispositivo (1/min).
-- Recomendação produção: particionar por mês ou archive após 90 dias.
-- ----------------------------------------------------------------------------
CREATE TABLE LEITURA_TEMPERATURA (
    ID_LEITURA       NUMBER(15)    DEFAULT SEQ_LEITURA_TEMP.NEXTVAL NOT NULL,
    ID_DISPOSITIVO   NUMBER(10)    NOT NULL,
    NR_TEMPERATURA   NUMBER(5,2)   NOT NULL,
    NR_UMIDADE       NUMBER(5,2),
    DT_LEITURA       TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    ST_DENTRO_FAIXA  CHAR(1)       NOT NULL,
    DS_OBSERVACAO    VARCHAR2(200),
    CONSTRAINT PK_LEITURA_TEMP       PRIMARY KEY (ID_LEITURA),
    CONSTRAINT FK_LEITURA_DISP       FOREIGN KEY (ID_DISPOSITIVO) REFERENCES DISPOSITIVO_IOT(ID_DISPOSITIVO),
    CONSTRAINT CK_LEITURA_FAIXA      CHECK (ST_DENTRO_FAIXA IN ('S','N')),
    CONSTRAINT CK_LEITURA_TEMP_RANGE CHECK (NR_TEMPERATURA BETWEEN -40 AND 80)
);

CREATE INDEX IDX_LEITURA_DISP_DATA ON LEITURA_TEMPERATURA(ID_DISPOSITIVO, DT_LEITURA DESC);
CREATE INDEX IDX_LEITURA_FORA      ON LEITURA_TEMPERATURA(ST_DENTRO_FAIXA, DT_LEITURA DESC);

COMMENT ON TABLE  LEITURA_TEMPERATURA                IS 'Time-series de leituras dos sensores. Cresce ~1.440 linhas/dia/dispositivo.';
COMMENT ON COLUMN LEITURA_TEMPERATURA.ST_DENTRO_FAIXA IS 'Calculado pelo backend ao receber leitura: S se entre min e max do dispositivo';
COMMENT ON COLUMN LEITURA_TEMPERATURA.NR_UMIDADE      IS 'Umidade % — opcional, alguns sensores DHT11/DHT22 fornecem';

-- ----------------------------------------------------------------------------
-- ALERTA_TEMPERATURA
-- Quando temperatura sai da faixa, dispara alerta. Front clínica consome
-- alertas ativos para exibir no dashboard. Alerta = problema agregado,
-- não 1 alerta por leitura (evita poluição visual).
-- ----------------------------------------------------------------------------
CREATE TABLE ALERTA_TEMPERATURA (
    ID_ALERTA          NUMBER(10)    DEFAULT SEQ_ALERTA_TEMP.NEXTVAL NOT NULL,
    ID_DISPOSITIVO     NUMBER(10)    NOT NULL,
    DS_TIPO_ALERTA     VARCHAR2(30)  NOT NULL,
    DS_SEVERIDADE      VARCHAR2(20)  NOT NULL,
    NR_TEMP_REGISTRADA NUMBER(5,2),
    DT_INICIO          TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    DT_FIM             TIMESTAMP,
    NR_DURACAO_MINUTOS NUMBER(6),
    DS_MENSAGEM        VARCHAR2(500) NOT NULL,
    ST_RESOLVIDO       CHAR(1)       DEFAULT 'N' NOT NULL,
    NM_RESOLVIDO_POR   VARCHAR2(120),
    DT_RESOLUCAO       TIMESTAMP,
    DS_ACAO_TOMADA     VARCHAR2(500),
    CONSTRAINT PK_ALERTA_TEMP       PRIMARY KEY (ID_ALERTA),
    CONSTRAINT FK_ALERTA_DISP       FOREIGN KEY (ID_DISPOSITIVO) REFERENCES DISPOSITIVO_IOT(ID_DISPOSITIVO),
    CONSTRAINT CK_ALERTA_TIPO       CHECK (DS_TIPO_ALERTA IN ('TEMP_ALTA','TEMP_BAIXA','SENSOR_OFFLINE','VARIACAO_BRUSCA')),
    CONSTRAINT CK_ALERTA_SEVERIDADE CHECK (DS_SEVERIDADE  IN ('BAIXA','MEDIA','ALTA','CRITICA')),
    CONSTRAINT CK_ALERTA_RESOLVIDO  CHECK (ST_RESOLVIDO   IN ('S','N'))
);

CREATE INDEX IDX_ALERTA_DISP   ON ALERTA_TEMPERATURA(ID_DISPOSITIVO);
CREATE INDEX IDX_ALERTA_ATIVOS ON ALERTA_TEMPERATURA(ST_RESOLVIDO, DT_INICIO DESC);

COMMENT ON TABLE  ALERTA_TEMPERATURA              IS 'Alertas agregados de temperatura. 1 alerta por evento, não por leitura.';
COMMENT ON COLUMN ALERTA_TEMPERATURA.DS_SEVERIDADE IS 'BAIXA = 8-10°C ou 0-2°C | MEDIA = 10-12°C ou -2-0°C | ALTA = >12°C ou <-2°C | CRITICA = >20°C ou sensor offline >30min';
COMMENT ON COLUMN ALERTA_TEMPERATURA.DT_FIM        IS 'Preenchido quando temperatura volta à faixa. NULL = alerta ativo.';

-- ============================================================================
-- 10. VIEWS ÚTEIS (apoiam queries das disciplinas e da Luna)
-- ============================================================================

-- View: timeline completa do pet (usada pelo Backend Tutor e pela Luna)
CREATE OR REPLACE VIEW VW_TIMELINE_PET AS
SELECT
    p.ID_PET,
    p.NM_PET,
    e.ID_EVENTO,
    te.NM_TIPO_EVENTO,
    e.DT_EVENTO,
    v.NM_VETERINARIO,
    e.DS_DIAGNOSTICO,
    e.DS_MODALIDADE,
    e.DS_CID10_VET
FROM PET p
JOIN EVENTO_CLINICO e ON e.ID_PET          = p.ID_PET
JOIN VETERINARIO    v ON v.ID_VETERINARIO  = e.ID_VETERINARIO
JOIN TIPO_EVENTO   te ON te.ID_TIPO_EVENTO = e.ID_TIPO_EVENTO
WHERE p.ST_ATIVO = 'S';

-- View: vacinas vencendo nos próximos 30 dias (alimenta Luna)
CREATE OR REPLACE VIEW VW_VACINAS_VENCENDO AS
SELECT
    p.ID_PET,
    p.NM_PET,
    t.ID_TUTOR,
    t.NM_TUTOR,
    t.DS_WHATSAPP,
    v.NM_VACINA,
    v.DT_PROXIMA_DOSE,
    (v.DT_PROXIMA_DOSE - TRUNC(SYSDATE)) AS DIAS_RESTANTES,
    c.NM_CLINICA
FROM VACINA v
JOIN EVENTO_CLINICO e ON e.ID_EVENTO   = v.ID_EVENTO
JOIN PET            p ON p.ID_PET      = e.ID_PET
JOIN TUTOR_PET     tp ON tp.ID_PET     = p.ID_PET AND tp.ST_PRINCIPAL = 'S'
JOIN TUTOR          t ON t.ID_TUTOR    = tp.ID_TUTOR
JOIN CLINICA        c ON c.ID_CLINICA  = t.ID_CLINICA
WHERE v.DT_PROXIMA_DOSE BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 30
  AND p.ST_ATIVO = 'S';

-- PROCEDURES

-- ============================================================================
-- PROCEDURE AUXILIAR DE LOG
-- ============================================================================

CREATE OR REPLACE PROCEDURE PRC_LOG_ERRO (
    P_NM_PROCEDURE      IN VARCHAR2,
    P_NR_CODIGO_ERRO    IN NUMBER,
    P_DS_MENSAGEM_ERRO  IN VARCHAR2,
    P_DS_PARAMETROS     IN VARCHAR2
)
IS
BEGIN

    INSERT INTO LOG_ERRO (
        NM_PROCEDURE,
        NM_USUARIO,
        DT_ERRO,
        NR_CODIGO_ERRO,
        DS_MENSAGEM_ERRO,
        DS_PARAMETROS
    )
    VALUES (
        P_NM_PROCEDURE,
        USER,
        SYSTIMESTAMP,
        P_NR_CODIGO_ERRO,
        P_DS_MENSAGEM_ERRO,
        P_DS_PARAMETROS
    );

END;
/



-- ============================================================================
-- PROCEDURE CLINICA
-- ============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERIR_CLINICA (
    P_NM_CLINICA      IN VARCHAR2,
    P_NR_CNPJ         IN VARCHAR2,
    P_DS_ENDERECO     IN VARCHAR2,
    P_NM_CIDADE       IN VARCHAR2,
    P_SG_UF           IN CHAR,
    P_NR_CEP          IN VARCHAR2,
    P_DS_EMAIL        IN VARCHAR2
)
IS

    V_EXISTE NUMBER;

    EX_CNPJ_DUPLICADO EXCEPTION;
    EX_EMAIL_INVALIDO EXCEPTION;

BEGIN

    SELECT COUNT(*)
    INTO V_EXISTE
    FROM CLINICA
    WHERE NR_CNPJ = P_NR_CNPJ;

    IF V_EXISTE > 0 THEN
        RAISE EX_CNPJ_DUPLICADO;
    END IF;

    IF P_DS_EMAIL NOT LIKE '%@%' THEN
        RAISE EX_EMAIL_INVALIDO;
    END IF;

    INSERT INTO CLINICA (
        NM_CLINICA,
        NR_CNPJ,
        DS_ENDERECO,
        NM_CIDADE,
        SG_UF,
        NR_CEP,
        DS_EMAIL
    )
    VALUES (
        P_NM_CLINICA,
        P_NR_CNPJ,
        P_DS_ENDERECO,
        P_NM_CIDADE,
        P_SG_UF,
        P_NR_CEP,
        P_DS_EMAIL
    );

    COMMIT;

EXCEPTION

    WHEN EX_CNPJ_DUPLICADO THEN

        PRC_LOG_ERRO(
            'PRC_INSERIR_CLINICA',
            SQLCODE,
            'CNPJ DUPLICADO',
            'CNPJ=' || P_NR_CNPJ
        );

        DBMS_OUTPUT.PUT_LINE('CNPJ já cadastrado');

    WHEN EX_EMAIL_INVALIDO THEN

        PRC_LOG_ERRO(
            'PRC_INSERIR_CLINICA',
            SQLCODE,
            'EMAIL INVALIDO',
            'EMAIL=' || P_DS_EMAIL
        );

        DBMS_OUTPUT.PUT_LINE('Email inválido');

    WHEN OTHERS THEN

        PRC_LOG_ERRO(
            'PRC_INSERIR_CLINICA',
            SQLCODE,
            SQLERRM,
            'ERRO GERAL'
        );

        DBMS_OUTPUT.PUT_LINE('Erro inesperado');

END;
/



-- =============================================================================
-- ESPECIE
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERT_ESPECIE (
    P_NM_ESPECIE IN VARCHAR2
)
AS
    V_EXISTE NUMBER;

    EX_NOME_INVALIDO  EXCEPTION;
    EX_JA_CADASTRADA  EXCEPTION;

BEGIN

    IF P_NM_ESPECIE IS NULL OR LENGTH(TRIM(P_NM_ESPECIE)) = 0 THEN
        RAISE EX_NOME_INVALIDO;
    END IF;

    SELECT COUNT(*)
    INTO V_EXISTE
    FROM ESPECIE
    WHERE NM_ESPECIE = TRIM(P_NM_ESPECIE);

    IF V_EXISTE > 0 THEN
        RAISE EX_JA_CADASTRADA;
    END IF;

    INSERT INTO ESPECIE (
        ID_ESPECIE,
        NM_ESPECIE
    )
    VALUES (
        SEQ_ESPECIE.NEXTVAL,
        TRIM(P_NM_ESPECIE)
    );

EXCEPTION
    WHEN EX_NOME_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_ESPECIE', SQLCODE, 'NOME INVALIDO OU VAZIO', P_NM_ESPECIE);
        DBMS_OUTPUT.PUT_LINE('Nome da espécie inválido ou vazio');

    WHEN EX_JA_CADASTRADA THEN
        PRC_LOG_ERRO('PRC_INSERT_ESPECIE', SQLCODE, 'ESPECIE JA CADASTRADA', P_NM_ESPECIE);
        DBMS_OUTPUT.PUT_LINE('Espécie já cadastrada: ' || P_NM_ESPECIE);

    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_ESPECIE', SQLCODE, SQLERRM, P_NM_ESPECIE);
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/


-- =============================================================================
-- MEDICAMENTO
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERT_MEDICAMENTO (
    P_NM_MEDICAMENTO  IN VARCHAR2,
    P_NM_PRINCIPIO    IN VARCHAR2,
    P_DS_APRESENTACAO IN VARCHAR2
)
AS
    V_EXISTE NUMBER;

    EX_NOME_INVALIDO   EXCEPTION;
    EX_JA_CADASTRADO   EXCEPTION;

BEGIN

    IF P_NM_MEDICAMENTO IS NULL OR LENGTH(TRIM(P_NM_MEDICAMENTO)) = 0 THEN
        RAISE EX_NOME_INVALIDO;
    END IF;

    SELECT COUNT(*)
    INTO V_EXISTE
    FROM MEDICAMENTO
    WHERE NM_MEDICAMENTO = TRIM(P_NM_MEDICAMENTO);

    IF V_EXISTE > 0 THEN
        RAISE EX_JA_CADASTRADO;
    END IF;

    INSERT INTO MEDICAMENTO (
        ID_MEDICAMENTO,
        NM_MEDICAMENTO,
        NM_PRINCIPIO,
        DS_APRESENTACAO
    )
    VALUES (
        SEQ_MEDICAMENTO.NEXTVAL,
        TRIM(P_NM_MEDICAMENTO),
        P_NM_PRINCIPIO,
        P_DS_APRESENTACAO
    );

EXCEPTION
    WHEN EX_NOME_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_MEDICAMENTO', SQLCODE, 'NOME INVALIDO OU VAZIO', P_NM_MEDICAMENTO);
        DBMS_OUTPUT.PUT_LINE('Nome do medicamento inválido ou vazio');

    WHEN EX_JA_CADASTRADO THEN
        PRC_LOG_ERRO('PRC_INSERT_MEDICAMENTO', SQLCODE, 'MEDICAMENTO JA CADASTRADO', P_NM_MEDICAMENTO);
        DBMS_OUTPUT.PUT_LINE('Medicamento já cadastrado: ' || P_NM_MEDICAMENTO);

    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_MEDICAMENTO', SQLCODE, SQLERRM, P_NM_MEDICAMENTO);
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/


-- =============================================================================
-- TIPO_EVENTO
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERT_TIPO_EVENTO (
    P_NM_TIPO_EVENTO IN VARCHAR2,
    P_DS_TIPO_EVENTO IN VARCHAR2
)
AS
    V_EXISTE NUMBER;

    EX_NOME_INVALIDO  EXCEPTION;
    EX_JA_CADASTRADO  EXCEPTION;

BEGIN

    IF P_NM_TIPO_EVENTO IS NULL OR LENGTH(TRIM(P_NM_TIPO_EVENTO)) = 0 THEN
        RAISE EX_NOME_INVALIDO;
    END IF;

    SELECT COUNT(*)
    INTO V_EXISTE
    FROM TIPO_EVENTO
    WHERE NM_TIPO_EVENTO = TRIM(P_NM_TIPO_EVENTO);

    IF V_EXISTE > 0 THEN
        RAISE EX_JA_CADASTRADO;
    END IF;

    INSERT INTO TIPO_EVENTO (
        ID_TIPO_EVENTO,
        NM_TIPO_EVENTO,
        DS_TIPO_EVENTO
    )
    VALUES (
        SEQ_TIPO_EVENTO.NEXTVAL,
        TRIM(P_NM_TIPO_EVENTO),
        P_DS_TIPO_EVENTO
    );

EXCEPTION
    WHEN EX_NOME_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_TIPO_EVENTO', SQLCODE, 'NOME INVALIDO OU VAZIO', P_NM_TIPO_EVENTO);
        DBMS_OUTPUT.PUT_LINE('Nome do tipo de evento inválido ou vazio');

    WHEN EX_JA_CADASTRADO THEN
        PRC_LOG_ERRO('PRC_INSERT_TIPO_EVENTO', SQLCODE, 'TIPO EVENTO JA CADASTRADO', P_NM_TIPO_EVENTO);
        DBMS_OUTPUT.PUT_LINE('Tipo de evento já cadastrado: ' || P_NM_TIPO_EVENTO);

    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_TIPO_EVENTO', SQLCODE, SQLERRM, P_NM_TIPO_EVENTO);
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/


-- =============================================================================
-- VETERINARIO
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERT_VETERINARIO (
    P_ID_CLINICA      IN NUMBER,
    P_NM_VETERINARIO  IN VARCHAR2,
    P_NR_CRMV         IN VARCHAR2,
    P_SG_UF_CRMV      IN CHAR,
    P_DS_EMAIL        IN VARCHAR2
)
AS
BEGIN
    INSERT INTO VETERINARIO (
        ID_VETERINARIO,
        ID_CLINICA,
        NM_VETERINARIO,
        NR_CRMV,
        SG_UF_CRMV,
        DS_EMAIL
    )
    VALUES (
        SEQ_VETERINARIO.NEXTVAL,
        P_ID_CLINICA,
        P_NM_VETERINARIO,
        P_NR_CRMV,
        P_SG_UF_CRMV,
        P_DS_EMAIL
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PRC_LOG_ERRO('PRC_INSERT_VETERINARIO', SQLCODE, SQLERRM, P_NM_VETERINARIO);

    WHEN VALUE_ERROR THEN
        PRC_LOG_ERRO('PRC_INSERT_VETERINARIO', SQLCODE, SQLERRM, P_NM_VETERINARIO);

    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_VETERINARIO', SQLCODE, SQLERRM, P_NM_VETERINARIO);
END;
/


-- ============================================================================
-- PROCEDURE TUTOR
-- ============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERIR_TUTOR (
    P_ID_CLINICA      IN NUMBER,
    P_NM_TUTOR        IN VARCHAR2,
    P_NR_CPF          IN VARCHAR2,
    P_DS_EMAIL        IN VARCHAR2,
    P_DS_TELEFONE     IN VARCHAR2
)
IS

    V_QTD NUMBER;

    EX_CPF_DUPLICADO EXCEPTION;
    EX_CLINICA_INVALIDA EXCEPTION;

BEGIN

    SELECT COUNT(*)
    INTO V_QTD
    FROM TUTOR
    WHERE NR_CPF = P_NR_CPF;

    IF V_QTD > 0 THEN
        RAISE EX_CPF_DUPLICADO;
    END IF;

    SELECT COUNT(*)
    INTO V_QTD
    FROM CLINICA
    WHERE ID_CLINICA = P_ID_CLINICA;

    IF V_QTD = 0 THEN
        RAISE EX_CLINICA_INVALIDA;
    END IF;

    INSERT INTO TUTOR (
        ID_CLINICA,
        NM_TUTOR,
        NR_CPF,
        DS_EMAIL,
        DS_TELEFONE
    )
    VALUES (
        P_ID_CLINICA,
        P_NM_TUTOR,
        P_NR_CPF,
        P_DS_EMAIL,
        P_DS_TELEFONE
    );

    COMMIT;

EXCEPTION

    WHEN EX_CPF_DUPLICADO THEN

        PRC_LOG_ERRO(
            'PRC_INSERIR_TUTOR',
            SQLCODE,
            'CPF DUPLICADO',
            'CPF=' || P_NR_CPF
        );

        DBMS_OUTPUT.PUT_LINE('CPF já cadastrado');

    WHEN EX_CLINICA_INVALIDA THEN

        PRC_LOG_ERRO(
            'PRC_INSERIR_TUTOR',
            SQLCODE,
            'CLINICA INVALIDA',
            'ID_CLINICA=' || P_ID_CLINICA
        );

        DBMS_OUTPUT.PUT_LINE('Clínica não encontrada');

    WHEN OTHERS THEN

        PRC_LOG_ERRO(
            'PRC_INSERIR_TUTOR',
            SQLCODE,
            SQLERRM,
            'ERRO GERAL'
        );

        DBMS_OUTPUT.PUT_LINE('Erro inesperado');

END;
/

-- =============================================================================
-- RACA
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERT_RACA (
    P_ID_ESPECIE       IN NUMBER,
    P_NM_RACA          IN VARCHAR2,
    P_DS_PREDISPOSICAO IN VARCHAR2
)
AS
BEGIN
    INSERT INTO RACA (
        ID_RACA,
        ID_ESPECIE,
        NM_RACA,
        DS_PREDISPOSICAO
    )
    VALUES (
        SEQ_RACA.NEXTVAL,
        P_ID_ESPECIE,
        P_NM_RACA,
        P_DS_PREDISPOSICAO
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PRC_LOG_ERRO('PRC_INSERT_RACA', SQLCODE, SQLERRM, P_NM_RACA);

    WHEN VALUE_ERROR THEN
        PRC_LOG_ERRO('PRC_INSERT_RACA', SQLCODE, SQLERRM, P_NM_RACA);

    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_RACA', SQLCODE, SQLERRM, P_NM_RACA);
END;
/




-- ============================================================================
-- PROCEDURE PET
-- ============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERIR_PET (
    P_ID_ESPECIE      IN NUMBER,
    P_ID_RACA         IN NUMBER,
    P_NM_PET          IN VARCHAR2,
    P_SG_SEXO         IN CHAR,
    P_NR_PESO_KG      IN NUMBER
)
IS

    EX_SEXO_INVALIDO EXCEPTION;
    EX_PESO_INVALIDO EXCEPTION;

BEGIN

    IF P_SG_SEXO NOT IN ('M', 'F') THEN
        RAISE EX_SEXO_INVALIDO;
    END IF;

    IF P_NR_PESO_KG <= 0 THEN
        RAISE EX_PESO_INVALIDO;
    END IF;

    INSERT INTO PET (
        ID_ESPECIE,
        ID_RACA,
        NM_PET,
        SG_SEXO,
        NR_PESO_KG
    )
    VALUES (
        P_ID_ESPECIE,
        P_ID_RACA,
        P_NM_PET,
        P_SG_SEXO,
        P_NR_PESO_KG
    );

    COMMIT;

EXCEPTION

    WHEN EX_SEXO_INVALIDO THEN

        PRC_LOG_ERRO(
            'PRC_INSERIR_PET',
            SQLCODE,
            'SEXO INVALIDO',
            'SEXO=' || P_SG_SEXO
        );

        DBMS_OUTPUT.PUT_LINE('Sexo inválido');

    WHEN EX_PESO_INVALIDO THEN

        PRC_LOG_ERRO(
            'PRC_INSERIR_PET',
            SQLCODE,
            'PESO INVALIDO',
            'PESO=' || P_NR_PESO_KG
        );

        DBMS_OUTPUT.PUT_LINE('Peso inválido');

    WHEN OTHERS THEN

        PRC_LOG_ERRO(
            'PRC_INSERIR_PET',
            SQLCODE,
            SQLERRM,
            'ERRO GERAL'
        );

        DBMS_OUTPUT.PUT_LINE('Erro inesperado');

END;
/

-- =============================================================================
-- TUTOR_PET
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERT_TUTOR_PET (
    P_ID_TUTOR IN NUMBER,
    P_ID_PET   IN NUMBER
)
AS
BEGIN
    INSERT INTO TUTOR_PET (
        ID_TUTOR,
        ID_PET
    )
    VALUES (
        P_ID_TUTOR,
        P_ID_PET
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PRC_LOG_ERRO('PRC_INSERT_TUTOR_PET', SQLCODE, SQLERRM, 'RELACIONAMENTO');

    WHEN VALUE_ERROR THEN
        PRC_LOG_ERRO('PRC_INSERT_TUTOR_PET', SQLCODE, SQLERRM, 'RELACIONAMENTO');

    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_TUTOR_PET', SQLCODE, SQLERRM, 'RELACIONAMENTO');
END;
/


-- =============================================================================
-- EVENTO_CLINICO
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERT_EVENTO (
    P_ID_PET          IN NUMBER,
    P_ID_VETERINARIO  IN NUMBER,
    P_ID_TIPO_EVENTO  IN NUMBER
)
AS
BEGIN
    INSERT INTO EVENTO_CLINICO (
        ID_EVENTO,
        ID_PET,
        ID_VETERINARIO,
        ID_TIPO_EVENTO
    )
    VALUES (
        SEQ_EVENTO_CLINICO.NEXTVAL,
        P_ID_PET,
        P_ID_VETERINARIO,
        P_ID_TIPO_EVENTO
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PRC_LOG_ERRO('PRC_INSERT_EVENTO', SQLCODE, SQLERRM, 'EVENTO');

    WHEN VALUE_ERROR THEN
        PRC_LOG_ERRO('PRC_INSERT_EVENTO', SQLCODE, SQLERRM, 'EVENTO');

    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_EVENTO', SQLCODE, SQLERRM, 'EVENTO');
END;
/

-- =============================================================================
-- VACINA
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERT_VACINA (
    P_ID_EVENTO   IN NUMBER,
    P_NM_VACINA   IN VARCHAR2,
    P_NR_LOTE     IN VARCHAR2,
    P_DT_APLICACAO IN DATE
)
AS
BEGIN
    INSERT INTO VACINA (
        ID_VACINA,
        ID_EVENTO,
        NM_VACINA,
        NR_LOTE,
        DT_APLICACAO
    )
    VALUES (
        SEQ_VACINA.NEXTVAL,
        P_ID_EVENTO,
        P_NM_VACINA,
        P_NR_LOTE,
        P_DT_APLICACAO
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PRC_LOG_ERRO('PRC_INSERT_VACINA', SQLCODE, SQLERRM, P_NM_VACINA);

    WHEN VALUE_ERROR THEN
        PRC_LOG_ERRO('PRC_INSERT_VACINA', SQLCODE, SQLERRM, P_NM_VACINA);

    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_VACINA', SQLCODE, SQLERRM, P_NM_VACINA);
END;
/

-- =============================================================================
-- PRESCRICAO
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERT_PRESCRICAO (
    P_ID_EVENTO IN NUMBER
)
AS
BEGIN
    INSERT INTO PRESCRICAO (
        ID_PRESCRICAO,
        ID_EVENTO
    )
    VALUES (
        SEQ_PRESCRICAO.NEXTVAL,
        P_ID_EVENTO
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PRC_LOG_ERRO('PRC_INSERT_PRESCRICAO', SQLCODE, SQLERRM, 'PRESCRICAO');

    WHEN VALUE_ERROR THEN
        PRC_LOG_ERRO('PRC_INSERT_PRESCRICAO', SQLCODE, SQLERRM, 'PRESCRICAO');

    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_PRESCRICAO', SQLCODE, SQLERRM, 'PRESCRICAO');
END;
/

-- =============================================================================
-- EXAME
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_INSERT_EXAME (
    P_ID_EVENTO IN NUMBER,
    P_NM_EXAME  IN VARCHAR2
)
AS
BEGIN
    INSERT INTO EXAME (
        ID_EXAME,
        ID_EVENTO,
        NM_EXAME
    )
    VALUES (
        SEQ_EXAME.NEXTVAL,
        P_ID_EVENTO,
        P_NM_EXAME
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PRC_LOG_ERRO('PRC_INSERT_EXAME', SQLCODE, SQLERRM, P_NM_EXAME);

    WHEN VALUE_ERROR THEN
        PRC_LOG_ERRO('PRC_INSERT_EXAME', SQLCODE, SQLERRM, P_NM_EXAME);

    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_EXAME', SQLCODE, SQLERRM, P_NM_EXAME);
END;
/

-- PRESCRICAO_MEDICAMENTO
CREATE OR REPLACE PROCEDURE PRC_INSERT_PRESCRICAO_MED (
    P_ID_PRESCRICAO   IN NUMBER,
    P_ID_MEDICAMENTO  IN NUMBER,
    P_DS_DOSAGEM      IN VARCHAR2,
    P_DS_FREQUENCIA   IN VARCHAR2,
    P_NR_DURACAO_DIAS IN NUMBER
)
AS
    V_EXISTE_PRESC NUMBER;
    V_EXISTE_MED   NUMBER;
    V_EXISTE_ITEM  NUMBER;
 
    EX_PRESCRICAO_INVALIDA  EXCEPTION;
    EX_MEDICAMENTO_INVALIDO EXCEPTION;
    EX_ITEM_DUPLICADO       EXCEPTION;
 
BEGIN
 
    IF P_DS_DOSAGEM IS NULL OR LENGTH(TRIM(P_DS_DOSAGEM)) = 0 THEN
        PRC_LOG_ERRO('PRC_INSERT_PRESCRICAO_MED', -20001, 'DOSAGEM INVALIDA OU VAZIA', 'ID_PRESC=' || P_ID_PRESCRICAO);
        DBMS_OUTPUT.PUT_LINE('Dosagem inválida ou vazia');
        RETURN;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_PRESC
    FROM PRESCRICAO
    WHERE ID_PRESCRICAO = P_ID_PRESCRICAO;
 
    IF V_EXISTE_PRESC = 0 THEN
        RAISE EX_PRESCRICAO_INVALIDA;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_MED
    FROM MEDICAMENTO
    WHERE ID_MEDICAMENTO = P_ID_MEDICAMENTO;
 
    IF V_EXISTE_MED = 0 THEN
        RAISE EX_MEDICAMENTO_INVALIDO;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_ITEM
    FROM PRESCRICAO_MEDICAMENTO
    WHERE ID_PRESCRICAO  = P_ID_PRESCRICAO
      AND ID_MEDICAMENTO = P_ID_MEDICAMENTO;
 
    IF V_EXISTE_ITEM > 0 THEN
        RAISE EX_ITEM_DUPLICADO;
    END IF;
 
    INSERT INTO PRESCRICAO_MEDICAMENTO (
        ID_PRESCRICAO,
        ID_MEDICAMENTO,
        DS_DOSAGEM,
        DS_FREQUENCIA,
        NR_DURACAO_DIAS
    )
    VALUES (
        P_ID_PRESCRICAO,
        P_ID_MEDICAMENTO,
        TRIM(P_DS_DOSAGEM),
        P_DS_FREQUENCIA,
        P_NR_DURACAO_DIAS
    );
 
EXCEPTION
    WHEN EX_PRESCRICAO_INVALIDA THEN
        PRC_LOG_ERRO('PRC_INSERT_PRESCRICAO_MED', SQLCODE, 'PRESCRICAO NAO ENCONTRADA', 'ID_PRESC=' || P_ID_PRESCRICAO);
        DBMS_OUTPUT.PUT_LINE('Prescrição não encontrada: ' || P_ID_PRESCRICAO);
 
    WHEN EX_MEDICAMENTO_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_PRESCRICAO_MED', SQLCODE, 'MEDICAMENTO NAO ENCONTRADO', 'ID_MED=' || P_ID_MEDICAMENTO);
        DBMS_OUTPUT.PUT_LINE('Medicamento não encontrado: ' || P_ID_MEDICAMENTO);
 
    WHEN EX_ITEM_DUPLICADO THEN
        PRC_LOG_ERRO('PRC_INSERT_PRESCRICAO_MED', SQLCODE, 'ITEM JA EXISTE NA PRESCRICAO', 'ID_PRESC=' || P_ID_PRESCRICAO || ' ID_MED=' || P_ID_MEDICAMENTO);
        DBMS_OUTPUT.PUT_LINE('Medicamento já adicionado nesta prescrição');
 
    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_PRESCRICAO_MED', SQLCODE, SQLERRM, 'ERRO GERAL');
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/


-- DOCUMENTO
CREATE OR REPLACE PROCEDURE PRC_INSERT_DOCUMENTO (
    P_ID_PET         IN NUMBER,
    P_ID_EVENTO      IN NUMBER,
    P_NM_DOCUMENTO   IN VARCHAR2,
    P_DS_TIPO        IN VARCHAR2,
    P_DS_URL_STORAGE IN VARCHAR2
)
AS
    V_EXISTE_PET    NUMBER;
    V_EXISTE_EVENTO NUMBER;
 
    EX_PET_INVALIDO    EXCEPTION;
    EX_EVENTO_INVALIDO EXCEPTION;
    EX_TIPO_INVALIDO   EXCEPTION;
 
BEGIN
 
    IF P_DS_TIPO NOT IN ('LAUDO','RECEITA','ATESTADO','EXAME_PDF','IMAGEM','OUTRO') THEN
        RAISE EX_TIPO_INVALIDO;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_PET
    FROM PET
    WHERE ID_PET = P_ID_PET;
 
    IF V_EXISTE_PET = 0 THEN
        RAISE EX_PET_INVALIDO;
    END IF;
 
    IF P_ID_EVENTO IS NOT NULL THEN
        SELECT COUNT(*) INTO V_EXISTE_EVENTO
        FROM EVENTO_CLINICO
        WHERE ID_EVENTO = P_ID_EVENTO;
 
        IF V_EXISTE_EVENTO = 0 THEN
            RAISE EX_EVENTO_INVALIDO;
        END IF;
    END IF;
 
    INSERT INTO DOCUMENTO (
        ID_EVENTO,
        ID_PET,
        NM_DOCUMENTO,
        DS_TIPO,
        DS_URL_STORAGE
    )
    VALUES (
        P_ID_EVENTO,
        P_ID_PET,
        TRIM(P_NM_DOCUMENTO),
        P_DS_TIPO,
        P_DS_URL_STORAGE
    );
 
EXCEPTION
    WHEN EX_TIPO_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_DOCUMENTO', SQLCODE, 'TIPO INVALIDO', 'TIPO=' || P_DS_TIPO);
        DBMS_OUTPUT.PUT_LINE('Tipo inválido. Use: LAUDO, RECEITA, ATESTADO, EXAME_PDF, IMAGEM ou OUTRO');
 
    WHEN EX_PET_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_DOCUMENTO', SQLCODE, 'PET NAO ENCONTRADO', 'ID_PET=' || P_ID_PET);
        DBMS_OUTPUT.PUT_LINE('Pet não encontrado: ' || P_ID_PET);
 
    WHEN EX_EVENTO_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_DOCUMENTO', SQLCODE, 'EVENTO NAO ENCONTRADO', 'ID_EVENTO=' || P_ID_EVENTO);
        DBMS_OUTPUT.PUT_LINE('Evento clínico não encontrado: ' || P_ID_EVENTO);
 
    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_DOCUMENTO', SQLCODE, SQLERRM, 'ERRO GERAL');
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/


-- NOTIFICACAO
CREATE OR REPLACE PROCEDURE PRC_INSERT_NOTIFICACAO (
    P_ID_TUTOR    IN NUMBER,
    P_ID_PET      IN NUMBER,
    P_DS_CANAL    IN VARCHAR2,
    P_DS_TIPO     IN VARCHAR2,
    P_DS_TITULO   IN VARCHAR2,
    P_DS_MENSAGEM IN VARCHAR2,
    P_DT_AGENDADA IN TIMESTAMP
)
AS
    V_EXISTE_TUTOR NUMBER;
    V_EXISTE_PET   NUMBER;
 
    EX_TUTOR_INVALIDO EXCEPTION;
    EX_PET_INVALIDO   EXCEPTION;
    EX_CANAL_INVALIDO EXCEPTION;
    EX_TIPO_INVALIDO  EXCEPTION;
 
BEGIN
 
    IF P_DS_CANAL NOT IN ('WHATSAPP','EMAIL','PUSH','SMS') THEN
        RAISE EX_CANAL_INVALIDO;
    END IF;
 
    IF P_DS_TIPO NOT IN ('LEMBRETE_VACINA','RETORNO','PRESCRICAO_NOVA','RED_FLAG','BOAS_VINDAS','PESQUISA','OUTRO') THEN
        RAISE EX_TIPO_INVALIDO;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_TUTOR
    FROM TUTOR
    WHERE ID_TUTOR = P_ID_TUTOR;
 
    IF V_EXISTE_TUTOR = 0 THEN
        RAISE EX_TUTOR_INVALIDO;
    END IF;
 
    IF P_ID_PET IS NOT NULL THEN
        SELECT COUNT(*) INTO V_EXISTE_PET
        FROM PET
        WHERE ID_PET = P_ID_PET;
 
        IF V_EXISTE_PET = 0 THEN
            RAISE EX_PET_INVALIDO;
        END IF;
    END IF;
 
    INSERT INTO NOTIFICACAO (
        ID_TUTOR,
        ID_PET,
        DS_CANAL,
        DS_TIPO,
        DS_TITULO,
        DS_MENSAGEM,
        DT_AGENDADA
    )
    VALUES (
        P_ID_TUTOR,
        P_ID_PET,
        P_DS_CANAL,
        P_DS_TIPO,
        P_DS_TITULO,
        P_DS_MENSAGEM,
        P_DT_AGENDADA
    );
 
EXCEPTION
    WHEN EX_CANAL_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_NOTIFICACAO', SQLCODE, 'CANAL INVALIDO', 'CANAL=' || P_DS_CANAL);
        DBMS_OUTPUT.PUT_LINE('Canal inválido. Use: WHATSAPP, EMAIL, PUSH ou SMS');
 
    WHEN EX_TIPO_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_NOTIFICACAO', SQLCODE, 'TIPO INVALIDO', 'TIPO=' || P_DS_TIPO);
        DBMS_OUTPUT.PUT_LINE('Tipo inválido. Verifique os valores permitidos');
 
    WHEN EX_TUTOR_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_NOTIFICACAO', SQLCODE, 'TUTOR NAO ENCONTRADO', 'ID_TUTOR=' || P_ID_TUTOR);
        DBMS_OUTPUT.PUT_LINE('Tutor não encontrado: ' || P_ID_TUTOR);
 
    WHEN EX_PET_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_NOTIFICACAO', SQLCODE, 'PET NAO ENCONTRADO', 'ID_PET=' || P_ID_PET);
        DBMS_OUTPUT.PUT_LINE('Pet não encontrado: ' || P_ID_PET);
 
    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_NOTIFICACAO', SQLCODE, SQLERRM, 'ERRO GERAL');
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/

--inserir dispositivo

CREATE OR REPLACE PROCEDURE PRC_INSERT_DISPOSITIVO_IOT (
    P_ID_CLINICA       IN NUMBER,
    P_DS_IDENTIFICADOR IN VARCHAR2,
    P_NM_DISPOSITIVO   IN VARCHAR2,
    P_NR_TEMP_MINIMA   IN NUMBER,
    P_NR_TEMP_MAXIMA   IN NUMBER
)
AS
    V_EXISTE_CLINICA NUMBER;
    V_EXISTE_ID      NUMBER;
 
    EX_CLINICA_INVALIDA  EXCEPTION;
    EX_IDENTIFICADOR_DUP EXCEPTION;
    EX_NOME_INVALIDO     EXCEPTION;
    EX_FAIXA_INVALIDA    EXCEPTION;
 
BEGIN
 
    IF P_NM_DISPOSITIVO IS NULL OR LENGTH(TRIM(P_NM_DISPOSITIVO)) = 0 THEN
        RAISE EX_NOME_INVALIDO;
    END IF;
 
    IF P_NR_TEMP_MAXIMA <= P_NR_TEMP_MINIMA THEN
        RAISE EX_FAIXA_INVALIDA;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_CLINICA
    FROM CLINICA
    WHERE ID_CLINICA = P_ID_CLINICA;
 
    IF V_EXISTE_CLINICA = 0 THEN
        RAISE EX_CLINICA_INVALIDA;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_ID
    FROM DISPOSITIVO_IOT
    WHERE DS_IDENTIFICADOR = TRIM(P_DS_IDENTIFICADOR);
 
    IF V_EXISTE_ID > 0 THEN
        RAISE EX_IDENTIFICADOR_DUP;
    END IF;
 
    INSERT INTO DISPOSITIVO_IOT (
        ID_CLINICA,
        DS_IDENTIFICADOR,
        NM_DISPOSITIVO,
        NR_TEMP_MINIMA,
        NR_TEMP_MAXIMA
    )
    VALUES (
        P_ID_CLINICA,
        TRIM(P_DS_IDENTIFICADOR),
        TRIM(P_NM_DISPOSITIVO),
        P_NR_TEMP_MINIMA,
        P_NR_TEMP_MAXIMA
    );
 
EXCEPTION
    WHEN EX_NOME_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_DISPOSITIVO_IOT', SQLCODE, 'NOME INVALIDO OU VAZIO', 'ID_CLINICA=' || P_ID_CLINICA);
        DBMS_OUTPUT.PUT_LINE('Nome do dispositivo inválido ou vazio');
 
    WHEN EX_FAIXA_INVALIDA THEN
        PRC_LOG_ERRO('PRC_INSERT_DISPOSITIVO_IOT', SQLCODE, 'FAIXA DE TEMPERATURA INVALIDA', 'MIN=' || P_NR_TEMP_MINIMA || ' MAX=' || P_NR_TEMP_MAXIMA);
        DBMS_OUTPUT.PUT_LINE('Temperatura máxima deve ser maior que a mínima');
 
    WHEN EX_CLINICA_INVALIDA THEN
        PRC_LOG_ERRO('PRC_INSERT_DISPOSITIVO_IOT', SQLCODE, 'CLINICA NAO ENCONTRADA', 'ID_CLINICA=' || P_ID_CLINICA);
        DBMS_OUTPUT.PUT_LINE('Clínica não encontrada: ' || P_ID_CLINICA);
 
    WHEN EX_IDENTIFICADOR_DUP THEN
        PRC_LOG_ERRO('PRC_INSERT_DISPOSITIVO_IOT', SQLCODE, 'IDENTIFICADOR JA CADASTRADO', 'ID=' || P_DS_IDENTIFICADOR);
        DBMS_OUTPUT.PUT_LINE('Identificador já cadastrado: ' || P_DS_IDENTIFICADOR);
 
    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_DISPOSITIVO_IOT', SQLCODE, SQLERRM, 'ERRO GERAL');
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/


-- LEITURA_TEMPERATURA
CREATE OR REPLACE PROCEDURE PRC_INSERT_LEITURA_TEMP (
    P_ID_DISPOSITIVO IN NUMBER,
    P_NR_TEMPERATURA IN NUMBER,
    P_NR_UMIDADE     IN NUMBER
)
AS
    V_EXISTE_DISP  NUMBER;
    V_TEMP_MIN     NUMBER;
    V_TEMP_MAX     NUMBER;
    V_DENTRO_FAIXA CHAR(1);
 
    EX_DISPOSITIVO_INVALIDO EXCEPTION;
    EX_TEMPERATURA_INVALIDA EXCEPTION;
 
BEGIN
 
    IF P_NR_TEMPERATURA IS NULL OR P_NR_TEMPERATURA NOT BETWEEN -40 AND 80 THEN
        RAISE EX_TEMPERATURA_INVALIDA;
    END IF;
 
    SELECT COUNT(*), MIN(NR_TEMP_MINIMA), MIN(NR_TEMP_MAXIMA)
    INTO V_EXISTE_DISP, V_TEMP_MIN, V_TEMP_MAX
    FROM DISPOSITIVO_IOT
    WHERE ID_DISPOSITIVO = P_ID_DISPOSITIVO;
 
    IF V_EXISTE_DISP = 0 THEN
        RAISE EX_DISPOSITIVO_INVALIDO;
    END IF;
 
    IF P_NR_TEMPERATURA BETWEEN V_TEMP_MIN AND V_TEMP_MAX THEN
        V_DENTRO_FAIXA := 'S';
    ELSE
        V_DENTRO_FAIXA := 'N';
    END IF;
 
    INSERT INTO LEITURA_TEMPERATURA (
        ID_DISPOSITIVO,
        NR_TEMPERATURA,
        NR_UMIDADE,
        ST_DENTRO_FAIXA
    )
    VALUES (
        P_ID_DISPOSITIVO,
        P_NR_TEMPERATURA,
        P_NR_UMIDADE,
        V_DENTRO_FAIXA
    );
 
    UPDATE DISPOSITIVO_IOT
    SET DT_ULTIMA_LEITURA = SYSTIMESTAMP
    WHERE ID_DISPOSITIVO = P_ID_DISPOSITIVO;
 
EXCEPTION
    WHEN EX_TEMPERATURA_INVALIDA THEN
        PRC_LOG_ERRO('PRC_INSERT_LEITURA_TEMP', SQLCODE, 'TEMPERATURA FORA DO RANGE', 'TEMP=' || P_NR_TEMPERATURA);
        DBMS_OUTPUT.PUT_LINE('Temperatura inválida. Deve estar entre -40 e 80 graus C');
 
    WHEN EX_DISPOSITIVO_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_LEITURA_TEMP', SQLCODE, 'DISPOSITIVO NAO ENCONTRADO', 'ID_DISP=' || P_ID_DISPOSITIVO);
        DBMS_OUTPUT.PUT_LINE('Dispositivo não encontrado: ' || P_ID_DISPOSITIVO);
 
    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_LEITURA_TEMP', SQLCODE, SQLERRM, 'ERRO GERAL');
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/


-- ALERTA_TEMPERATURA
CREATE OR REPLACE PROCEDURE PRC_INSERT_ALERTA_TEMP (
    P_ID_DISPOSITIVO     IN NUMBER,
    P_DS_TIPO_ALERTA     IN VARCHAR2,
    P_DS_SEVERIDADE      IN VARCHAR2,
    P_NR_TEMP_REGISTRADA IN NUMBER,
    P_DS_MENSAGEM        IN VARCHAR2
)
AS
    V_EXISTE_DISP  NUMBER;
    V_ALERTA_ATIVO NUMBER;
 
    EX_DISPOSITIVO_INVALIDO EXCEPTION;
    EX_TIPO_INVALIDO        EXCEPTION;
    EX_SEVERIDADE_INVALIDA  EXCEPTION;
    EX_ALERTA_JA_ATIVO      EXCEPTION;
 
BEGIN
 
    IF P_DS_TIPO_ALERTA NOT IN ('TEMP_ALTA','TEMP_BAIXA','SENSOR_OFFLINE','VARIACAO_BRUSCA') THEN
        RAISE EX_TIPO_INVALIDO;
    END IF;
 
    IF P_DS_SEVERIDADE NOT IN ('BAIXA','MEDIA','ALTA','CRITICA') THEN
        RAISE EX_SEVERIDADE_INVALIDA;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_DISP
    FROM DISPOSITIVO_IOT
    WHERE ID_DISPOSITIVO = P_ID_DISPOSITIVO;
 
    IF V_EXISTE_DISP = 0 THEN
        RAISE EX_DISPOSITIVO_INVALIDO;
    END IF;
 
    SELECT COUNT(*) INTO V_ALERTA_ATIVO
    FROM ALERTA_TEMPERATURA
    WHERE ID_DISPOSITIVO = P_ID_DISPOSITIVO
      AND DS_TIPO_ALERTA = P_DS_TIPO_ALERTA
      AND ST_RESOLVIDO   = 'N';
 
    IF V_ALERTA_ATIVO > 0 THEN
        RAISE EX_ALERTA_JA_ATIVO;
    END IF;
 
    INSERT INTO ALERTA_TEMPERATURA (
        ID_DISPOSITIVO,
        DS_TIPO_ALERTA,
        DS_SEVERIDADE,
        NR_TEMP_REGISTRADA,
        DS_MENSAGEM
    )
    VALUES (
        P_ID_DISPOSITIVO,
        P_DS_TIPO_ALERTA,
        P_DS_SEVERIDADE,
        P_NR_TEMP_REGISTRADA,
        P_DS_MENSAGEM
    );
 
EXCEPTION
    WHEN EX_TIPO_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_ALERTA_TEMP', SQLCODE, 'TIPO DE ALERTA INVALIDO', 'TIPO=' || P_DS_TIPO_ALERTA);
        DBMS_OUTPUT.PUT_LINE('Tipo inválido. Use: TEMP_ALTA, TEMP_BAIXA, SENSOR_OFFLINE ou VARIACAO_BRUSCA');
 
    WHEN EX_SEVERIDADE_INVALIDA THEN
        PRC_LOG_ERRO('PRC_INSERT_ALERTA_TEMP', SQLCODE, 'SEVERIDADE INVALIDA', 'SEV=' || P_DS_SEVERIDADE);
        DBMS_OUTPUT.PUT_LINE('Severidade inválida. Use: BAIXA, MEDIA, ALTA ou CRITICA');
 
    WHEN EX_DISPOSITIVO_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_ALERTA_TEMP', SQLCODE, 'DISPOSITIVO NAO ENCONTRADO', 'ID_DISP=' || P_ID_DISPOSITIVO);
        DBMS_OUTPUT.PUT_LINE('Dispositivo não encontrado: ' || P_ID_DISPOSITIVO);
 
    WHEN EX_ALERTA_JA_ATIVO THEN
        PRC_LOG_ERRO('PRC_INSERT_ALERTA_TEMP', SQLCODE, 'ALERTA DO MESMO TIPO JA ATIVO', 'ID_DISP=' || P_ID_DISPOSITIVO || ' TIPO=' || P_DS_TIPO_ALERTA);
        DBMS_OUTPUT.PUT_LINE('Já existe um alerta ativo deste tipo para este dispositivo');
 
    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_ALERTA_TEMP', SQLCODE, SQLERRM, 'ERRO GERAL');
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/

-- =============================================================================
-- CONTA_TUTOR
-- =============================================================================
 
CREATE OR REPLACE PROCEDURE PRC_INSERT_CONTA_TUTOR (
    P_ID_TUTOR        IN NUMBER,
    P_DS_EMAIL_LOGIN  IN VARCHAR2,
    P_DS_SENHA_HASH   IN VARCHAR2,
    P_ID_INVITE_USADO IN NUMBER
)
AS
    V_EXISTE_TUTOR  NUMBER;
    V_EXISTE_CONTA  NUMBER;
    V_EXISTE_EMAIL  NUMBER;
    V_EXISTE_INVITE NUMBER;
 
    EX_TUTOR_INVALIDO  EXCEPTION;
    EX_CONTA_DUPLICADA EXCEPTION;
    EX_EMAIL_DUPLICADO EXCEPTION;
    EX_INVITE_INVALIDO EXCEPTION;
 
BEGIN
 
    SELECT COUNT(*) INTO V_EXISTE_TUTOR
    FROM TUTOR
    WHERE ID_TUTOR = P_ID_TUTOR;
 
    IF V_EXISTE_TUTOR = 0 THEN
        RAISE EX_TUTOR_INVALIDO;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_CONTA
    FROM CONTA_TUTOR
    WHERE ID_TUTOR = P_ID_TUTOR;
 
    IF V_EXISTE_CONTA > 0 THEN
        RAISE EX_CONTA_DUPLICADA;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_EMAIL
    FROM CONTA_TUTOR
    WHERE DS_EMAIL_LOGIN = TRIM(P_DS_EMAIL_LOGIN);
 
    IF V_EXISTE_EMAIL > 0 THEN
        RAISE EX_EMAIL_DUPLICADO;
    END IF;
 
    IF P_ID_INVITE_USADO IS NOT NULL THEN
        SELECT COUNT(*) INTO V_EXISTE_INVITE
        FROM INVITE_TUTOR
        WHERE ID_INVITE    = P_ID_INVITE_USADO
          AND ST_ATIVO     = 'S'
          AND DT_EXPIRACAO > SYSTIMESTAMP;
 
        IF V_EXISTE_INVITE = 0 THEN
            RAISE EX_INVITE_INVALIDO;
        END IF;
    END IF;
 
    INSERT INTO CONTA_TUTOR (
        ID_TUTOR,
        DS_EMAIL_LOGIN,
        DS_SENHA_HASH,
        ID_INVITE_USADO
    )
    VALUES (
        P_ID_TUTOR,
        TRIM(P_DS_EMAIL_LOGIN),
        P_DS_SENHA_HASH,
        P_ID_INVITE_USADO
    );
 
EXCEPTION
    WHEN EX_TUTOR_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_CONTA_TUTOR', SQLCODE, 'TUTOR NAO ENCONTRADO', 'ID_TUTOR=' || P_ID_TUTOR);
        DBMS_OUTPUT.PUT_LINE('Tutor não encontrado: ' || P_ID_TUTOR);
 
    WHEN EX_CONTA_DUPLICADA THEN
        PRC_LOG_ERRO('PRC_INSERT_CONTA_TUTOR', SQLCODE, 'TUTOR JA POSSUI CONTA', 'ID_TUTOR=' || P_ID_TUTOR);
        DBMS_OUTPUT.PUT_LINE('Este tutor já possui uma conta cadastrada');
 
    WHEN EX_EMAIL_DUPLICADO THEN
        PRC_LOG_ERRO('PRC_INSERT_CONTA_TUTOR', SQLCODE, 'EMAIL JA CADASTRADO', 'EMAIL=' || P_DS_EMAIL_LOGIN);
        DBMS_OUTPUT.PUT_LINE('E-mail já cadastrado: ' || P_DS_EMAIL_LOGIN);
 
    WHEN EX_INVITE_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_CONTA_TUTOR', SQLCODE, 'INVITE INVALIDO OU EXPIRADO', 'ID_INVITE=' || P_ID_INVITE_USADO);
        DBMS_OUTPUT.PUT_LINE('Invite inválido, expirado ou já utilizado');
 
    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_CONTA_TUTOR', SQLCODE, SQLERRM, 'ERRO GERAL');
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/
 
 
-- =============================================================================
-- CONSENTIMENTO
-- =============================================================================
 
CREATE OR REPLACE PROCEDURE PRC_INSERT_CONSENTIMENTO (
    P_ID_TUTOR        IN NUMBER,
    P_DS_TIPO         IN VARCHAR2,
    P_DS_VERSAO_TERMO IN VARCHAR2,
    P_ST_ACEITO       IN CHAR,
    P_DS_IP_ACEITE    IN VARCHAR2
)
AS
    V_EXISTE_TUTOR NUMBER;
 
    EX_TUTOR_INVALIDO  EXCEPTION;
    EX_TIPO_INVALIDO   EXCEPTION;
    EX_STATUS_INVALIDO EXCEPTION;
 
BEGIN
 
    IF P_DS_TIPO NOT IN ('TELEORIENTACAO','LEMBRETES','DADOS_ANONIMOS','COMPARTILHAR_SEGURADORA','MARKETING') THEN
        RAISE EX_TIPO_INVALIDO;
    END IF;
 
    IF P_ST_ACEITO NOT IN ('S','N') THEN
        RAISE EX_STATUS_INVALIDO;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_TUTOR
    FROM TUTOR
    WHERE ID_TUTOR = P_ID_TUTOR;
 
    IF V_EXISTE_TUTOR = 0 THEN
        RAISE EX_TUTOR_INVALIDO;
    END IF;
 
    INSERT INTO CONSENTIMENTO (
        ID_TUTOR,
        DS_TIPO,
        DS_VERSAO_TERMO,
        ST_ACEITO,
        DS_IP_ACEITE
    )
    VALUES (
        P_ID_TUTOR,
        P_DS_TIPO,
        P_DS_VERSAO_TERMO,
        P_ST_ACEITO,
        P_DS_IP_ACEITE
    );
 
EXCEPTION
    WHEN EX_TIPO_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_CONSENTIMENTO', SQLCODE, 'TIPO INVALIDO', 'TIPO=' || P_DS_TIPO);
        DBMS_OUTPUT.PUT_LINE('Tipo inválido. Use: TELEORIENTACAO, LEMBRETES, DADOS_ANONIMOS, COMPARTILHAR_SEGURADORA ou MARKETING');
 
    WHEN EX_STATUS_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_CONSENTIMENTO', SQLCODE, 'STATUS ACEITO INVALIDO', 'ST_ACEITO=' || P_ST_ACEITO);
        DBMS_OUTPUT.PUT_LINE('Status inválido. Use S ou N');
 
    WHEN EX_TUTOR_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_CONSENTIMENTO', SQLCODE, 'TUTOR NAO ENCONTRADO', 'ID_TUTOR=' || P_ID_TUTOR);
        DBMS_OUTPUT.PUT_LINE('Tutor não encontrado: ' || P_ID_TUTOR);
 
    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_CONSENTIMENTO', SQLCODE, SQLERRM, 'ERRO GERAL');
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/
 
 
-- =============================================================================
-- AGENDAMENTO
-- =============================================================================
 
CREATE OR REPLACE PROCEDURE PRC_INSERT_AGENDAMENTO (
    P_ID_TUTOR       IN NUMBER,
    P_ID_PET         IN NUMBER,
    P_ID_CLINICA     IN NUMBER,
    P_ID_VETERINARIO IN NUMBER,
    P_DT_AGENDAMENTO IN TIMESTAMP,
    P_DS_TIPO        IN VARCHAR2,
    P_DS_ORIGEM      IN VARCHAR2
)
AS
    V_EXISTE_TUTOR  NUMBER;
    V_EXISTE_PET    NUMBER;
    V_EXISTE_CLINIC NUMBER;
 
    EX_TUTOR_INVALIDO   EXCEPTION;
    EX_PET_INVALIDO     EXCEPTION;
    EX_CLINICA_INVALIDA EXCEPTION;
    EX_TIPO_INVALIDO    EXCEPTION;
 
BEGIN
 
    IF P_DS_TIPO NOT IN ('CONSULTA','RETORNO','VACINA','EXAME','PROCEDIMENTO','TELEORIENTACAO') THEN
        RAISE EX_TIPO_INVALIDO;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_TUTOR
    FROM TUTOR
    WHERE ID_TUTOR = P_ID_TUTOR;
 
    IF V_EXISTE_TUTOR = 0 THEN
        RAISE EX_TUTOR_INVALIDO;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_PET
    FROM PET
    WHERE ID_PET = P_ID_PET;
 
    IF V_EXISTE_PET = 0 THEN
        RAISE EX_PET_INVALIDO;
    END IF;
 
    SELECT COUNT(*) INTO V_EXISTE_CLINIC
    FROM CLINICA
    WHERE ID_CLINICA = P_ID_CLINICA;
 
    IF V_EXISTE_CLINIC = 0 THEN
        RAISE EX_CLINICA_INVALIDA;
    END IF;
 
    INSERT INTO AGENDAMENTO (
        ID_TUTOR,
        ID_PET,
        ID_CLINICA,
        ID_VETERINARIO,
        DT_AGENDAMENTO,
        DS_TIPO,
        DS_ORIGEM
    )
    VALUES (
        P_ID_TUTOR,
        P_ID_PET,
        P_ID_CLINICA,
        P_ID_VETERINARIO,
        P_DT_AGENDAMENTO,
        P_DS_TIPO,
        P_DS_ORIGEM
    );
 
EXCEPTION
    WHEN EX_TIPO_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_AGENDAMENTO', SQLCODE, 'TIPO INVALIDO', 'TIPO=' || P_DS_TIPO);
        DBMS_OUTPUT.PUT_LINE('Tipo inválido. Use: CONSULTA, RETORNO, VACINA, EXAME, PROCEDIMENTO ou TELEORIENTACAO');
 
    WHEN EX_TUTOR_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_AGENDAMENTO', SQLCODE, 'TUTOR NAO ENCONTRADO', 'ID_TUTOR=' || P_ID_TUTOR);
        DBMS_OUTPUT.PUT_LINE('Tutor não encontrado: ' || P_ID_TUTOR);
 
    WHEN EX_PET_INVALIDO THEN
        PRC_LOG_ERRO('PRC_INSERT_AGENDAMENTO', SQLCODE, 'PET NAO ENCONTRADO', 'ID_PET=' || P_ID_PET);
        DBMS_OUTPUT.PUT_LINE('Pet não encontrado: ' || P_ID_PET);
 
    WHEN EX_CLINICA_INVALIDA THEN
        PRC_LOG_ERRO('PRC_INSERT_AGENDAMENTO', SQLCODE, 'CLINICA NAO ENCONTRADA', 'ID_CLINICA=' || P_ID_CLINICA);
        DBMS_OUTPUT.PUT_LINE('Clínica não encontrada: ' || P_ID_CLINICA);
 
    WHEN OTHERS THEN
        PRC_LOG_ERRO('PRC_INSERT_AGENDAMENTO', SQLCODE, SQLERRM, 'ERRO GERAL');
        DBMS_OUTPUT.PUT_LINE('Erro inesperado');
END;
/

--CARGA DE DADOS REALIZADO POR CHAMADA DE PROCEDURES

BEGIN PRC_INSERT_EVENTO(P_ID_PET => 1, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 2); END;
/
-- evento 4: Thor - vacina
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 1, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 3); END;
/
-- evento 5: Thor - exame
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 2, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 1); END;
/
-- evento 6: Mel - consulta
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 4, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 1); END;
/
-- evento 7: Bob - consulta
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 4, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 3); END;
/
-- evento 8: Bob - exame
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 5, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 1); END;
/
-- evento 9: Luke - consulta
 
-- ============================================================================
-- MAIS VACINAS
-- (garante: Vacinas por Pet no Relatório 2)
-- ============================================================================
 
BEGIN
    PRC_INSERT_VACINA(
        P_ID_EVENTO    => 4,
        P_NM_VACINA    => 'Antirrábica',
        P_NR_LOTE      => 'L456',
        P_DT_APLICACAO => SYSDATE
    );
END;
/
 
-- ============================================================================
-- MAIS EXAMES
-- (garante: Exames por Status com valores variados no Relatório 2)
-- ============================================================================
 
BEGIN PRC_INSERT_EXAME(P_ID_EVENTO => 5, P_NM_EXAME => 'Urinálise'); END;
/
 
BEGIN PRC_INSERT_EXAME(P_ID_EVENTO => 8, P_NM_EXAME => 'Raio-X Tórax'); END;
/
 
-- Atualiza status do exame 2 para ENTREGUE e exame 3 para CANCELADO
-- (para o relatorio de exames por status ter variedade)
UPDATE EXAME SET ST_STATUS = 'ENTREGUE'  WHERE ID_EXAME = 2;
UPDATE EXAME SET ST_STATUS = 'CANCELADO' WHERE ID_EXAME = 3;
COMMIT;
 
-- ============================================================================
-- MAIS TUTOR_PET
-- (garante: Pets por Tutor com quantidades diferentes)
-- Clayton fica com Thor, Mel, Bob e Luke (4 pets)
-- Marina fica com Mimi (1 pet)
-- ============================================================================
 
BEGIN PRC_INSERT_TUTOR_PET(P_ID_TUTOR => 1, P_ID_PET => 4); END;
/
 
BEGIN PRC_INSERT_TUTOR_PET(P_ID_TUTOR => 1, P_ID_PET => 5); END;
/
 
-- ============================================================================
-- MAIS AGENDAMENTOS
-- (garante: Agendamentos por Clínica com pelo menos 2 clínicas)
-- ============================================================================
 
BEGIN
    PRC_INSERT_AGENDAMENTO(
        P_ID_TUTOR       => 1,
        P_ID_PET         => 2,
        P_ID_CLINICA     => 1,
        P_ID_VETERINARIO => 1,
        P_DT_AGENDAMENTO => SYSTIMESTAMP + 3,
        P_DS_TIPO        => 'RETORNO',
        P_DS_ORIGEM      => 'TELEFONE'
    );
END;
/
 
BEGIN
    PRC_INSERT_AGENDAMENTO(
        P_ID_TUTOR       => 1,
        P_ID_PET         => 4,
        P_ID_CLINICA     => 1,
        P_ID_VETERINARIO => 1,
        P_DT_AGENDAMENTO => SYSTIMESTAMP + 7,
        P_DS_TIPO        => 'EXAME',
        P_DS_ORIGEM      => 'PORTAL'
    );
END;
/
 
BEGIN
    PRC_INSERT_AGENDAMENTO(
        P_ID_TUTOR       => 2,
        P_ID_PET         => 3,
        P_ID_CLINICA     => 2,
        P_ID_VETERINARIO => 2,
        P_DT_AGENDAMENTO => SYSTIMESTAMP + 10,
        P_DS_TIPO        => 'RETORNO',
        P_DS_ORIGEM      => 'BALCAO'
    );
END;
/
 
-- ============================================================================
-- MAIS LEITURAS DE TEMPERATURA
-- (garante: Leituras por Dispositivo com volume nos 2 dispositivos)
-- ============================================================================
 
BEGIN PRC_INSERT_LEITURA_TEMP(P_ID_DISPOSITIVO => 1, P_NR_TEMPERATURA => 3.8, P_NR_UMIDADE => 61); END;
/
 
BEGIN PRC_INSERT_LEITURA_TEMP(P_ID_DISPOSITIVO => 1, P_NR_TEMPERATURA => 7.1, P_NR_UMIDADE => 59); END;
/
 
BEGIN PRC_INSERT_LEITURA_TEMP(P_ID_DISPOSITIVO => 1, P_NR_TEMPERATURA => 10.5, P_NR_UMIDADE => 65); END;
/
 
BEGIN PRC_INSERT_LEITURA_TEMP(P_ID_DISPOSITIVO => 2, P_NR_TEMPERATURA => 5.0, P_NR_UMIDADE => 57); END;
/
 
BEGIN PRC_INSERT_LEITURA_TEMP(P_ID_DISPOSITIVO => 2, P_NR_TEMPERATURA => 6.3, P_NR_UMIDADE => 60); END;
/
 
-- ============================================================================
-- MAIS NOTIFICACOES
-- (dados extras para cursores e relatórios)
-- ============================================================================
 
BEGIN
    PRC_INSERT_NOTIFICACAO(
        P_ID_TUTOR    => 2,
        P_ID_PET      => 3,
        P_DS_CANAL    => 'EMAIL',
        P_DS_TIPO     => 'RETORNO',
        P_DS_TITULO   => 'Retorno agendado',
        P_DS_MENSAGEM => 'Sua consulta de retorno da Mimi está confirmada.',
        P_DT_AGENDADA => SYSTIMESTAMP + 1
    );
END;
/
 
BEGIN
    PRC_INSERT_NOTIFICACAO(
        P_ID_TUTOR    => 1,
        P_ID_PET      => 1,
        P_DS_CANAL    => 'WHATSAPP',
        P_DS_TIPO     => 'PRESCRICAO_NOVA',
        P_DS_TITULO   => 'Nova prescrição disponível',
        P_DS_MENSAGEM => 'A prescrição do Thor foi emitida e está disponível no portal.',
        P_DT_AGENDADA => SYSTIMESTAMP
    );
END;
/
 
-- ============================================================================
-- MAIS CONSENTIMENTOS
-- (variedade de tipos para o cursor de consentimentos)
-- ============================================================================
 
BEGIN
    PRC_INSERT_CONSENTIMENTO(
        P_ID_TUTOR        => 1,
        P_DS_TIPO         => 'DADOS_ANONIMOS',
        P_DS_VERSAO_TERMO => 'v1.0',
        P_ST_ACEITO       => 'S',
        P_DS_IP_ACEITE    => '192.168.1.10'
    );
END;
/
 
BEGIN
    PRC_INSERT_CONSENTIMENTO(
        P_ID_TUTOR        => 2,
        P_DS_TIPO         => 'MARKETING',
        P_DS_VERSAO_TERMO => 'v1.0',
        P_ST_ACEITO       => 'N',
        P_DS_IP_ACEITE    => '192.168.1.11'
    );
END;
/
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 1, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 2); END;
/
-- evento 4: Thor - vacina
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 1, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 3); END;
/
-- evento 5: Thor - exame
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 2, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 1); END;
/
-- evento 6: Mel - consulta
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 4, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 1); END;
/
-- evento 7: Bob - consulta
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 4, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 3); END;
/
-- evento 8: Bob - exame
 
BEGIN PRC_INSERT_EVENTO(P_ID_PET => 5, P_ID_VETERINARIO => 1, P_ID_TIPO_EVENTO => 1); END;
/
-- evento 9: Luke - consulta
 
-- ============================================================================
-- MAIS VACINAS
-- (garante: Vacinas por Pet no Relatório 2)
-- ============================================================================
 
BEGIN
    PRC_INSERT_VACINA(
        P_ID_EVENTO    => 4,
        P_NM_VACINA    => 'Antirrábica',
        P_NR_LOTE      => 'L456',
        P_DT_APLICACAO => SYSDATE
    );
END;
/
 
-- ============================================================================
-- MAIS EXAMES
-- (garante: Exames por Status com valores variados no Relatório 2)
-- ============================================================================
 
BEGIN PRC_INSERT_EXAME(P_ID_EVENTO => 5, P_NM_EXAME => 'Urinálise'); END;
/
 
BEGIN PRC_INSERT_EXAME(P_ID_EVENTO => 8, P_NM_EXAME => 'Raio-X Tórax'); END;
/
 
-- Atualiza status do exame 2 para ENTREGUE e exame 3 para CANCELADO
-- (para o relatorio de exames por status ter variedade)
UPDATE EXAME SET ST_STATUS = 'ENTREGUE'  WHERE ID_EXAME = 2;
UPDATE EXAME SET ST_STATUS = 'CANCELADO' WHERE ID_EXAME = 3;
COMMIT;
 
-- ============================================================================
-- MAIS TUTOR_PET
-- (garante: Pets por Tutor com quantidades diferentes)
-- Clayton fica com Thor, Mel, Bob e Luke (4 pets)
-- Marina fica com Mimi (1 pet)
-- ============================================================================
 
BEGIN PRC_INSERT_TUTOR_PET(P_ID_TUTOR => 1, P_ID_PET => 4); END;
/
 
BEGIN PRC_INSERT_TUTOR_PET(P_ID_TUTOR => 1, P_ID_PET => 5); END;
/
 
-- ============================================================================
-- MAIS AGENDAMENTOS
-- (garante: Agendamentos por Clínica com pelo menos 2 clínicas)
-- ============================================================================
 
BEGIN
    PRC_INSERT_AGENDAMENTO(
        P_ID_TUTOR       => 1,
        P_ID_PET         => 2,
        P_ID_CLINICA     => 1,
        P_ID_VETERINARIO => 1,
        P_DT_AGENDAMENTO => SYSTIMESTAMP + 3,
        P_DS_TIPO        => 'RETORNO',
        P_DS_ORIGEM      => 'TELEFONE'
    );
END;
/
 
BEGIN
    PRC_INSERT_AGENDAMENTO(
        P_ID_TUTOR       => 1,
        P_ID_PET         => 4,
        P_ID_CLINICA     => 1,
        P_ID_VETERINARIO => 1,
        P_DT_AGENDAMENTO => SYSTIMESTAMP + 7,
        P_DS_TIPO        => 'EXAME',
        P_DS_ORIGEM      => 'PORTAL'
    );
END;
/
 
BEGIN
    PRC_INSERT_AGENDAMENTO(
        P_ID_TUTOR       => 2,
        P_ID_PET         => 3,
        P_ID_CLINICA     => 2,
        P_ID_VETERINARIO => 2,
        P_DT_AGENDAMENTO => SYSTIMESTAMP + 10,
        P_DS_TIPO        => 'RETORNO',
        P_DS_ORIGEM      => 'BALCAO'
    );
END;
/
 
-- ============================================================================
-- MAIS LEITURAS DE TEMPERATURA
-- (garante: Leituras por Dispositivo com volume nos 2 dispositivos)
-- ============================================================================
 
BEGIN PRC_INSERT_LEITURA_TEMP(P_ID_DISPOSITIVO => 1, P_NR_TEMPERATURA => 3.8, P_NR_UMIDADE => 61); END;
/
 
BEGIN PRC_INSERT_LEITURA_TEMP(P_ID_DISPOSITIVO => 1, P_NR_TEMPERATURA => 7.1, P_NR_UMIDADE => 59); END;
/
 
BEGIN PRC_INSERT_LEITURA_TEMP(P_ID_DISPOSITIVO => 1, P_NR_TEMPERATURA => 10.5, P_NR_UMIDADE => 65); END;
/
 
BEGIN PRC_INSERT_LEITURA_TEMP(P_ID_DISPOSITIVO => 2, P_NR_TEMPERATURA => 5.0, P_NR_UMIDADE => 57); END;
/
 
BEGIN PRC_INSERT_LEITURA_TEMP(P_ID_DISPOSITIVO => 2, P_NR_TEMPERATURA => 6.3, P_NR_UMIDADE => 60); END;
/
 
-- ============================================================================
-- MAIS NOTIFICACOES
-- (dados extras para cursores e relatórios)
-- ============================================================================
 
BEGIN
    PRC_INSERT_NOTIFICACAO(
        P_ID_TUTOR    => 2,
        P_ID_PET      => 3,
        P_DS_CANAL    => 'EMAIL',
        P_DS_TIPO     => 'RETORNO',
        P_DS_TITULO   => 'Retorno agendado',
        P_DS_MENSAGEM => 'Sua consulta de retorno da Mimi está confirmada.',
        P_DT_AGENDADA => SYSTIMESTAMP + 1
    );
END;
/
 
BEGIN
    PRC_INSERT_NOTIFICACAO(
        P_ID_TUTOR    => 1,
        P_ID_PET      => 1,
        P_DS_CANAL    => 'WHATSAPP',
        P_DS_TIPO     => 'PRESCRICAO_NOVA',
        P_DS_TITULO   => 'Nova prescrição disponível',
        P_DS_MENSAGEM => 'A prescrição do Thor foi emitida e está disponível no portal.',
        P_DT_AGENDADA => SYSTIMESTAMP
    );
END;
/
 
-- ============================================================================
-- MAIS CONSENTIMENTOS
-- (variedade de tipos para o cursor de consentimentos)
-- ============================================================================
 
BEGIN
    PRC_INSERT_CONSENTIMENTO(
        P_ID_TUTOR        => 1,
        P_DS_TIPO         => 'DADOS_ANONIMOS',
        P_DS_VERSAO_TERMO => 'v1.0',
        P_ST_ACEITO       => 'S',
        P_DS_IP_ACEITE    => '192.168.1.10'
    );
END;
/
 
BEGIN
    PRC_INSERT_CONSENTIMENTO(
        P_ID_TUTOR        => 2,
        P_DS_TIPO         => 'MARKETING',
        P_DS_VERSAO_TERMO => 'v1.0',
        P_ST_ACEITO       => 'N',
        P_DS_IP_ACEITE    => '192.168.1.11'
    );
END;
/
 
COMMIT;
 

--BLOCOS ANONIMOS COM JOINS

SET SERVEROUTPUT ON;

DECLARE
BEGIN

    DBMS_OUTPUT.PUT_LINE('==== RELATORIO 1 ====');

    -- =========================================================
    -- CONSULTA 1
    -- =========================================================

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'PETS POR TUTOR');

    FOR X IN (

        SELECT
            T.NM_TUTOR,
            COUNT(P.ID_PET) AS TOTAL_PETS
        FROM TUTOR T
        JOIN TUTOR_PET TP
            ON TP.ID_TUTOR = T.ID_TUTOR
        JOIN PET P
            ON P.ID_PET = TP.ID_PET
        GROUP BY T.NM_TUTOR
        ORDER BY TOTAL_PETS DESC

    ) LOOP

        DBMS_OUTPUT.PUT_LINE(
            X.NM_TUTOR || ' - ' || X.TOTAL_PETS
        );

    END LOOP;

    -- =========================================================
    -- CONSULTA 2
    -- =========================================================

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'EVENTOS POR PET');

    FOR X IN (

        SELECT
            P.NM_PET,
            COUNT(E.ID_EVENTO) AS TOTAL_EVENTOS
        FROM PET P
        JOIN EVENTO_CLINICO E
            ON E.ID_PET = P.ID_PET
        GROUP BY P.NM_PET
        ORDER BY TOTAL_EVENTOS DESC

    ) LOOP

        DBMS_OUTPUT.PUT_LINE(
            X.NM_PET || ' - ' || X.TOTAL_EVENTOS
        );

    END LOOP;

    -- =========================================================
    -- CONSULTA 3
    -- =========================================================

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'AGENDAMENTOS POR CLINICA');

    FOR X IN (

        SELECT
            C.NM_CLINICA,
            COUNT(A.ID_AGENDAMENTO) AS TOTAL_AGENDAMENTOS
        FROM CLINICA C
        JOIN AGENDAMENTO A
            ON A.ID_CLINICA = C.ID_CLINICA
        GROUP BY C.NM_CLINICA
        ORDER BY TOTAL_AGENDAMENTOS DESC

    ) LOOP

        DBMS_OUTPUT.PUT_LINE(
            X.NM_CLINICA || ' - ' || X.TOTAL_AGENDAMENTOS
        );

    END LOOP;

END;
/


SET SERVEROUTPUT ON;

DECLARE
BEGIN

    DBMS_OUTPUT.PUT_LINE('==== RELATORIO 2 ====');

    -- =========================================================
    -- CONSULTA 1
    -- =========================================================

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'VACINAS POR PET');

    FOR X IN (

        SELECT
            P.NM_PET,
            COUNT(V.ID_VACINA) AS TOTAL_VACINAS
        FROM PET P
        JOIN EVENTO_CLINICO E
            ON E.ID_PET = P.ID_PET
        JOIN VACINA V
            ON V.ID_EVENTO = E.ID_EVENTO
        GROUP BY P.NM_PET
        ORDER BY TOTAL_VACINAS DESC

    ) LOOP

        DBMS_OUTPUT.PUT_LINE(
            X.NM_PET || ' - ' || X.TOTAL_VACINAS
        );

    END LOOP;

    -- =========================================================
    -- CONSULTA 2
    -- =========================================================

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'EXAMES POR STATUS');

    FOR X IN (

        SELECT
            ST_STATUS,
            COUNT(ID_EXAME) AS TOTAL
        FROM EXAME
        GROUP BY ST_STATUS
        ORDER BY TOTAL DESC

    ) LOOP

        DBMS_OUTPUT.PUT_LINE(
            X.ST_STATUS || ' - ' || X.TOTAL
        );

    END LOOP;

    -- =========================================================
    -- CONSULTA 3
    -- =========================================================

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'LEITURAS POR DISPOSITIVO');

    FOR X IN (

        SELECT
            D.NM_DISPOSITIVO,
            COUNT(L.ID_LEITURA) AS TOTAL_LEITURAS
        FROM DISPOSITIVO_IOT D
        JOIN LEITURA_TEMPERATURA L
            ON L.ID_DISPOSITIVO = D.ID_DISPOSITIVO
        GROUP BY D.NM_DISPOSITIVO
        ORDER BY TOTAL_LEITURAS DESC

    ) LOOP

        DBMS_OUTPUT.PUT_LINE(
            X.NM_DISPOSITIVO || ' - ' || X.TOTAL_LEITURAS
        );

    END LOOP;

END;
/

-- BLOCO PARA LEITURA DOS DADOS DA TABELA PET

SET SERVEROUTPUT ON;

DECLARE
BEGIN

    DBMS_OUTPUT.PUT_LINE('==== RELATORIO PETS ====');

    FOR X IN (

        SELECT

            NM_PET AS PET_ATUAL,

            NVL(
                LAG(NM_PET) OVER (ORDER BY ID_PET),
                'Vazio'
            ) AS PET_ANTERIOR,

            NVL(
                LEAD(NM_PET) OVER (ORDER BY ID_PET),
                'Vazio'
            ) AS PROXIMO_PET

        FROM PET

        ORDER BY ID_PET

    ) LOOP

        DBMS_OUTPUT.PUT_LINE(
            'PET ANTERIOR: ' || X.PET_ANTERIOR
        );

        DBMS_OUTPUT.PUT_LINE(
            'PET ATUAL: ' || X.PET_ATUAL
        );

        DBMS_OUTPUT.PUT_LINE(
            'PROXIMO PET: ' || X.PROXIMO_PET
        );

        DBMS_OUTPUT.PUT_LINE('-------------------');

    END LOOP;

END;
/


-- RELATORIOS COM CURSOR EXPLICITO

SET SERVEROUTPUT ON;

DECLARE

    CURSOR C_EVENTOS_PET IS
        SELECT
            P.NM_PET,
            TE.NM_TIPO_EVENTO,
            COUNT(E.ID_EVENTO) AS TOTAL_EVENTOS
        FROM PET P
        JOIN EVENTO_CLINICO E ON E.ID_PET = P.ID_PET
        JOIN TIPO_EVENTO TE   ON TE.ID_TIPO_EVENTO = E.ID_TIPO_EVENTO
        WHERE P.ST_ATIVO = 'S'
        GROUP BY P.NM_PET, TE.NM_TIPO_EVENTO
        ORDER BY P.NM_PET, TE.NM_TIPO_EVENTO;

    V_PET_ATUAL      PET.NM_PET%TYPE;
    V_PET_ANTERIOR   PET.NM_PET%TYPE := NULL;
    V_TIPO           TIPO_EVENTO.NM_TIPO_EVENTO%TYPE;
    V_TOTAL_EVENTOS  NUMBER;
    V_SUBTOTAL       NUMBER := 0;
    V_TOTAL_GERAL    NUMBER := 0;

BEGIN

    DBMS_OUTPUT.PUT_LINE('==== RELATORIO EVENTOS POR PET ====');
    DBMS_OUTPUT.PUT_LINE('PET             | TIPO EVENTO  | QTD');
    DBMS_OUTPUT.PUT_LINE('=====================================');

    OPEN C_EVENTOS_PET;

    LOOP

        FETCH C_EVENTOS_PET INTO V_PET_ATUAL, V_TIPO, V_TOTAL_EVENTOS;

        -- Quebra de grupo: imprime subtotal do pet anterior
        IF V_PET_ANTERIOR IS NOT NULL AND
           (C_EVENTOS_PET%NOTFOUND OR V_PET_ATUAL <> V_PET_ANTERIOR) THEN

            DBMS_OUTPUT.PUT_LINE(
                'Sub-Total ' || V_PET_ANTERIOR || ': ' || V_SUBTOTAL || ' evento(s)'
            );
            DBMS_OUTPUT.PUT_LINE('-------------------------------------');
            V_SUBTOTAL := 0;

        END IF;

        EXIT WHEN C_EVENTOS_PET%NOTFOUND;

        -- Tomada de decisão: classifica o tipo de evento
        IF V_TIPO = 'CONSULTA' THEN
            DBMS_OUTPUT.PUT_LINE(
            'Pet: ' || V_PET_ATUAL || 
            ' | Evento: ' || V_TIPO || 
            ' | Quantidade: ' || V_TOTAL_EVENTOS || 
            ' [ATENDIMENTO CLINICO]'
            );
        ELSIF V_TIPO = 'VACINA' THEN
            DBMS_OUTPUT.PUT_LINE(
                V_PET_ATUAL || ' | ' || V_TIPO || ' | ' || V_TOTAL_EVENTOS || ' [PREVENCAO]'
            );
        ELSIF V_TIPO = 'EXAME' THEN
            DBMS_OUTPUT.PUT_LINE(
                V_PET_ATUAL || ' | ' || V_TIPO || ' | ' || V_TOTAL_EVENTOS || ' [DIAGNOSTICO]'
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE(
                V_PET_ATUAL || ' | ' || V_TIPO || ' | ' || V_TOTAL_EVENTOS || ' [OUTRO]'
            );
        END IF;

        V_SUBTOTAL      := V_SUBTOTAL + V_TOTAL_EVENTOS;
        V_TOTAL_GERAL   := V_TOTAL_GERAL + V_TOTAL_EVENTOS;
        V_PET_ANTERIOR  := V_PET_ATUAL;

    END LOOP;

    CLOSE C_EVENTOS_PET;

    DBMS_OUTPUT.PUT_LINE('=====================================');
    DBMS_OUTPUT.PUT_LINE('Total Geral: ' || V_TOTAL_GERAL || ' evento(s)');

END;
/

SET SERVEROUTPUT ON;

DECLARE

    CURSOR C_PETS IS
        SELECT
            NM_PET,
            NR_PESO_KG
        FROM PET;

    V_NOME PET.NM_PET%TYPE;
    V_PESO PET.NR_PESO_KG%TYPE;

    V_TOTAL NUMBER := 0;
    V_SOMA  NUMBER := 0;

BEGIN

    OPEN C_PETS;

    LOOP

        FETCH C_PETS INTO V_NOME, V_PESO;

        EXIT WHEN C_PETS%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            'PET: ' || V_NOME ||
            ' | PESO: ' || V_PESO
        );

        V_TOTAL := V_TOTAL + 1;
        V_SOMA := V_SOMA + V_PESO;

        IF V_PESO >= 20 THEN
            DBMS_OUTPUT.PUT_LINE('PORTE GRANDE');
        ELSE
            DBMS_OUTPUT.PUT_LINE('PORTE PEQUENO');
        END IF;

        DBMS_OUTPUT.PUT_LINE('----------------');

    END LOOP;

    CLOSE C_PETS;

    DBMS_OUTPUT.PUT_LINE('TOTAL PETS: ' || V_TOTAL);
    DBMS_OUTPUT.PUT_LINE('SOMA PESOS: ' || V_SOMA);

END;
/



SET SERVEROUTPUT ON;

DECLARE

    CURSOR C_AGEND IS
        SELECT
            DS_TIPO,
            ST_STATUS
        FROM AGENDAMENTO;

    V_TIPO   AGENDAMENTO.DS_TIPO%TYPE;
    V_STATUS AGENDAMENTO.ST_STATUS%TYPE;

BEGIN

    OPEN C_AGEND;

    LOOP

        FETCH C_AGEND INTO V_TIPO, V_STATUS;

        EXIT WHEN C_AGEND%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            'TIPO: ' || V_TIPO
        );

        IF V_STATUS = 'AGENDADO' THEN

            DBMS_OUTPUT.PUT_LINE(
                'STATUS NORMAL'
            );

        ELSE

            DBMS_OUTPUT.PUT_LINE(
                'STATUS DIFERENTE'
            );

        END IF;

        DBMS_OUTPUT.PUT_LINE('----------------');

    END LOOP;

    CLOSE C_AGEND;

END;
/


SET SERVEROUTPUT ON;

DECLARE

    CURSOR C_TEMP IS
        SELECT
            NR_TEMPERATURA
        FROM LEITURA_TEMPERATURA;

    V_TEMP NUMBER(5,2);

BEGIN

    OPEN C_TEMP;

    LOOP

        FETCH C_TEMP INTO V_TEMP;

        EXIT WHEN C_TEMP%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            'TEMPERATURA: ' || V_TEMP
        );

        IF V_TEMP > 8 THEN

            DBMS_OUTPUT.PUT_LINE(
                'ALERTA DE TEMPERATURA'
            );

        ELSE

            DBMS_OUTPUT.PUT_LINE(
                'TEMPERATURA NORMAL'
            );

        END IF;

        DBMS_OUTPUT.PUT_LINE('----------------');

    END LOOP;

    CLOSE C_TEMP;

END;
/


SET SERVEROUTPUT ON;

DECLARE

    CURSOR C_VET IS
        SELECT
            NM_VETERINARIO,
            ST_ATIVO
        FROM VETERINARIO;

    V_NOME   VARCHAR2(120);
    V_STATUS CHAR(1);

BEGIN

    OPEN C_VET;

    LOOP

        FETCH C_VET INTO V_NOME, V_STATUS;

        EXIT WHEN C_VET%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            'VETERINARIO: ' || V_NOME
        );

        IF V_STATUS = 'S' THEN

            DBMS_OUTPUT.PUT_LINE(
                'ATIVO'
            );

        ELSE

            DBMS_OUTPUT.PUT_LINE(
                'INATIVO'
            );

        END IF;

        DBMS_OUTPUT.PUT_LINE('----------------');

    END LOOP;

    CLOSE C_VET;

END;
/

SET SERVEROUTPUT ON;

DECLARE
    CURSOR C_TEMP IS
        SELECT NR_TEMPERATURA
        FROM LEITURA_TEMPERATURA;
BEGIN
    FOR REG IN C_TEMP LOOP
        IF REG.NR_TEMPERATURA > 8 THEN
            DBMS_OUTPUT.PUT_LINE(
                'TEMPERATURA ALTA: ' || REG.NR_TEMPERATURA
            );
        ELSIF REG.NR_TEMPERATURA < 2 THEN
            DBMS_OUTPUT.PUT_LINE(
                'TEMPERATURA BAIXA: ' || REG.NR_TEMPERATURA
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE(
                'TEMPERATURA NORMAL: ' || REG.NR_TEMPERATURA
            );
        END IF;
    END LOOP;
END;
/
-- ============================================================================
-- FIM DA DDL
-- ============================================================================
