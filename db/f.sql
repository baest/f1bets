DROP TABLE IF EXISTS b_user CASCADE;
CREATE TABLE b_user (
  id BIGSERIAL NOT NULL PRIMARY KEY
, name TEXT NOT NULL
, fullname TEXT NOT NULL
, password TEXT
, email TEXT
);
CREATE UNIQUE INDEX b_user_name ON b_user (name);

DROP TABLE IF EXISTS bet CASCADE;
CREATE TABLE bet (
  id BIGSERIAL NOT NULL PRIMARY KEY
, bookie BIGINT NOT NULL REFERENCES b_user
, takers BIGINT[]
, description TEXT NOT NULL
, bet_start TIMESTAMP NOT NULL
, bet_end TIMESTAMP NOT NULL
, bookie_won BOOLEAN
, season INTEGER NOT NULL DEFAULT 2011
, paid BOOLEAN DEFAULT false
);
CREATE INDEX bet_season ON bet (season);

DROP TABLE IF EXISTS subcription_payment CASCADE;
CREATE TABLE subcription_payment (
  id BIGSERIAL NOT NULL PRIMARY KEY
, member BIGINT NOT NULL
);

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

COPY b_user ("name", fullname) FROM STDIN WITH DELIMITER '|';
baest|baest
michael|Michael Halberg
klein|Søren Klein
kenneth|Kenneth Halberg
huset|House always wins
\.


