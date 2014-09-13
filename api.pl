#!/usr/bin/env perl
use strict;
use warnings;

use Mojolicious::Lite;

post '/synonyms' => sub {
    my $c = shift;
    my $query = $c->param('query');
    my $domain = $c->param('domain');
    my $output = `python improve-query.py $domain | $domain`;
    $c->render(json => $output);
};

app->start;
