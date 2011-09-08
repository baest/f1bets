-- TODO recreate all views!!
DROP VIEW IF EXISTS v_bet CASCADE;
CREATE OR REPLACE VIEW v_bet AS
	SELECT *, to_datetext(bet_start) as bet_start_text 
		, to_datetext(bet_end) as bet_end_text 
		, (bookie_won IS NOT NULL) as is_finished
	FROM bet;

CREATE OR REPLACE VIEW v_finished_bet AS
	SELECT * FROM v_bet WHERE is_finished;

-- TODO mangler is_paid!
CREATE OR REPLACE VIEW v_bet_by_user AS
	SELECT *, CASE WHEN user_lost THEN takers ELSE 0 END as twenties FROM (
	SELECT 
		id, unnest(takers) as user, (CASE WHEN house_takes THEN 2 ELSE 1 END) as takers, description, bet_start, bookie_won, house_takes, is_finished, (is_finished AND (house_takes IS TRUE OR bookie_won IS TRUE)) as user_lost
	FROM v_bet 
UNION 
	SELECT 
	id, bookie as user, array_length(takers, 1) * (CASE WHEN house_takes THEN 2 ELSE 1 END) as takers, description, bet_start, bookie_won, house_takes, is_finished, (is_finished AND bookie_won IS FALSE) as user_lost
	FROM v_bet) as x;

---- bets bookie har tabt og hvor mange tyvere han skal betale
--CREATE OR REPLACE VIEW v_finished_bet_takers AS
--	SELECT bookie as user, sum(array_length(takers, 1)) as sum FROM v_finished_bet WHERE NOT bookie_won OR house_takes GROUP BY bookie;

---- bets bookie har vundet og hvor mange tyvere han skal betale
--CREATE OR REPLACE VIEW v_finished_bet_bookie AS
--	SELECT unnest(takers) as user, COUNT(*) as sum FROM v_finished_bet WHERE bookie_won OR house_takes GROUP BY 1;

--CREATE OR REPLACE VIEW v_finished_bet_all AS
--	SELECT * FROM v_finished_bet_takers
--	UNION SELECT * FROM v_finished_bet_bookie;

CREATE OR REPLACE VIEW v_finished_bet_status AS
	SELECT payee as user, SUM(twenties)::bigint as lost, SUM(paid)::bigint as paid FROM finished_bet GROUP BY payee;
