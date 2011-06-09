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
, season INTEGER NOT NULL DEFAULT EXTRACT('YEAR' FROM NOW())
);
CREATE INDEX bet_season ON bet (season);

CREATE OR REPLACE FUNCTION tf_save_bet() RETURNS trigger AS $$
BEGIN
	IF true OR random() < .03 THEN
		RAISE NOTICE 'house!!!';
		UPDATE bet SET house_won = true, bookie_won = NULL WHERE id = NEW.id;
		INSERT INTO finished_bet(bet_id, payee, twenties) SELECT NEW.id, payee, 1 FROM unnest(NEW.takers) as payee;
		INSERT INTO finished_bet(bet_id, payee, twenties) VALUES (NEW.id, NEW.bookie, 1); -- bookie should only pay to house in this case
	END IF;

	RETURN NEW;
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER trig_bet AFTER INSERT ON bet FOR EACH ROW EXECUTE PROCEDURE tf_save_bet();

CREATE OR REPLACE FUNCTION tf_update_bet() RETURNS trigger AS $$
BEGIN
	IF COALESCE(OLD.bookie_won, OLD.house_won) IS NOT NULL THEN
		RETURN NULL;
	END IF;

	IF NEW.bookie_won IS NOT NULL THEN
		IF NEW.bookie_won THEN
			INSERT INTO finished_bet(bet_id, payee, twenties) SELECT NEW.id, payee, 1 FROM unnest(NEW.takers) as payee;
		END IF;

		IF NOT NEW.bookie_won THEN
			INSERT INTO finished_bet(bet_id, payee, twenties) VALUES (NEW.id, NEW.bookie, array_length(NEW.takers, 1));
		END IF;
	END IF;

	RETURN NEW;
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER trig_bet_update BEFORE UPDATE ON bet FOR EACH ROW EXECUTE PROCEDURE tf_update_bet();

-- inserted when 
DROP TABLE IF EXISTS finished_bet CASCADE;
CREATE TABLE finished_bet (
  id BIGSERIAL NOT NULL PRIMARY KEY
, bet_id BIGINT NOT NULL REFERENCES bet(id)
, payee BIGINT NOT NULL REFERENCES b_user(id)
, twenties INT CHECK (twenties > 0) NOT NULL
, paid INT CHECK(paid BETWEEN 0 AND twenties) DEFAULT 0
);
CREATE INDEX finished_bet_payee ON finished_bet (payee);


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

DROP TYPE IF EXISTS log_type;
CREATE TYPE log_type AS ENUM ('pay', 'new_bet', 'update_bet');

DROP TABLE IF EXISTS f1_log CASCADE;
CREATE TABLE f1_log (
  id BIGSERIAL NOT NULL PRIMARY KEY
,	msg TEXT NOT NULL
, log_type log_type NOT NULL
,	"start" TIMESTAMPTZ NOT NULL DEFAULT NOW()
, who BIGSERIAL REFERENCES b_user(id)
);

COPY b_user ("name", fullname, password) FROM STDIN WITH DELIMITER '|';
baest|baest|LfM8OLFsAgpQ0UYu
michael|Michael Halberg|michael01
klein|Søren Klein|klein02
kenneth|Kenneth Halberg|kenneth03
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

\i db/f_view.sql
\i db/f1_cal.sql

