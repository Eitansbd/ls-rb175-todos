CREATE TABLE lists (
  id serial PRIMARY KEY,
  name text UNIQUE NOT NULL check(length(name) >= 1)
);

CREATE TABLE todos (
  id serial PRIMARY KEY,
  name text UNIQUE NOT NULL CHECK(length(name) >= 1),
  completed boolean NOT NULL DEFAULT FALSE,
  list_id integer NOT NULL REFERENCES lists(id)
);