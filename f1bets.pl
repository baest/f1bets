#!/usr/bin/perl
use Mojolicious::Lite;
use File::Basename;

app->static->root(File::Basename::dirname(app->static->root) . '/static');
app->secret('somewhatmoresecret password');

get '/' => sub { 
	my ($self) = @_;
	$self->stash(extjs_server => 'http://noedweb/'); 
} => 'index';

get '/json' => sub {
	my $self = shift;

	my $params = $self->req->params->to_hash;
	my $verb_form = verb_form($params->{verb}, $params->{form_id});
	my $data;

	if ($params->{guess} eq $verb_form) {
		$data = { msg => 'Korrekt!' };
	}
	elsif ($params->{guess} eq remove_accent($verb_form)) {
		$data = { msg => "Korrekt! ($verb_form)" };
	}
	else {
		$data = { msg => "Forkert, det rigtige svar er $verb_form!" };
	}
	$self->render(json => $data );
	return;
} => 'json';

app->start;

__DATA__

@@ index.html.ep
% layout 'index';
