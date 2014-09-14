#!/usr/bin/env perl
use strict;
use warnings;
use 5.18.2;

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

my %mappings = (
    python => {
        add_for_all => [qw(module library pypi)],
        csv => {
            add => [qw(parse)]
        },
        report => {
            add => [qw(graph statistics), 'data mining'],
            replace => [qw(analysis)]
        },
        array => {
            replace => [qw(list)]
        },
        length => {
            add => [qw(collection list)],
            replace => [qw(len)]
        },
        inch => {
            add => [qw(unit convert)]
        }
    },

    snakes => {
        add_for_all => [qw(snake reptile)],
        length => {
            add => [qw(record)],
        },
        report => {
            replace => ['fact sheet', qw(statistics information)],
            add => [qw()]
        }
    },

    javascript => {

    }
);

sub calculate_perplexity {
    my $domain = shift;
    my $query = shift;
    open my $tmpfile, '>', 'search-terms';
    print $tmpfile $query;
    my $output = `ngram -lm $domain-3gram.lm -ppl search-terms`;
    $output =~ /ppl1= (\d+\.\d+)/;
    my $ppl = $1;
    return $ppl;
}

sub generate_possible_searches {
    my $domain = shift;
    my $query = shift;
    my @query_terms = split ' ', $query;
    return if not defined $mappings{$domain};

    my %possibilities;
    $possibilities{$query} = 1;
    my $domain_map = $mappings{$domain};
    for my $global_add (@{$domain_map->{add_for_all}}) {
        my $new_query = $query . ' ' . $global_add;
        $possibilities{$new_query} = calculate_perplexity($domain, $new_query);
    }

    for my $keyword (keys %{$domain_map}) {
        next if $keyword eq 'add_for_all';
        my $word = $domain_map->{$keyword};

        if (defined $word->{replace}) {
            for my $replace (@{$word->{replace}}) {
                my $new_query = $query =~ s/$keyword/$replace/r;
                $possibilities{$new_query} = calculate_perplexity($domain, $new_query);
            }
        }

        if (defined $word->{add}) {
            for my $add (@{$word->{add}}) {
                my $new_query = "$query $add";
                $possibilities{$new_query} = calculate_perplexity($domain, $new_query);
            }
        }
    }

    # sort based on perplexity
    my @result = sort { $possibilities{$a} <=> $possibilities{$b} } keys %possibilities;
    return \@result;
}

post '/searches' => sub {
    my $c = shift;
    my $query = $c->param('query');
    my $domain = $c->param('domain');
    my $options = generate_possible_searches($domain, $query);
    $c->render(json => {
        type => 'search',
        options => $options
    });
};

app->start;
