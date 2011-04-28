#!/usr/bin/perl
use strict;
use Mojolicious::Lite;
use File::Basename;
use File::Slurp 'slurp';
use DBI;
use utf8;
use Data::Dump;

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

	my $func = \&{'create_' . $self->param('service')};

#$self->render_json({ $self->param('service') => $func->($self) });
	$self->render_json($func->($self));
	return;
} => 'json';

sub get_user {
	my $data = $dbh->selectall_arrayref(q!SELECT * FROM b_user WHERE name <> 'house' ORDER BY name!, { Slice => {} });
}
sub get_bet {
	my $data = $dbh->selectall_arrayref(q!SELECT * FROM v_bet!, { Slice => {} });
}

sub create_bet {
	my ($self) = @_;

	my %p;
	my @list = @{$self->req->body_params->params};
	for(my $i = 0; $i < @list; $i += 2) {
		if (exists $p{$list[$i]}) {
			$p{$list[$i]} = [$p{$list[$i]}, $list[$i+1]];
		}
		else {
			$p{$list[$i]} = $list[$i+1];
		}
	}

	foreach(qw/start end/) {
		my $lookup = "bet_${_}_time";
		if ($p{$lookup}) {
			$p{"bet_$_"} .= ' ' . $p{$lookup};
		}
	}

	return unless ($p{bookie} && $p{description});
	my @fields = qw/bookie takers description bet_start bet_end/;
	my $fields = join(', ', @fields);
	my $params = join(", ", ("?") x @fields);
	my ($guid) = $dbh->selectrow_array(qq!INSERT INTO bet ($fields) VALUES($params) RETURNING id!, {}, @p{@fields});
	return { guid => $guid, success => Mojo::JSON->true };
}

app->start;

__DATA__

@@ index.html.ep
% layout 'index';
