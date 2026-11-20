-- CDC por timestamp (PostgreSQL)
-- Ideia → buscar só o que mudou desde a última carga

-- 1. Tabela de controle guarda a última carga de cada tabela
CREATE TABLE IF NOT EXISTS controle_carga (
    tabela        VARCHAR(100) PRIMARY KEY,
    ultima_carga  TIMESTAMP NOT NULL
);

-- 2. Busca só as linhas alteradas depois da última carga
SELECT *
FROM origem.pedidos
WHERE updated_at > (SELECT ultima_carga FROM controle_carga WHERE tabela = 'pedidos');

-- 3. Grava no destino com upsert (insere ou atualiza)
INSERT INTO destino.pedidos (id, status, valor, updated_at)
SELECT id, status, valor, updated_at
FROM origem.pedidos
WHERE updated_at > (SELECT ultima_carga FROM controle_carga WHERE tabela = 'pedidos')
ON CONFLICT (id) DO UPDATE
SET status = EXCLUDED.status,
    valor = EXCLUDED.valor,
    updated_at = EXCLUDED.updated_at;

-- 4. Atualiza o controle para a próxima execução
UPDATE controle_carga
SET ultima_carga = (SELECT MAX(updated_at) FROM destino.pedidos)
WHERE tabela = 'pedidos';

-- Limite desta técnica → linhas apagadas na origem não aparecem aqui
