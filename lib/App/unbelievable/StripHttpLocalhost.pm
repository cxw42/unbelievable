package App::unbelievable::StripHttpLocalhost;

=head1 NAME

App::unbelievable::StripHttpLocalhost - Plack middleware to remove "http://localhost"

=head1 TODO

Make this work correctly!  Wallflower's docs specifically note that wallflower
does not rewrite the content of URLs.  Figure out how to handle this as
cleanly as possible.  Perhaps, instead of this postprocessing, change
the request.uri_base at the time the request is processed by Dancer2?

=cut

use App::unbelievable::Util;

use parent 'Plack::Middleware';
use Plack::Util;

sub call {
    my ($self, $env) = @_;
    my $res = $self->app->($env);

    return Plack::Util::response_cb($res, sub {
        my $res = shift;
        my @headers = $res->[1];
        my @header_pairs = map { [$headers[$_*2], $headers[$_*2+1]] } 0..$#headers/2;

        # Ignore everything but text/html
        for my $pair (@header_pairs) {
            next unless $pair->[0] eq 'Content-Type';
            return unless $pair->[1] eq 'text/html';
        }

        # Postprocess the response
        _diag(\2, 'postprocessing request in ' . __PACKAGE__);
        return sub {
            my $chunk = shift;
            return unless defined $chunk;
            $chunk =~ s{https?://localhost/}{/}g;
            return $chunk;
        };
    });
}

1;
__END__
=head1 LICENSE

Copyright (C) 2020 Chris White.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Chris White E<lt>cxwembedded@gmail.comE<gt>

=cut

