# t/100_shortcode_parser.t: Test the shortcode parser

use App::unbelievable ();
use App::unbelievable::Util;
use Data::Dumper;
use List::AutoNumbered;
use Test::More;

# A simple templater that produces deterministic output without depending
# on any external template file.
my $_d = Data::Dumper->new([], ['D']);
$_d->Indent(0)->Terse(1)->Deepcopy(1)->Sortkeys(1)->Quotekeys(1)->Sparseseen(1)
    ->Pair('=>');

sub templater {
    my ($filename, $hrTemplateVars, $templateOptions) = @_;
    return $_d->Values([{'' => $filename, %$hrTemplateVars}])->Dump;
} #templater()

my $text_result;    # set by callback()

sub callback {
    my ($code, $lrArgs, $templater) = @_;
    $text_result = $templater->($code, {_=>$lrArgs});
} #callback()

###########################################################################

my $good = List::AutoNumbered->new(__LINE__);
$good->load('{{< code1 >}}', q({''=>'code1','_'=>[]}));

for my $case (@$good) {
    diag Dumper $case;
    App::unbelievable::_process_shortcodes('test1.md', \&templater, $case->[1], \&callback);
    is($text_result, $case->[2], elide($case->[1]) . " (line $case->[0])"
    );
}

my $text = <<'EOT';
Test of a document with shortcodes embedded.
{{< code1 >}}
{{< code2 arg1 >}}
{{< code3 "arg1 with spaces" >}}
{{< code4 "arg1 with \"embedded quotes\"" >}}
{{< code4b "arg1 with \'embedded quotes\'" >}}
{{< code5 arg1 arg2 "arg3 with spaces" >}}
EOT
App::unbelievable::_process_shortcodes('test1.md', \&templater, $text, \&callback);

done_testing;
