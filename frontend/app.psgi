#!/usr/bin/perl
use strict;
use warnings;

use File::Slurp 'slurp';
use JSON;
use Data::Dump qw/pp ddx/;
use Plack::Builder;
use Plack::Request;
use Encode;
use utf8;
use File::Basename qw(dirname);

my $app = sub {
	my $env = shift;

	return [ 200, ['Content-Type' => 'text/plain'], [ 'xxx'] ];
};

