CREATE OR REPLACE FUNCTION to_datetext(timestamptz) RETURNS TEXT AS $$
	SELECT to_char($1, 'DD/MM-YYYY HH24:MI');
$$ LANGUAGE SQL IMMUTABLE;

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
, bet_end TIMESTAMP NOT NULL DEFAULT '2011-11-28'
, bookie_won BOOLEAN
, house_won BOOLEAN
, season INTEGER NOT NULL DEFAULT 2011
, paid BOOLEAN DEFAULT false
);
CREATE INDEX bet_season ON bet (season);

DROP VIEW v_bet CASCADE;
CREATE OR REPLACE VIEW v_bet AS
	SELECT *, to_datetext(bet_start) as bet_start_text 
		, to_datetext(bet_end) as bet_end_text 
		, (COALESCE(bookie_won, house_won) IS NOT NULL) as is_finished
		, CASE WHEN (COALESCE(bookie_won, house_won) IS NOT NULL) THEN NULL ELSE paid END as is_paid
	FROM bet;

CREATE OR REPLACE VIEW v_finished_bet AS
	SELECT * FROM v_bet WHERE COALESCE(bookie_won, house_won) IS NOT NULL;

CREATE OR REPLACE VIEW v_bet_by_user AS
	SELECT *, CASE WHEN user_lost THEN takers ELSE 0 END as twenties FROM (
	SELECT 
		id, unnest(takers) as user, 1 as takers, description, bet_start, bookie_won, house_won, is_finished, is_paid, (is_finished AND (house_won IS TRUE OR bookie_won IS TRUE)) as user_lost
	FROM v_bet 
UNION 
	SELECT 
		id, bookie as user, array_length(takers, 1) as takers, description, bet_start, bookie_won, house_won, is_finished, is_paid, (is_finished AND (house_won IS TRUE OR bookie_won IS FALSE)) as user_lost
	FROM v_bet) as x;

DROP TABLE IF EXISTS subcription_payment CASCADE;
CREATE TABLE subcription_payment (
  id BIGSERIAL NOT NULL PRIMARY KEY
, member BIGINT NOT NULL
);

DROP TABLE IF EXISTS f1_cal CASCADE;
CREATE TABLE f1_cal (
  id BIGSERIAL NOT NULL PRIMARY KEY
,	name TEXT NOT NULL
,	"start" TIMESTAMPTZ NOT NULL
,	"end" TIMESTAMPTZ NOT NULL
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

CREATE OR REPLACE FUNCTION tf_save_bet() RETURNS trigger AS $$
BEGIN
	IF random() < .03 THEN
		RAISE NOTICE 'house!!!';
		NEW.takers := array_append(NEW.takers, f_get_user('house'));
		NEW.house_won := true;
		NEW.bookie_won := NULL;
	END IF;

	RETURN NEW;
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER trig_bet BEFORE INSERT ON bet FOR EACH ROW EXECUTE PROCEDURE tf_save_bet();

---- bets bookie har tabt og hvor mange tyvere han skal betale
CREATE OR REPLACE VIEW v_finished_bet_takers AS
	SELECT bookie as user, sum(array_length(takers, 1)) as sum FROM v_finished_bet WHERE NOT bookie_won OR house_won GROUP BY bookie;

---- bets bookie har vundet og hvor mange tyvere han skal betale
CREATE OR REPLACE VIEW v_finished_bet_bookie AS
	SELECT unnest(takers) as user, COUNT(*) as sum FROM v_finished_bet WHERE bookie_won OR house_won GROUP BY 1;

CREATE OR REPLACE VIEW v_finished_bet_all AS
	SELECT * FROM  v_finished_bet_takers
	UNION SELECT * FROM v_finished_bet_bookie;

CREATE OR REPLACE VIEW v_finished_bet_status AS
	SELECT "user", SUM(sum)::bigint as sum FROM v_finished_bet_all GROUP BY "user";

COPY b_user ("name", fullname, password) FROM STDIN WITH DELIMITER '|';
baest|baest|LfM8OLFsAgpQ0UYu
michael|Michael Halberg|michael01
klein|Søren Klein|klein02
kenneth|Kenneth Halberg|kenneth03
house|House always wins|omgverysecreeet
\.

CREATE OR REPLACE FUNCTION f_get_user(p_name TEXT) RETURNS BIGINT AS $$
	SELECT id FROM b_user WHERE name = $1 LIMIT 1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION f_get_user_a(p_name TEXT) RETURNS BIGINT[] AS $$
	SELECT ARRAY[id] FROM b_user WHERE name = $1 LIMIT 1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION f_get_users(p_name TEXT[]) RETURNS BIGINT[] AS $$
	SELECT ARRAY(SELECT id FROM b_user WHERE name =ANY ($1));
$$ LANGUAGE SQL;

INSERT INTO bet (bookie, takers, description, bet_start, bookie_won) VALUES(f_get_user('klein'), f_get_user_a('kenneth'), 'Maclaren kommer ikke på top 10, de 3 første løb', '2011-03-27 7:00', false);

INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('baest'), f_get_user_a('michael'), 'Schumi har flere point end rosberg efter sæsonen', '2011-03-27 7:00');

INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('baest'), f_get_users(ARRAY['michael', 'kenneth', 'klein']), 'Massa vinder over Alonso i point', '2011-03-27 7:00');

INSERT INTO bet (bookie, takers, description, bet_start, bookie_won) VALUES(f_get_user('baest'), f_get_users(ARRAY['michael', 'kenneth', 'klein']), 'Mindst en Red bull og en Maclaren udgår pga. tekniske skader', '2011-03-27 7:00', false);

INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('klein'), f_get_users(ARRAY['kenneth', 'baest']), 'Button ikke laver en overhaling inden for 10 omgange fra omgang 3.', '2011-03-27 7:00', '2011-03-27 12:00', false);

INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('michael'), f_get_users(ARRAY['baest', 'klein']), 'Kiesa får lavet en facial', '2011-03-27 7:00');

INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('klein'), f_get_users(ARRAY['baest']), 'f1bets bliver ikke færdigt i løbet af sæsonen', '2011-04-10 11:00');

INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('klein'), f_get_users(ARRAY['baest']), 'f1bets bliver ikke færdigt i løbet af sæsonen (repeat)', '2011-04-17 11:00');

INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('kenneth'), f_get_users(ARRAY['baest']), 'Maclaren vinder flere løb end ferrari', '2011-04-17 9:00');

INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('michael'), f_get_users(ARRAY['baest']), 'Alonso slutter før Massa i China', '2011-04-17 9:00', '2011-04-17 11:00', false);

INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('michael'), f_get_users(ARRAY['baest']), 'Rosberg slutter over Schumacher i Spanien', '2011-05-22 14:00', '2011-05-17 14:05', false);

INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('kenneth'), f_get_users(ARRAY['michael','klein']), 'Kenneth henter 16 romsnegle i næste reklamepause', '2011-05-22 14:00', '2011-05-17 14:05', false);

INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('klein'), f_get_users(ARRAY['kenneth']), 'Hamilton kører af med alle 4 dæk i sving 11-15', '2011-05-22 14:00', '2011-05-17 14:05', false);

INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('kenneth'), f_get_users(ARRAY['klein']), 'Hamilton gennemfører', '2011-05-22 14:00', '2011-05-17 14:05', true);


--Halberg siger team USA får ingen point, bæst tager op
--Halberg siger team USA får præcis 1 point, Klein, bæst tager op
--Huset har 1% chance for at tage et bet og vinder 100% af betsne
--Hvert bet har en sidste deltagelse og en udløbsdato. Alle bets har en udbyder og x takers. Enten betaler takers eller udbyder

\i db/f1_cal.sql
