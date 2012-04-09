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
use Mojo::JSON;

plugin 'basic_auth';
my $paths = app->static->paths;
app->static->paths([File::Basename::dirname($paths->[0]) . '/static']);
app->secret('somewhatmoresecret password');
my $json = Mojo::JSON->new;

app->attr(dbh => sub {
		my $self = shift;

		my $dbh = DBI->connect("dbi:Pg:dbname=f1bets", 'pgsql', '');

		$dbh->{pg_enable_utf8} = 1;

		return $dbh;
});

sub auth {
	my ($self) = @_;
	my $id = $self->session('user_id');

	return $id if $id;

	$id = $self->basic_auth( realm => sub { $self->check_user(@_); } );

	if ($id) {
		$self->session(user_id => $id);
	}

	return $id;
}

sub check_user {
	my ($self, $username, $password) = @_;
	my ($id) = $self->app->dbh->selectrow_array('SELECT id FROM b_user WHERE name = ? AND password = ?', {}, $username, sha256_hex($password));
	return $id;
}

get '/' => sub {
	my ($self) = @_;
	return unless auth($self);
} => 'index';

get '/service/:service' => sub {
	my $self = shift;
	return unless auth($self);

	my $func = \&{'get_' . $self->param('service')};

	return $self->render_json({ $self->param('service') => $func->($self) });
} => 'json';

post '/service/:service' => sub {
	my $self = shift;
	return unless auth($self);

	my $func = \&{'create_' . $self->param('service')};

#$self->render_json({ $self->param('service') => $func->($self) });
	return $self->render_json($func->($self));
} => 'json';

post '/call/:service' => sub {
	my $self = shift;
	return unless auth($self);

	my $data = $json->decode($self->req->build_body);

	if (my $sub = __PACKAGE__->can($self->param('service'))) {
		return $self->render_json($sub->($self, $data));
	}
	return $self->render_json({ error => 'Unknown call: ' . $self->param('service') });
} => 'json';

sub get_user {
	my $self = shift;
	my $data = $self->app->dbh->selectall_arrayref(q!SELECT id, name, (? = id) as me FROM b_user WHERE name <> 'house' ORDER BY name!, { Slice => {} }, $self->session('user_id'));
}
sub get_bet {
	my $self = shift;
	my $data = $self->app->dbh->selectall_arrayref(q!SELECT * FROM v_bet!, { Slice => {} });
}
sub get_cal {
	my $self = shift;
	my $data = $self->app->dbh->selectall_arrayref(q!SELECT name, to_datetext(start) as f1_start FROM f1_cal ORDER BY start!, { Slice => {} });
}
sub get_bet_status{
	my $self = shift;
	my $data = $self->app->dbh->selectall_arrayref(q!SELECT * FROM v_finished_bet_status ORDER BY user!, { Slice => {} });
}
sub get_bet_by_user {
	my $self = shift;
	my $data = $self->app->dbh->selectall_arrayref(q!SELECT (id || '_' || user_name) as bet_user, *, (twenties > 0) as user_lost FROM v_bet_by_user ORDER BY user_name, bet_start!, { Slice => {} });
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
	my ($id) = $self->app->dbh->selectrow_array(qq!INSERT INTO bet ($fields) VALUES($params) RETURNING id!, {}, @p{@fields});

	insert_log($self, sprintf('New bet with id %d', $id), 'new_bet');

	return { id => $id, success => Mojo::JSON->true };
}

sub upd_bet {
	my ($self, $data) = @_;

	if (exists $data->{id}) {
		my @possible_fields = qw/description is_finished/;
		my @fields = ();
		my @values = ();
		my @x = ();

		foreach my $field (@possible_fields) {
			if (exists $data->{$field}) {
				push @fields, $field;
				push @values, bet_parse_value($field, $data->{$field}, $data);
			}

			push @x, $data->{$field};
		}

		ddx(\@x);

		push @values, $data->{id};
		my $sql = 'UPDATE bet SET ' . join(', ', map { "$_ = ?" } @fields) . ' WHERE id = ? RETURNING id';

		my ($id) = $self->app->dbh->selectrow_array($sql, {}, @values);

		return { id => $id, success => Mojo::JSON->true };
	}

	return { error => 'Incorrect data received' };
}

sub bet_parse_value {
	my ($field, $value, $data) = @_;

	given ($field) {
		when (/is_finished/) {
		}
		default {
			return $value;
		}
	}
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

	$self->app->dbh->do('INSERT INTO f1_log(msg, log_type, who) VALUES(?, ?, ?) RETURNING id', {}, $msg, $log_type, $self->session('user_id'));

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
