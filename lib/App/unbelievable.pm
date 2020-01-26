package App::unbelievable;

=encoding utf-8

=head1 NAME

App::unbelievable - Yet another site generator (can you believe it?)

=cut

use 5.010001;   # For say(), stacked file tests
use strict;
use warnings;
use autodie ':all';

use Data::Dumper;
BEGIN { $Data::Dumper::Indent = 1; }

use File::Slurp;
use File::Spec;
use JSON;
use Text::FrontMatter::YAML;
use Text::MultiMarkdown 'markdown';     # TODO someday - Text::Markup
    # But see https://github.com/theory/text-markup/issues/20

use version 0.77; our $VERSION = version->declare('v0.0.1');

use vars::i '$VERBOSE' => 1;    # DEBUG

# Imports: used by Dancer2 code {{{1
use parent 'Exporter';
use vars::i '@EXPORT' => [qw(unbelievable)];

sub import {
    my $target = caller;
    say 'Loading ', __PACKAGE__, ' into ', $target;
    __PACKAGE__->export_to_level(1, @_);

    require Import::Into;
    require feature;
    require Dancer2;
    $_->import::into($target) foreach qw(Dancer2 strict warnings);
    feature->import::into($target, ':5.10');

} #import()

# Produce a file, e.g., by processing a markdown file into HTML.
# Returns:
#   - falsy: pass
#   - hashref:
#       - {send_file => $filename}: a filename to send_file
#       - {template => [...]}: args for template().
sub _produce_output {
    my ($public_dir, $content_dir, $request, $lrTags) = @_;
    my $path = join('/', @$lrTags);
    _diag("Processing file ", $path);

    my $fn;             # File we are going to read from
    my @candidates;     # Where we might find it

    push @candidates, File::Spec->catfile($content_dir, _suffix('.md', @$lrTags));
    push @candidates, File::Spec->catfile($public_dir, _suffix('.html', @$lrTags));
    push @candidates, File::Spec->catfile($public_dir, _suffix('.htm', @$lrTags));

    foreach my $candidate (@candidates) {
        next unless -f -r $candidate;
        $fn = $candidate;
        last;
    }

    die "Could not find file for $path (tried @{[join(' ', @candidates)]})"
        unless $fn;

    return {send_file => $fn} if $fn =~ /\.html?$/;

    # Process a Markdown file
    my @retval = ('index');     # Name of the template
    my ($frontmatter, $markdown) = _load($fn);
    _diag("Got frontmatter\n", Dumper $frontmatter);
    _diag("Got contents:\n$markdown");

    # TODO shortcodes

    my $html = markdown($markdown, {base_url => $request->uri_base});
    _diag("Generated HTML:\n$html");

    return { template => ['raw', {htmlsource => $html}] };
} #_produce_output

# Make default routes.  Usage: unbelievable();
sub unbelievable {
    my $appname = caller or die "No caller!";
    say 'unbelievable ', __PACKAGE__, ' in ', $appname;

    require Dancer2;

    my $dsl = do { no strict 'refs'; &{ $appname . '::dsl' } };
    die "Could not find Dancer2 DSL" unless $dsl;

    # Find the public dir and the content dir
    my $public_dir = $dsl->setting('public_dir') or die "No public_dir set";
    $public_dir = File::Spec->rel2abs($public_dir)
        unless File::Spec->file_name_is_absolute($public_dir);
    my ($vol, $dirs, $file) = File::Spec->splitpath($public_dir);
    my $content_dir = File::Spec->catpath($vol, $dirs, 'content');

    say "public_dir $public_dir";
    say "content_dir $content_dir";

    # Create default routes.  The caller must invoke this function
    # after defining any other routes, so these will only be used
    # as fallbacks.
    my $text = _line_mark_string(<<EOT);
    package App::unbelievable::Routes;
    use 5.010001;
    use strict;
    use warnings;
    use vars::i {
        '\$APPNAME' => @{[_sqescape($appname)]},
        '\$PUBLIC' =>@{[_sqescape($public_dir)]},
        '\$CONTENT' => @{[_sqescape($content_dir)]},
    };
EOT

    $text .= _line_mark_string(<<'EOTSQ');
    use Data::Dumper;
    use Dancer2 appname => $APPNAME;

    say 'Loading routes into ', $APPNAME;

    # Call our _produce_output, above, and take the appropriate action.
    # This way we don't have to try to directly invoke Dancer2 DSL in
    # _produce_output.
    sub _do_file {
        my $content =
            App::unbelievable::_produce_output($PUBLIC, $CONTENT, request, shift);
        pass unless $content;
        send_file $content->{send_file} if $content->{send_file};
        return template @{$content->{template}} if $content->{template};
        die "Assertion failure: I don't know how to handle that file.\n" .
            Dumper $content;
    }

    get '/' => sub { _do_file(['index']) };
    # Note: we never get here on requests for static files --- those are
    # handled by middleware before Dancer2 checks routes.  See
    # Dancer2::Core::App::to_app().
    get '/**' => sub { _do_file(splat) };
EOTSQ

    eval $text;
    die $@ if $@;

    return 1;   # So the unbelievable() call can be the last thing in the file
} #unbelievable()

# }}}1
# Helper routines {{{1
#
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

# Lazy Carp::croak
sub _croak {
    require Carp;
    goto &Carp::croak;
}

# Escape in single quotes
sub _sqescape {
    my $str = shift;
    $str =~ s/'/\\'/g;
    return "'$str'";
}
# }}}1

# Add a suffix to the last component of a list.  No-op if the
# list is empty.
sub _suffix {
    my $suffix = shift;
    return () unless @_;
    my $last = $_[$#_] . $suffix;
    return @_[0..$#_-1], $last;
}

# Load a Markdown file, which may have front matter.
# Returns an arrayref of YAML documents.
sub _load {
    my $fn = shift;
    my $text = read_file($fn);
    my ($frontmatter, $markdown);
    my @errors;

    # Mainline case: YAML frontmatter with `---` separators
    my $reader;
    eval {
        $reader = Text::FrontMatter::YAML->new(
            document_string => $text
        );
        $frontmatter = $reader->frontmatter_hashref;
        $markdown = $reader->data_text // '';
    };
    push @errors, "Could not read YAML-frontmatter document: $@" if $@;

    return ($frontmatter, $markdown) unless @errors;

    # That didn't work.  Look for JSON frontmatter without separators.
    eval {
        my $charcount;
        $reader = JSON->new;
        ($frontmatter, $charcount) = $reader->decode_prefix($text);
        $markdown = substr $text, $charcount//0;
    };
    push @errors, "Could not read JSON: $@" if $@;

    return ($frontmatter, $markdown) unless(@errors);

    # Default: assume the full contents are markdown, and there is
    # no frontmatter.
    say join "\n  ", "While loading $fn, got errors:", @errors if $VERBOSE;

    return ({}, $text);
} #_load()

# _diag: lazy Test::More::diag(), conditioned on $VERBOSE.
sub _diag {
    return unless $VERBOSE;
    require Test::More;     # for diag()
    goto &Test::More::diag;
}

1;
__END__

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
