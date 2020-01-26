package App::unbelievable;
use 5.010001;
use strict;
use warnings;

use Data::Dumper;
BEGIN { $Data::Dumper::Indent = 1; }

use File::Slurp;
use File::Spec;

use version 0.77; our $VERSION = version->declare('v0.0.1');

# Imports: used by Dancer2 code {{{1
use parent 'Exporter';
our @EXPORT;
BEGIN { @EXPORT = qw(unbelievable); }

my $APPNAME;

sub import {
    say "Loading ", __PACKAGE__;
    __PACKAGE__->export_to_level(1, @_);

    require Import::Into;
    require feature;
    require Dancer2;
    my $target = $APPNAME = caller;
    $_->import::into($target) foreach qw(Dancer2 strict warnings);
    feature->import::into($target, ':5.10');

} #import()

# Process a markdown file into HTML.
sub _markdown_processor {
    die "TODO processing file ", shift;
} #_markdown_processor

# Make default routes.  Usage: unbelievable();
sub unbelievable {
    say "unbelievable ", __PACKAGE__;

    require Dancer2;
    require Dancer2::Core::Route;

    # TODO find a less hackish way to get the app and DSL.
    my ($app) = grep { $_->name eq caller } @{Dancer2->runner->apps};
    die "Could not find Dancer2 application" unless $app;

    my $dsl = do { no strict 'refs'; &{ caller . '::dsl' } };
    die "Could not find Dancer2 DSL" unless $dsl;

    # Find the public dir and the content dir
    my $public_dir = $dsl->setting('public_dir') or die "No public_dir set";
    $public_dir = File::Spec->rel2abs($public_dir)
        unless File::Spec->file_name_is_absolute($public_dir);
    my ($vol, $dirs, $file) = File::Spec->splitpath($public_dir);
    my $content_dir = File::Spec->catpath($vol, $dirs, 'content');

    say "public_dir $public_dir";
    say "content_dir $content_dir";

    # Create default / route
    my $route = Dancer2::Core::Route->new(
        method => 'get', regexp => '/', code => sub {} );
    unless($app->route_exists($route)) {
        say "Adding GET / route";
        my $index_file;
        my @candidates;
        push @candidates, File::Spec->catfile($content_dir, 'index.md');
        push @candidates, File::Spec->catfile($public_dir, 'index.html');

        foreach my $candidate (@candidates) {
            next unless -r $candidate;
            $index_file = $candidate;
            last;
        }

        die "No index file (tried " . join(' ', @candidates) . ')'
            unless $index_file;

        if($index_file =~ /\.html?$/) {
            $dsl->get('/', sub {
                return read_file($index_file);
            });
        } else {
            $dsl->get('/', sub {
                return _markdown_processor($index_file);
            });
        }

    } #endif need to add GET / route

    # Add megasplat route for everything in /content
    say "Adding GET /** route";
    #my $get = do { no strict 'refs'; \&{ caller . '::get' } };
    $dsl->get('/**', sub {
        #say "megasplat:\n", Dumper \@_;
        # TODO find out why the megasplat tags aren't getting passed properly
        # into this function.  The following is an ugly hack.
        my $tags = $dsl->request->{_params}->{splat}->[0];
        #say "megasplat tags:\n", Dumper $tags;

        _markdown_processor(File::Spec->catfile($content_dir, @$tags));
    });

    return 1;   # So the unbelievable() call can be the last thing in the file
} #unbelievable()

# }}}1
# Runner: used by script/unbelievable {{{1

sub run {
    require Getopt::Long::Subcommand;
    require Pod::Usage;
    my $args = shift or die "No args";
    local @ARGV = @$args;
    my %opts;
    my $res = Getopt::Long::Subcommand::GetOptions(
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

    say "Got options:\n", Dumper($res), Dumper(\%opts) if $opts{verbose};

    Pod::Usage::pod2usage() unless $res->{success};
    Pod::Usage::pod2usage(-verbose => 1, -exitval => 0) if $opts{help};
    Pod::Usage::pod2usage(-verbose => 1, -exitval => 0)
        if $res->{success} && $res->{subcommand}->[0] eq 'help';
    Pod::Usage::pod2usage(-verbose => 2, -exitval => 0) if $opts{man};

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
    require App::Wallflower;
    say "Build site";

    # TODO get CPU count per
    # https://gist.github.com/aras-p/47e2252d6b1fa57d3619fd8e021690ec

    # TODO
    # - get all routes from app
    # - include all files in public/ and content/.
    return App::Wallflower->new_with_options( [ #TODO
        ] )->run // 0;
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
Inputs are in C<content/>.  Output goes to C<_built/>.

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
