# Haystack API

This is the backend for a Startup Weekend Twin Cities 6 project. Developed in a handful of hours over a busy weekend, it talks to a Chrome extension to improve your search keywords. Full of hacks!  

## What is it?

Haystack is a tool to help you search like an expert. Google is incredible, but it can only help you so much when you don't know the words that domain experts use to describe problems and solutions. Garbage in, garbage out, and all that. 

For a simple example, think of the ball thingy in the back of a toilet: if that thing broke, and you were googling for a solution, what would you search for? If you don't know the technical term ('float'), you need to find a page that links your non-expert language ('ball thing') to the expert language ('float'). Once you know the right word, finding a high quality solution is easy.

The idea with Haystack is to take your original query, ask you which content area you're interested in, and leverage that knowledge to try to generate variations of your search query that are more similar to the language used by experts in that domain. In theory, this will give you better search results.

##Installation

You'll need:

* A recent version of Perl (5.18.2 is specified, but >=5.16 will be fine if you remove that line).
* (Mojolicious)[http://mojolico.us], the lovely web framework.
* (SRILM)[http://www.speech.sri.com/projects/srilm/]. Language modelling toolkit. 
    
### SRILM

Building/installing SRILM is a little tricky, but follow `srilm/INSTALL` closely and it'll be ok. Make sure to set $SRILM in your environment to the SRILM source directory.

Once it has built, make sure to add `$SRILM/bin` to your `$PATH` so that the Haystack API can find it.

Then, you need to create your language models.

A two step process for each model you want to add (in our case, we did two: python and snakes):

1. `ngram-count -write snakes-3gram.count -tolower -interpolate3 -text snakes.txt`
2. `ngram-count -read snakes-3gram.count -lm snakes-3gram.lm -order 3`

Where `snakes.txt` is a large (megabyte or more, ideally) collection of text about snakes, with one sentence per line.

Put the resulting "snakes-3gram.lm" file into the same directory as api.pl. Do the same thing for "python" instead of snakes and you should be good to go.

Note that you'll need to set up both `snakes-3gram.lm` and `python-3gram.lm` in order for the API to work without any changes. Sorry, hackathon code.

##How it works

###Expert language models

SRILM generates an interpolated trigram model based on the input text. We chose text written by experts in the knowledge domain (like freely-available popular books on Python, or wiki articles/blog posts about snakes). 

####Aside: Interpolated trigram model?

This just describes a large collection of probabilities based on word relationships in the text. Trigram (instead of quadgram or bigram) just means that the longest unit of text being analyzed is three units. For example, if we created a language model based on the two phrases: 

1. `The horse ran down the road.`
2. `The horse stood patiently, watching the other animals.`

We could say that given two words as input "The horse", the probability that the next word will be "ran" is 50%. Same for "stood". Because our model is __interpolated__, we also analyze the text at the bigram and even unigram level (at which point you're just discussing word frequencies). That is, from a bigram perspective, the probability that the next word after "the" will be "road" is 25%: of the 4 instances of "the", it occurs once as the following word. Of course, "the" is a stopword that should probably be stripped out, but you get the idea.  

### Guessing a domain

Once we have our expert language models, we collect the user's search query and see which domain it matches better. We collect a value called __perplexity__, which approximately describes how well the collection of probabilities that make up our language model predict the given input. In other words, how probable is our input, according to the each model? The domain options (in this case two) are returned to the user ranked by perplexity, and the user picks one.

### Generating better search terms

Once we know the domain (i.e. which model the user cares about), we generate permutations of the original search query by substituting/adding terms to the query and seeing how well said the modified queries are predicted by the expert language model. In other words, we're trying to see which variation compares best to the language used by domain experts, because that's the sort of language that is going to lead you to the best results on Google. We select the top 5 results and present them to the user in the Chrome extension (well, hacked into the Google search UI).

#### Search term permutation generation

We cheat, see the `%mappings` hash in `api.pl`. There was a bunch of work done to use WordNet to find similar words in the given domain, but it wasn't ready in time for the presentation.

## Bugs

Surely lots.

## Future

Zero plans for this codebase (burn it!), but I think the problem is a real one.  Grab my email out of a commit if you're interested in chatting about this sort of thing. I think there's a lot of potential for learning aids built into the search process, from JIT technical vocab acquisition to grasping conceptual relationships by looking at how an expert modifies a query over multiple iterations to find an answer.
