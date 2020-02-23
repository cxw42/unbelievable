# t/100_shortcode_parser.t: Test the shortcode parser

use App::unbelievable ();
use App::unbelievable::Util;
use Data::Dumper;
use Test::More;

sub callback {
    my ($code, $lrArgs, $templater) = @_;
    diag "Shortcode $code, args " . Dumper($lrArgs);
}

ok(!!1, 'truth is still true!');

my $templater = {};
my $text = <<'EOT';
Test of a document with shortcodes embedded.
{{< code1 >}}
{{< code2 arg1 >}}
{{< code3 "arg1 with spaces" >}}
{{< code4 "arg1 with \"embedded quotes\"" >}}
{{< code5 arg1 arg2 "arg3 with spaces" >}}
EOT
App::unbelievable::_process_shortcodes('test1.md', $templater, $text, \&callback);

done_testing;
