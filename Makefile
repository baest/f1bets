
devel:
		morbo f1bets.pl --watch f1bets.pl

run:
		./f1bets.pl daemon --reload
#		hypnotoad f1bets.pl

edit:
	mvim f1bets.pl templates/layouts/* db/f1*.sql static/*/*.[cj]s* -c ':vsplit' -c ':wincmd w'

db: .PHONY
	psql f1bets < db/f.sql
