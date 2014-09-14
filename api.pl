#!/usr/bin/env perl
use strict;
use warnings;
use 5.18.2;

use Mojolicious::Lite;

sub python_to_pydev {
    my $list = shift;
    my @result = map { s/python/python development/r } @{$list};
    \@result;
}

sub guess_domain {
    my $query = shift;

    my @models = (
        'snakes',
        'python'
    );

    my @perplexity;
    foreach my $model (@models) {
        open my $tmpfile, '>', 'domain-guess-search-terms';
        print $tmpfile $query;
        my $output = `ngram -lm $model-3gram.lm -ppl domain-guess-search-terms`;
        $output =~ /ppl1= (\d+\.?\d+?)/;
        my $ppl = $1;
        push @perplexity, [$model, $ppl];
    }

    # sort based on perplexity
    @perplexity = map { $_->[0] } sort { $a->[1] <=> $b->[1] } @perplexity;
    \@perplexity;
}

post '/domains' => sub {
    my $c = shift;
    my $query = $c->param('query');
    my $options = guess_domain $query;
    $c->render(json => {
        type => 'domain',
        options => python_to_pydev $options
    });

};

my %mappings = (
    python => {
        add_for_all => [qw(module library pypi)],
        csv => {
            add => [qw(parse)]
        },
        report => {
            add => [qw(graph statistics)],
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
    $output =~ /ppl1= (\d+\.?\d+?)/;
    my $ppl = $1;
    return $ppl;
}

sub generate_possible_searches {
    my $domain = shift;
    my $query = shift;
    my @query_terms = split ' ', $query;
    return if not defined $mappings{$domain};

    my %possibilities;
    $possibilities{$query} = calculate_perplexity($domain, $query);

    my $domain_map = $mappings{$domain};
    for my $global_add (@{$domain_map->{add_for_all}}) {
        my $new_query = $query . ' ' . $global_add;
        $possibilities{$new_query} = calculate_perplexity($domain, $new_query);
    }

    for my $keyword (keys %{$domain_map}) {
        next if $keyword eq 'add_for_all';
        next if not defined $domain_map->{$keyword};

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
    return [@result[0 .. 4]];
}

post '/searches' => sub {
    my $c = shift;
    my $query = $c->param('query');
    my $domain = $c->param('domain');
    my $options = generate_possible_searches($domain, $query);
    $c->render(json => {
        type => 'search',
        options => python_to_pydev $options
    });
};

app->start;
