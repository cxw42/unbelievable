package App::unbelievable::CLI;

use 5.010001;
use strict;
use warnings;
use autodie ':all';

# Runner: used by script/unbelievable

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
} #cmd_new()

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
} #cmd_build()

1;
