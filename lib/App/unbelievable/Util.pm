package App::unbelievable::Util;
# Common utilities

use 5.010001;   # For say(), stacked file tests
use feature ':5.10';
use strict;
use warnings;
use autodie ':all';

use Import::Into;

use vars::i '$VERBOSE' => 1;    # DEBUG

use Data::Dumper;
BEGIN { $Data::Dumper::Indent = 1; }
require File::Spec;

use parent 'Exporter';
use vars::i '@EXPORT' => [qw($VERBOSE _croak _diag)];

sub import {
    my $target = caller;
    __PACKAGE__->export_to_level(1, @_);

    $_->import::into($target) foreach qw(strict warnings Data::Dumper File::Spec);
    feature->import::into($target, ':5.10');
    autodie->import::into($target, ':all');
} #import()

# Lazy Carp::croak
sub _croak {
    require Carp;
    goto &Carp::croak;
}

# _diag: lazy Test::More::diag(), conditioned on $VERBOSE.
sub _diag {
    return unless $VERBOSE;
    require Test::More;     # for diag()
    goto &Test::More::diag;
}

