package Filter::HereDocIndent;
use strict;
use Filter::Util::Call;
use re 'taint';
use vars qw($VERSION $debug);

# documentation at end of file


# version
$VERSION = '0.90';

# constants
use constant REG => 1;
use constant HEREDOC => 2;
use constant POD => 3; # reserved for later improvement


#------------------------------------------------------------------
# import routine: returns the filter object
# 
sub import {
	my ($class, %opts) = @_ ;
	my $self = bless({}, $class);
	
	# default INDENT_CONTENT
	defined($opts{'INDENT_CONTENT'}) or $opts{'INDENT_CONTENT'} = 1;
	$self->{'INDENT_CONTENT'} = $opts{'INDENT_CONTENT'};
	
	# default state
	$self->{'state'} = REG;
	
	# add to filters
	filter_add($self);
}
# 
# import routine: returns the filter object
#------------------------------------------------------------------


#------------------------------------------------------------------
# filter: this sub is run for every line in the calling routine
# 
sub filter {
	my $self = shift;
	my $status = filter_read() ;
	my $line = $_;

	
	# if we're at the end of the file
	if (! $status) {
		# for debugging this module
		if ($debug)
			{print STDERR "\n--------------------------\n"}
	}
	
	# if in here doc
	elsif ($self->{'state'} == HEREDOC) {
		# if this is the end of the heredoc
		if ($line =~ m|^(\s*)$self->{'del_regex'}\s*$|) {
			my $len = length($1);
			
			if ($self->{'INDENT_CONTENT'}) {
				foreach my $el (@{$self->{'lines'}}) {
					$el =~ s|^\s{$len}|| or $el =~ s|^\s+||;
					$el eq '' and $el = "\n";
				}
			}
			
			$line = join('', @{$self->{'lines'}}, $self->{'del'}, "\n");
			$self->{'state'} = REG;
		}
		
		# else add to lines array
		else {
			push @{$self->{'lines'}}, $line;
			$line = '';
		}
	}
	
	# else in regular code
	else {
		# if this line starts a heredoc
		if ($line =~ m/^[^'"]*<<\s*('[^']+'|"[^"]+"|\w+)\s*;\s*/s) {
			$self->{'del'} = $1;
			$self->{'del'} =~ s|^'(.*)'$|$1| or $self->{'del'} =~ s|^"(.*)"$|$1|;
			$self->{'del_regex'} = quotemeta($self->{'del'});
			
			$self->{'lines'} = [];
			$self->{'state'} = HEREDOC;
		}
	}
	
	# for debugging this module
	print STDERR $line if $debug;
	
	$_= $line;
	$status;
}
# 
# filter: this sub is run for every line in the calling routine
#------------------------------------------------------------------




# return true
1;

__END__

=head1 NAME

Filter::HereDocIndent - Indent here documents

=head1 SYNOPSIS

use Filter::HereDocIndent;

 if ($sometest) {
         print <<'(MYDOC)';
         Melody
         Starflower
         Miko
         (MYDOC)
 }

outputs (with text beginning at start of line):

 Melody
 Starflower
 Miko

=head1 INSTALLATION

Filter::HereDocIndent can be installed with the usual routine:

	perl Makefile.PL
	make
	make test
	make install

You can also just copy HereDocIndent.pm into the Filter/ directory of one of
your library trees.

=head1 DEPENDENCIES

HereDocIndent requires C<Filter::Util::Call>, which is part of the standard
distribution starting with Perl 5.6.0.  For earlier versions of Perl you will
need to install C<Filter::Util::Call>, which requires either a C compiler or
a pre-compiled binary.

=head1 DESCRIPTION

HereDocIndent allows you to indent your here documents along with the rest of
the code.  The contents of the here doc and the ending delimiter itself may be
indented with any amount of whitespace.  Each line of content will have the
leading whitespace stripped off up to the amount of whitespace that the
closing delimiter is indented. Only whitespace is stripped off the beginning
of the line, never any other characters

For example, in the following code the closing delimiter is indented eight spaces:

 if ($sometest) {
         print <<'(MYDOC)';
         Melody
         Starflower
         Miko
         (MYDOC)
 }

All of the content lines in the example will have the leading eight whitespace
characters removed, thereby outputting the content at the beginning of the line:

 Melody
 Starflower
 Miko

If a line is indented more than the closing delimiter, it will be indented by
the extra amount in the results.  For example, this code:

 if ($sometest) {
         print <<'(MYDOC)';
         Melody
            Starflower
         Miko
         (MYDOC)
 }

produces this output:

 Melody
    Starflower
 Miko

HereDocIndent does not distinguish between different types of whitespace.  If
you indent the closing delimiter with a single tab, and the contents eight
spaces, each line of content will lose just one space character.  The best
practice is to be consistent in how you indent, using just tabs or just spaces.

HereDocIndent will only remove leading whitespace.  If one of the lines of
content is not indented, the non-whitespace characters will I<not> be removed.
The trailing newline is never removed.

=head2 INDENT_CONTENT

By default the contents of the here document are indented to the same extent
as the closing delimiter.  If you want to leave the contents indented, but
still indent the closing delimiter so that it lines up with its content, set
the C<INDENT_CONTENT> option to zero in when you load HereDocIndent:

 use Filter::HereDocIndent INDENT_CONTENT=>0;

=head2 LIMITATIONS

HereDocIndent was written to be conservative in what it decides are here
documents.  HereDocIndent recognizes the most common usage for here docs and
disregards other less common usages.  If you constrain your here doc
declarations to the format recognized by HereDocIndent (which is by far the
most popular format) then your code will compile just fine.

The format recognized by HereDocIndent is a single print statement or variable
assignment, followed by C<E<lt>E<lt>>, then a quoted string or unquoted string
of word characters, then a semicolon, then the end of line.  Here are a few 
examples that would be parsed properly by HereDocIndent:

 print << '(MYDOC)';
 print << "MYDOC";
 my $var = <<EOT;
 push @arr, <<  '(MYDOC)';


Here are a few examples that would I<not> be recognized by HereDocIndent:

 mysub (<<'MYDOC');
 push @arr, <<'MYDOC', 'foo';
 print <<'MYDOC', "------\n";

HereDocIndent does not currently recognize POD notation, so there could be
unintended problems if you put text in your POD that looks like a here doc.
This issue will need to be fixed in a later release.  HereDocIndent also does
not recognize if an entire line is inside quotes from another line, or even
inside a here doc that it didn't recognize.

=head1 TERMS AND CONDITIONS

Copyright (c) 2002 by Miko O'Sullivan.  All rights reserved.  This program is 
free software; you can redistribute it and/or modify it under the same terms 
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>


=head1 VERSION

=over

=item Version 0.90    August 6, 2002

Initial release

=back

=begin cpan

-------------------------------------------
Version 0.90

registered:  Aug 6, 2002
uploaded:    
announced:   

=end cpan


=cut

