-- Usar o banco sakila e mostrar as tabelas
USE sakila;
SHOW TABLES;

-- Listar o total de filmes por categoria

SELECT c.name AS categoria, COUNT(f.film_id) AS total_filmes
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY total_filmes DESC;

-- Mostrar os top 10 filmes mais alugados

SELECT f.title, COUNT(r.rental_id) AS total_locacoes
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
GROUP BY f.title
ORDER BY total_locacoes DESC
LIMIT 10;

-- Listar clientes com pagamento total superiores a 100

SELECT CONCAT(c.first_name, ' ', c.last_name) AS nome_cliente, SUM(p.amount) AS total_pago
FROM payment p
JOIN customer c ON p.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING total_pago > 100;

-- Transação para cadastrar novo pagamento

ALTER TABLE customer ADD COLUMN notes TEXT;

START TRANSACTION;
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date) VALUES (1, 1, 1, 50.00, NOW());
UPDATE customer SET notes = 'Pagamento Realizado' WHERE customer_id = 1;
COMMIT;

-- Apagar um pagamento

START TRANSACTION;
SAVEPOINT inicio;
DELETE FROM payment WHERE payment_id = 1;
COMMIT;

-- Criar uma view clientes vip (que gastaram mais de 200)

CREATE VIEW clientes_vip AS
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS nome_completo, SUM(p.amount) AS total_gasto
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
HAVING total_gasto > 200;

-- Consultar clientes vip

SELECT * FROM clientes_vip;

-- Mostrar filmes com duração média maior que 120

SELECT rating, AVG(length) AS duracao_media
FROM film
GROUP BY rating
HAVING duracao_media > 120;

-- Mostrar número de aluguéis em 2024

SELECT MONTH(rental_date) AS mes, COUNT(rental_id) AS total_locacoes
FROM rental
WHERE YEAR(rental_date) = 2024
GROUP BY MONTH(rental_date)
ORDER BY mes;

-- Registrar pagamentos 

CREATE TABLE log_pagamentos (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    payment_id INT,
    customer_id INT,
    amount DECIMAL(5,2),
    data_pagamento DATETIME
);

DELIMITER //
CREATE TRIGGER after_payment_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    INSERT INTO log_pagamentos (payment_id, customer_id, amount, data_pagamento)
    VALUES (NEW.payment_id, NEW.customer_id, NEW.amount, NEW.payment_date);
END;
//
DELIMITER ;

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date) VALUES (2, 1, 1, 30.00, NOW());

-- Atualizar de endereços

CREATE TABLE log_enderecos (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    address_id INT,
    old_address TEXT,
    data_alteracao DATETIME
);

-- Cadastrar novo cliente com email ainda não cadastrado

DELIMITER //
CREATE TRIGGER after_address_update
AFTER UPDATE ON address
FOR EACH ROW
BEGIN
    INSERT INTO log_enderecos (address_id, old_address, data_alteracao)
    VALUES (OLD.address_id, OLD.address, NOW());
END;
//
DELIMITER ;

UPDATE address SET address = 'Rua do Exemplo, 999' WHERE address_id = 1;

DELIMITER //
CREATE PROCEDURE CadastrarCliente(
    IN nome VARCHAR(50),
    IN sobrenome VARCHAR(50),
    IN email VARCHAR(50),
    IN endereco_id INT
)
BEGIN
    IF EXISTS (SELECT 1 FROM customer WHERE email = email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente com este e-mail já existe';
    ELSE
        INSERT INTO customer (store_id, first_name, last_name, email, address_id, create_date)
        VALUES (1, nome, sobrenome, email, endereco_id, NOW());
    END IF;
END;
//
DELIMITER ;

CALL CadastrarCliente('Thiago', 'Pinheiro', 'thiago.pinheiro@pe.senac.br', 5);

