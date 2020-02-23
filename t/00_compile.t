use strict;
use Test::More 0.98;

# Note: for some reason, use_ok() causes `cover -test` to fail.
# Therefore, require_ok().
require_ok $_ for qw(
    App::unbelievable
    App::unbelievable::CLI
);

done_testing;
