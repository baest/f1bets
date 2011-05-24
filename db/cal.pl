
use 5.10.0;
use strict;
use warnings;
use Tie::iCal;
use Data::Dump;

my %f1_cal;

tie %f1_cal, 'Tie::iCal', 'f1-calendar_gp.ics' or die "Failed to tie file!\n";

say q!COPY f1_cal ("name", "start", "end") FROM STDIN WITH DELIMITER '|';!;

foreach(keys %f1_cal) {
	my $details = $f1_cal{$_}[1];

	say "$details->{SUMMARY}|$details->{DTSTAMP}|$details->{DTEND}[1]";
}
say q!\\.!;
