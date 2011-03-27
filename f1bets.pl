#!/usr/bin/perl
use strict;
use Mojolicious::Lite;
use File::Basename;
use File::Slurp 'slurp';
use DBI;
use utf8;

my $dbh = DBI->connect("dbi:Pg:dbname=f1bets", 'pgsql', '');

$dbh->{pg_enable_utf8} = 1;

app->static->root(File::Basename::dirname(app->static->root) . '/static');
app->secret('somewhatmoresecret password');

get '/' => sub { 
	my ($self) = @_;
	$self->stash(extjs_server => 'http://noedweb/'); 
} => 'index';

get '/service/:service' => sub {
	my $self = shift;

	my $func = \&{'get_' . $self->param('service')};

	$self->render_json({ $self->param('service') => &$func });
	return;
} => 'json';

post '/service/:service' => sub {
	my $self = shift;

	my $func = \&{$self->param('service')};

	ddx($self->req->body_params);

	$self->render_json({ $self->param('service') => &$func });
	return;
} => 'json';

sub get_user {
	my $data = $dbh->selectall_arrayref(q!SELECT * FROM b_user WHERE name <> 'huset' ORDER BY name!, { Slice => {} });
}
sub get_bet {
	my $data = $dbh->selectall_arrayref(q!SELECT * FROM v_bet!, { Slice => {} });
}

app->start;

__DATA__

@@ index.html.ep
% layout 'index';
