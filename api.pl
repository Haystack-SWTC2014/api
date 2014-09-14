#!/usr/bin/env perl
use strict;
use warnings;

use Mojolicious::Lite;

post '/domain' => sub {
    my $c = shift;
    my $query = $c->param('query');
    my $output = `guess-domain $query`;
    my $options = [split ',', $output];
    $c->render(json => {
        type => 'domain',
        options => $options
    });

};

post '/searches' => sub {
    my $c = shift;
    my $query = $c->param('query');
    my $domain = $c->param('domain');
    my $output = `python improve-query.py $domain | $query`;
    my $options = [split ',', $output];
    $c->render(json => {
        type => 'search',
        options => $options
    });
};

app->start;
