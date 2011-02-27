
run:
		./f1bets.pl daemon --reload

edit:
	mvim f1bets.pl templates/layouts/* db/f.sql static/** -c ':vsplit' -c ':wincmd w'
