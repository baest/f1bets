#!/usr/bin/perl
use strict;
use Mojolicious::Lite;
use Mojolicious::Sessions;
use File::Basename;
use File::Slurp 'slurp';
use DBI;
use utf8;
use Data::Dump;
use Digest::SHA 'sha256_hex';

my $dbh = DBI->connect("dbi:Pg:dbname=f1bets", 'pgsql', '');

$dbh->{pg_enable_utf8} = 1;

plugin 'basic_auth';
app->static->root(File::Basename::dirname(app->static->root) . '/static');
app->secret('somewhatmoresecret password');

sub auth {
	my ($self) = @_;
	my $id = $self->session('user_id');

	return $id if $id;

	$id = $self->basic_auth( realm => \&check_user );

	if ($id) {
		$self->session(user_id => $id);
	}

	return $id;
}

sub check_user {
	my ($username, $password) = @_;
	my ($id) = $dbh->selectrow_array('SELECT id FROM b_user WHERE name = ? AND password = ?', {}, $username, sha256_hex($password));
	return $id;
}

get '/' => sub { 
	my ($self) = @_;
	return unless auth($self);
	
	$self->stash(extjs_server => 'http://noedweb/'); 
} => 'index';

get '/service/:service' => sub {
	my $self = shift;
	return unless auth($self);

	my $func = \&{'get_' . $self->param('service')};

	$self->render_json({ $self->param('service') => $func->($self) });
	return;
} => 'json';

post '/service/:service' => sub {
	my $self = shift;
	return unless auth($self);

	my $func = \&{'create_' . $self->param('service')};

#$self->render_json({ $self->param('service') => $func->($self) });
	$self->render_json($func->($self));
	return;
} => 'json';

sub get_user {
	my $self = shift;
	my $data = $dbh->selectall_arrayref(q!SELECT id, name, (? = id) as me FROM b_user WHERE name <> 'house' ORDER BY name!, { Slice => {} }, $self->session('user_id'));
}
sub get_bet {
	my $data = $dbh->selectall_arrayref(q!SELECT * FROM v_bet!, { Slice => {} });
}
sub get_cal {
	my $data = $dbh->selectall_arrayref(q!SELECT name, to_datetext(start) as f1_start FROM f1_cal ORDER BY start!, { Slice => {} });
}
sub get_bet_status{
	my $data = $dbh->selectall_arrayref(q!SELECT * FROM v_finished_bet_status ORDER BY user!, { Slice => {} });
}
sub get_bet_by_user {
	my $data = $dbh->selectall_arrayref(q!SELECT (bu.id || '_' || bu."user") as bet_user, bu.*, u.name as user_name FROM v_bet_by_user bu JOIN b_user u ON (u.id = bu."user") ORDER BY user, bet_start!, { Slice => {} });
}

sub create_bet {
	my ($self) = @_;

	my %p;
	my @list = @{$self->req->body_params->params};
	for(my $i = 0; $i < @list; $i += 2) {
		my ($key, $val) = @list[$i,$i+1];
		if (exists $p{$key}) {
			if (ref $p{$key}) {
				push @{$p{$key}}, $val;
			}
			else {
				$p{$key} = [$p{$key}, $val];
			}
		}
		else {
			$p{$key} = $val;
		}
	}

	foreach(qw/start end/) {
		my $key = "bet_$_";
		my $lookup = "bet_${_}_time";
		$p{$key} = convert_danish_date($p{$key}) if $p{$key};
		if ($p{$lookup}) {
			$p{$key} .= ' ' . $p{$lookup};
		}
	}

	$p{takers} = [ $p{takers} ] unless ref $p{takers};

	return unless ($p{bookie} && $p{description});
	my @fields = qw/bookie takers description bet_start bet_end/;
	my $fields = join(', ', @fields);
	my $params = join(", ", ("?") x @fields);
	my ($id) = $dbh->selectrow_array(qq!INSERT INTO bet ($fields) VALUES($params) RETURNING id!, {}, @p{@fields});

	insert_log($self, sprintf('New bet with id %d', $id), 'new_bet');

	return { id => $id, success => Mojo::JSON->true };
}

sub create_user_pays_bet {
	my ($self) = @_;

	my $params = $self->req->params->to_hash;

	return { } unless $params->{user} && $params->{how_many};

	my $msg = sprintf('User %d payed %d', $params->{user}, $params->{how_many});
	insert_log($self, $msg, 'pay');

	#TODO actually insert payment

	return { id => 0, success => Mojo::JSON->true };
}

sub insert_log {
	my ($self, $msg, $log_type) = @_;

	$dbh->do('INSERT INTO f1_log(msg, log_type, who) VALUES(?, ?, ?) RETURNING id', {}, $msg, $log_type, $self->session('user_id'));

	#TODO? get id?
}

sub convert_danish_date {
	my ($date) = @_;

	#date/month/year
	return "$3/$2/$1" if $date =~ m!(\d{2})/(\d{2})-(\d{4})!;

	return $date;
}

app->start;

__DATA__

@@ index.html.ep
% layout 'index';
