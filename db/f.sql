DROP TABLE IF EXISTS "user" CASCADE;
CREATE TABLE "user" (
  id BIGSERIAL NOT NULL PRIMARY KEY
, name TEXT NOT NULL
, fullname TEXT NOT NULL
, password TEXT
, email TEXT
);
CREATE UNIQUE INDEX user_name ON "user" (name);

DROP TABLE IF EXISTS bet CASCADE;
CREATE TABLE bet (
  id BIGSERIAL NOT NULL
, players BIGINT[]
, description TEXT NOT NULL
, winner BIGINT
, season INTEGER
);
CREATE INDEX bet_season ON bet (season);

--DROP VIEW IF EXISTS v_next_what_to_do CASCADE;
--CREATE OR REPLACE VIEW v_next_what_to_do AS 
--	SELECT *
--	FROM what_to_do
--	ORDER BY random()
--	LIMIT 1;
--
--DROP VIEW IF EXISTS v_players CASCADE;
--CREATE OR REPLACE VIEW v_players AS 
--	SELECT g.id as game_id, p.* 
--	FROM player p
--	JOIN game g ON (p.id =ANY (g.players))
--	;
--
--DROP FUNCTION IF EXISTS f_get_next_player(INT);
--CREATE OR REPLACE FUNCTION f_get_next_player(p_game_id INTEGER) RETURNS player AS $$
--	SELECT p.* 
--	FROM player p
--	JOIN game g USING (id)
--	WHERE g.id = $1
--	ORDER BY random() 
--	LIMIT 1;
--$$ LANGUAGE SQL;

COPY "user" ("name", fullname) FROM STDIN WITH DELIMITER '|';
baest|baest
Michael|Michael Halberg
klein|Søren Klein
kenneth|Kenneth Halberg
huset|House always wins
\.


