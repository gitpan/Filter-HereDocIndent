#!/usr/local/bin/perl -w
use lib '../../';
use strict;
use Filter::HereDocIndent;

use Test;
BEGIN {plan tests => 1}

my ($var);

    $var=<<'(MYDOC)';
    a
     b
   c
    (MYDOC)

if ($var eq "a\n b\nc\n")
	{ok 1}
else
	{ok 0}


