CREATE TABLE IF NOT EXISTS notificacao_lida (
    id_cliente INT NOT NULL,
    id_adocao INT NOT NULL,
    status VARCHAR(32) NOT NULL,
    PRIMARY KEY (id_cliente, id_adocao, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
