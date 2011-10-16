-- TODO recreate all views!!
DROP VIEW IF EXISTS v_bet CASCADE;
CREATE OR REPLACE VIEW v_bet AS
	SELECT *, to_datetext(bet_start) as bet_start_text 
		, to_datetext(bet_end) as bet_end_text 
		, (bookie_won IS NOT NULL) as is_finished
	FROM bet;

CREATE OR REPLACE VIEW v_bet_by_user AS 
	SELECT u.name as user_name, b.*, COALESCE(fb.twenties, 0) as twenties, COALESCE(fb.paid, 0) as paid FROM v_bet b JOIN b_user u ON (u.id = b.bookie OR u.id =ANY (b.takers)) LEFT JOIN finished_bet fb ON (u.id = fb.payee AND b.id = fb.bet_id);

CREATE OR REPLACE VIEW v_finished_bet_status AS
	SELECT payee as user, SUM(twenties)::bigint as lost, SUM(paid)::bigint as paid FROM finished_bet GROUP BY payee;
