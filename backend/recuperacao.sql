CREATE TABLE IF NOT EXISTS recuperacao_senha (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    token_hash CHAR(64) NOT NULL UNIQUE,
    criado DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira DATETIME NOT NULL,
    INDEX idx_recuperacao_cliente (id_cliente, criado),
    CONSTRAINT fk_recuperacao_cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id)
) ENGINE=InnoDB;
