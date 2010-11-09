#!/usr/bin/perl -w
use lib '../../';
use strict;
use Filter::HereDocIndent;

use Test;
BEGIN {plan tests => 2}



#------------------------------------------------------------------------------
# test 1: basic filtering
#
do {
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
};
#
# test 1: basic filtering
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# test 2: commented out here doc
#
sub test2 {
	my ($var);
	
	#$var=<<'(XXXX)';
	#a
	#b
	#c

	$var=<<'(MYDOC)';
	a
	b
	c
	(MYDOC)
	
	return $var;
}

if (test2() eq "a\nb\nc\n")
	{ok 1}
else
	{ok 0}
#
# test 2: commented out here doc
#------------------------------------------------------------------------------

