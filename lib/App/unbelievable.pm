package App::unbelievable;
use 5.010001;
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long::Subcommand;
use Import::Into;
use Pod::Usage;

use version 0.77; our $VERSION = version->declare('v0.0.1');

# Imports: used by Dancer2 code {{{1


# }}}1
# Runner: used by script/unbelievable {{{1

sub run {
    my $args = shift or die "No args";
    local @ARGV = @$args;
    my %opts;
    my $res = GetOptions(
        summary => 'Build a static site',
        default_subcommand => 'help',

        # common options recognized by all subcommands
        options => {
            'help|h|?|usage' => {
                summary => 'Display help message',
                handler => \$opts{help},
                #handler => sub {
                #    my ($cb, $val, $res) = @_;
                #    if ($res->{subcommand}) {
                #        say "Help message for $res->{subcommand} ...";
                #    } else {
                #        say "General help message ...";
                #    }
                #    exit 0;
                #},
            },
            'man' => {
                summary => 'Display full docs',
                handler => \$opts{man},
            },
            'version|V' => {
                summary => 'Display program version',
                handler => sub {
                    say "$0 version $main::VERSION";
                    exit 0;
                },
            },
            'verbose|v+' => {
                handler => \$opts{verbose},
            },
        }, # options

        # subcommands
        subcommands => {
            new => {
                summary => 'Create a new site',
            },
            build => {
                summary => 'Build the static html',
            },
            help => {
                summary => 'Show help',
            },
        }, # subcommands
    );

    say "Got options:\n", ddc($res), ddc(\%opts) if $opts{verbose};

    pod2usage() unless $res->{success};
    pod2usage(-verbose => 1, -exitval => 0) if $opts{help};
    pod2usage(-verbose => 1, -exitval => 0)
        if $res->{success} && $res->{subcommand}->[0] eq 'help';
    pod2usage(-verbose => 2, -exitval => 0) if $opts{man};

    my $cmdname = 'cmd_' . join '_', @{$res->{subcommand}};
    my $fn = __PACKAGE__->can($cmdname)
        or die "I don't know subcommand $cmdname";
    return $fn->($res, \%opts);
} #run()

sub cmd_new {
    my ($res, $opts) = @_;
    say "New site";
    return 0;
} #new()

sub cmd_build {
    my ($res, $opts) = @_;
    say "Build site";
    return 0;
} #new()

# }}}1

1;
__END__

=encoding utf-8

=head1 NAME

App::unbelievable - Yet another site generator (can you believe it?)

=head1 SYNOPSIS

    use App::unbelievable;  # Pulls in Dancer2
    # your routes here
    unbelievable;           # At EOF, fills in the rest of the routes.

=head1 DESCRIPTION

App::unbelievable makes a Dancer2 application into a static site generator.

=head1 THANKS

Thanks to L<Getopt::Long::Subcommand> --- I used some code from its Synopsis.

=head1 LICENSE

Copyright (C) 2020 Chris White.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Chris White E<lt>cxwembedded@gmail.comE<gt>

=cut

# vi: set fdm=marker: #
