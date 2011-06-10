
run:
		./f1bets.pl daemon --reload

edit:
	mvim f1bets.pl templates/layouts/* db/f1*.sql static/*/*.[cj]s* -c ':vsplit' -c ':wincmd w'

db: .PHONY
	psql f1bets < db/f.sql
