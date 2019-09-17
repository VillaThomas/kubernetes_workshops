
CREATE TABLE customer(
   id serial PRIMARY KEY,
   username VARCHAR (50) UNIQUE NOT NULL,
   name VARCHAR (355) UNIQUE NOT NULL
);
INSERT INTO customer(id, username, name) VALUES (1, 'john', 'DOE');
