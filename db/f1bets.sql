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
, house_takes BOOLEAN DEFAULT false
, season INTEGER NOT NULL DEFAULT EXTRACT('YEAR' FROM NOW())
);
CREATE INDEX bet_season ON bet (season);

CREATE OR REPLACE FUNCTION f_create_finished_bet(p_rec bet) RETURNS VOID AS $$
DECLARE
	l_house_multiplier INTEGER := 1;
BEGIN
	IF p_rec.bookie_won IS NOT NULL THEN

		IF p_rec.house_takes THEN
			l_house_multiplier := 2;
		END IF;

		IF p_rec.bookie_won THEN
			INSERT INTO finished_bet(bet_id, payee, twenties) SELECT p_rec.id, payee, 1 * l_house_multiplier FROM unnest(p_rec.takers) as payee;
		END IF;

		IF NOT p_rec.bookie_won THEN
			INSERT INTO finished_bet(bet_id, payee, twenties) VALUES (p_rec.id, p_rec.bookie, array_length(p_rec.takers, 1) * l_house_multiplier);
		END IF;
	END IF;
END
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION tf_save_bet() RETURNS trigger AS $$
BEGIN
	IF random() < .03 THEN
		RAISE NOTICE 'house!!!';
		UPDATE bet SET house_takes = true, bookie_won = NULL WHERE id = NEW.id;
	END IF;

	PERFORM f_create_finished_bet(NEW);

	RETURN NEW;
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER trig_bet AFTER INSERT ON bet FOR EACH ROW EXECUTE PROCEDURE tf_save_bet();

CREATE OR REPLACE FUNCTION tf_update_bet() RETURNS trigger AS $$
BEGIN
	IF OLD.bookie_won IS NOT NULL THEN
		RETURN NULL;
	END IF;

	PERFORM f_create_finished_bet(NEW);

	RETURN NEW;
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER trig_bet_update BEFORE UPDATE ON bet FOR EACH ROW EXECUTE PROCEDURE tf_update_bet();

-- inserted when 
DROP TABLE IF EXISTS finished_bet CASCADE;
CREATE TABLE finished_bet (
  id BIGSERIAL NOT NULL PRIMARY KEY
, bet_id BIGINT NOT NULL REFERENCES bet(id) ON DELETE CASCADE
, payee BIGINT NOT NULL REFERENCES b_user(id)
, twenties INT CHECK (twenties > 0) NOT NULL
, paid INT CHECK(paid BETWEEN 0 AND twenties) DEFAULT 0
);
CREATE INDEX finished_bet_payee ON finished_bet (payee);


DROP TABLE IF EXISTS subscription_payment CASCADE;
CREATE TABLE subscription_payment (
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

DROP TYPE IF EXISTS log_type CASCADE;
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
baest|baest|b7242783cf2762e3e30d63299a7afb924ec8887d73086063c425d99f07257639
michael|Michael Halberg|5ec9eca24f920d406768ece79616a66a0b0517496adf475d650ca36db9ac49d2
klein|Søren Klein|5ec9eca24f920d406768ece79616a66a0b0517496adf475d650ca36db9ac49d2
kenneth|Kenneth Halberg|5ec9eca24f920d406768ece79616a66a0b0517496adf475d650ca36db9ac49d2
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

--INSERT INTO bet (bookie, takers, description, bet_start, bookie_won) VALUES(f_get_user('klein'), f_get_user_a('kenneth'), 'Maclaren kommer ikke på top 10, de 3 første løb', '2011-03-27 7:00', false);
--
--INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('baest'), f_get_user_a('michael'), 'Schumi har flere point end rosberg efter sæsonen', '2011-03-27 7:00');
--
--INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('baest'), f_get_users(ARRAY['michael', 'kenneth', 'klein']), 'Massa vinder over Alonso i point', '2011-03-27 7:00');
--
--INSERT INTO bet (bookie, takers, description, bet_start, bookie_won) VALUES(f_get_user('baest'), f_get_users(ARRAY['michael', 'kenneth', 'klein']), 'Mindst en Red bull og en Maclaren udgår pga. tekniske skader', '2011-03-27 7:00', false);
--
--INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('klein'), f_get_users(ARRAY['kenneth', 'baest']), 'Button ikke laver en overhaling inden for 10 omgange fra omgang 3.', '2011-03-27 7:00', '2011-03-27 12:00', false);
--
--INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('michael'), f_get_users(ARRAY['baest', 'klein']), 'Kiesa får lavet en facial', '2011-03-27 7:00');
--
--INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('klein'), f_get_users(ARRAY['baest']), 'f1bets bliver ikke færdigt i løbet af sæsonen', '2011-04-10 11:00');
--
--INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('klein'), f_get_users(ARRAY['baest']), 'f1bets bliver ikke færdigt i løbet af sæsonen (repeat)', '2011-04-17 11:00');
--
--INSERT INTO bet (bookie, takers, description, bet_start) VALUES(f_get_user('kenneth'), f_get_users(ARRAY['baest']), 'Maclaren vinder flere løb end ferrari', '2011-04-17 9:00');
--
--INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('michael'), f_get_users(ARRAY['baest']), 'Alonso slutter før Massa i China', '2011-04-17 9:00', '2011-04-17 11:00', false);
--
--INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('michael'), f_get_users(ARRAY['baest']), 'Rosberg slutter over Schumacher i Spanien', '2011-05-22 14:00', '2011-05-17 14:05', false);
--
--INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('kenneth'), f_get_users(ARRAY['michael','klein']), 'Kenneth henter 16 romsnegle i næste reklamepause', '2011-05-22 14:00', '2011-05-17 14:05', false);
--
--INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('klein'), f_get_users(ARRAY['kenneth']), 'Hamilton kører af med alle 4 dæk i sving 11-15', '2011-05-22 14:00', '2011-05-17 14:05', false);
--
--INSERT INTO bet (bookie, takers, description, bet_start, bet_end, bookie_won) VALUES(f_get_user('kenneth'), f_get_users(ARRAY['klein']), 'Hamilton gennemfører', '2011-05-22 14:00', '2011-05-17 14:05', true);

COPY bet (id, bookie, takers, description, bet_start, bet_end, bookie_won, house_takes, season) FROM stdin;
2	1	{2}	Schumi har flere point end rosberg efter sæsonen	2011-03-27 07:00:00	2011-11-28 00:00:00	\N	f	2011
7	3	{1}	f1bets bliver ikke færdigt i løbet af sæsonen	2011-04-10 11:00:00	2011-11-28 00:00:00	\N	f	2011
8	3	{1}	f1bets bliver ikke færdigt i løbet af sæsonen (repeat)	2011-04-17 11:00:00	2011-11-28 00:00:00	\N	f	2011
9	4	{1}	Maclaren vinder flere løb end ferrari	2011-04-17 09:00:00	2011-11-28 00:00:00	\N	f	2011
1	3	{4}	Maclaren kommer ikke på top 10, de 3 første løb	2011-03-27 07:00:00	2011-11-28 00:00:00	f	f	2011
4	1	{2,3,4}	Mindst en Red bull og en Maclaren udgår pga. tekniske skader	2011-03-27 07:00:00	2011-11-28 00:00:00	f	f	2011
10	2	{1}	Alonso slutter før Massa i China	2011-04-17 09:00:00	2011-04-17 11:00:00	f	f	2011
11	2	{1}	Rosberg slutter over Schumacher i Spanien	2011-05-22 14:00:00	2011-05-17 14:05:00	f	f	2011
12	4	{2,3}	Kenneth henter 16 romsnegle i næste reklamepause	2011-05-22 14:00:00	2011-05-17 14:05:00	f	f	2011
13	3	{4}	Hamilton kører af med alle 4 dæk i sving 11-15	2011-05-22 14:00:00	2011-05-17 14:05:00	f	f	2011
14	4	{3}	Hamilton gennemfører	2011-05-22 14:00:00	2011-05-17 14:05:00	t	f	2011
15	4	{1}	Hamilton overhaler Massa inden slut af 32	2011-05-29 00:00:00	2011-05-29 00:00:00	f	f	2011
5	3	{1,4}	Button ikke laver en overhaling inden for 10 omgange fra omgang 3.	2011-03-27 07:00:00	2011-03-27 12:00:00	f	f	2011
6	2	{1,3}	Kiesa får lavet en facial	2011-03-27 07:00:00	2011-11-28 00:00:00	t	f	2011
3	1	{2,3,4}	Massa vinder over Alonso i point	2011-03-27 07:00:00	2011-11-28 00:00:00	\N	f	2011
\.


--Halberg siger team USA får ingen point, bæst tager op
--Halberg siger team USA får præcis 1 point, Klein, bæst tager op
--Huset har 1% chance for at tage et bet og vinder 100% af betsne
--Hvert bet har en sidste deltagelse og en udløbsdato. Alle bets har en udbyder og x takers. Enten betaler takers eller udbyder

\i db/f1_view.sql

