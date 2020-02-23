package App::unbelievable::Util;

=head1 NAME

App::unbelievable::Util - common utilities

=head1 VARIABLES

=cut

use 5.010001;   # For say(), stacked file tests
use feature ':5.10';
use strict;
use warnings;
use IPC::System::Simple;    # for autodie ':all'
use autodie ':all';

use Import::Into;

=head2 $VERBOSE

When truthy, L</_diag> produces output.

=cut

use vars::i '$VERBOSE' => 0;

use Data::Dumper;
BEGIN {
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Sortkeys = 1;
}
require File::Spec;

use parent 'Exporter';
use vars::i
    '@EXPORT' => [qw($VERBOSE _croak _diag _line_mark_string elide)];

=head1 FUNCTIONS

=head2 import

Load strict, warnings, &c. into the caller.

=cut

sub import {
    my $target = caller;
    __PACKAGE__->export_to_level(1, @_);

    $_->import::into($target) foreach qw(strict warnings Data::Dumper File::Spec);
    feature->import::into($target, ':5.10');
    IPC::System::Simple->import::into($target);
    autodie->import::into($target, ':all');
} #import()

=head2 _croak

Lazy L<Carp/croak>.

=cut

sub _croak {
    require Carp;
    goto &Carp::croak;
}

=head2 _diag

Lazy L<Test::More/diag>, conditioned on L</$VERBOSE>.
If the first argument is a scalar reference, output is suppressed
unless L</$VERBOSE> is at least the referenced value.

=cut

sub _diag {
    return unless $VERBOSE;
    if(ref $_[0] eq 'SCALAR') {
        return unless $VERBOSE >= ${$_[0]};
        shift;
    }
    require Test::More;     # for diag()
    goto &Test::More::diag;
}

=head2 _line_mark_string

Add a C<#line> directive to a string.  Usage:

    my $str = _line_mark_string <<EOT ;
    $contents
    EOT

or

    my $str = _line_mark_string __FILE__, __LINE__, <<EOT ;
    $contents
    EOT

In the first form, information from C<caller> will be used for the filename
and line number.

The C<#line> directive will point to the line after the C<_line_mark_string>
invocation, i.e., the first line of <C$contents>.  Generally, C<$contents> will
be source code, although this is not required.

C<$contents> must be defined, but can be empty.

=cut

sub _line_mark_string {
    my ($contents, $filename, $line);
    if(@_ == 1) {
        $contents = $_[0];
        (undef, $filename, $line) = caller;
    } elsif(@_ == 3) {
        ($filename, $line, $contents) = @_;
    } else {
        _croak("Invalid invocation");
    }

    _croak("Need text") unless defined $contents;
    die "Couldn't get location information" unless $filename && $line;

    $filename =~ s/"/-/g;
    ++$line;

    return <<EOT;
#line $line "$filename"
$contents
EOT
} #_line_mark_string()

=head1 elide

Truncate a string to a desired length, adding an ellipsis if truncated.
Copied from L<String::Escape> by Matthew Simon Cavalletto.

=cut

use vars::i {
    '$Elipses' => '...',
    '$DefaultLength' => 60,
    '$DefaultStrictness' => 10,
};

# $elided_string = elide($string);
# $elided_string = elide($string, $length);
# $elided_string = elide($string, $length, $word_boundary_strictness);
# $elided_string = elide($string, $length, $word_boundary_strictness, $elipses);
sub elide ($;$$) {
        my $source     = shift;
        my $length     = scalar(@_) ? shift() : $DefaultLength;
        my $word_limit = scalar(@_) ? shift() : $DefaultStrictness;
        my $elipses    = scalar(@_) ? shift() : $Elipses;

        # If the source is already short, we don't need to do anything
        return $source if (length($source) < $length);

        # Leave room for the elipses and make sure we include at least one character.
        $length -= length( $elipses );
        $length = 1 if ( $length < 1 );

        my $excerpt;

        # Try matching $length characters or less at a word boundary.
        $excerpt = ( $source =~ /^(.{0,$length})(?:\s|\Z)/ )[0] if ( $word_limit );

        # If that fails or returns much less than we wanted, ignore boundaries
        $excerpt = substr($source, 0, $length) if (
                ! defined $excerpt or
                length($excerpt) < length($source) and
                        ! length($excerpt) || abs($length - length($excerpt)) > $word_limit
        );

        return $excerpt . $elipses;
} #elide()

1;
__END__

# Rest of the docs {{{1

=head1 THANKS

L</elide> is Copyright 2010, 2002 Matthew Simon Cavalletto.
Portions copyright 1996, 1997, 1998, 2001 Evolution Online Systems, Inc.
Licensed under the same terms as Perl itself.

=head1 LICENSE

Copyright (C) 2020 Chris White.  See above for copyright in L</elide>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Chris White E<lt>cxwembedded@gmail.comE<gt>

=cut

# }}}1
