all:
	sudo starman --port 80 --error-log run/error_log --pid run/f1bets.pid -D f1bets.pl
#	sudo hypnotoad f1bets.pl

reload:
	sudo kill -HUP `cat run/f1bets.pid`

run:
		./f1bets.pl daemon --reload

edit:
	mvim f1bets.pl templates/layouts/* db/f1*.sql static/*/*.[cj]s* -c ':vsplit' -c ':wincmd w'

db: .PHONY
	psql f1bets < db/f.sql
