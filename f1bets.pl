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

	$self->render(json => $data );
	return;
} => 'json';

app->start;

__DATA__

@@ index.html.ep
% layout 'index';
