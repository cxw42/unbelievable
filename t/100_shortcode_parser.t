# t/100_shortcode_parser.t: Test the shortcode parser

use App::unbelievable ();
use App::unbelievable::Util;
use Data::Dumper;
use List::AutoNumbered;
use Test::Fatal;
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

# Callback to get the text for a shortcode.  Stashes the text away; ignores
# anything before or after the text.
sub callback {
    my ($code, $lrArgs, $templater) = @_;
    return $templater->($code, {_=>$lrArgs});
} #callback()

###########################################################################

my $good = List::AutoNumbered->new(__LINE__); $good->
    # Tests of various styles of argument
    load(LSKIP 1, '{{< code1 >}}', q({''=>'code1','_'=>[]}))->
    ('{{< code2 arg1 >}}', q({''=>'code2','_'=>['arg1']}))
    ('{{< code3 "arg1 with spaces" >}}', q({''=>'code3','_'=>['arg1 with spaces']}))
    ('{{< code4 "arg1 with \"embedded quotes\"" >}}', q({''=>'code4','_'=>['arg1 with "embedded quotes"']}))
    ('{{< code4b "arg1 with \'embedded quotes\'" >}}', q({''=>'code4b','_'=>['arg1 with \'embedded quotes\'']}))
    ('{{< code5 arg1 arg2 "arg3 with spaces" >}}', q({''=>'code5','_'=>['arg1','arg2','arg3 with spaces']}))
    ('{{< code5 arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9 arg10 arg11 arg12 >}}', q({''=>'code5','_'=>['arg1','arg2','arg3','arg4','arg5','arg6','arg7','arg8','arg9','arg10','arg11','arg12']}))

    # Whitespace within the shortcode
    (LSKIP 2, '{{<x>}}', q({''=>'x','_'=>[]}))
    ('{{<x >}}', q({''=>'x','_'=>[]}))
    ('{{< x>}}', q({''=>'x','_'=>[]}))
    ('{{< x >}}', q({''=>'x','_'=>[]}))
    ('{{< x arg>}}', q({''=>'x','_'=>['arg']}))
    ("{{< x arg\t>}}", q({''=>'x','_'=>['arg']}))
    ("{{< x\targ >}}", q({''=>'x','_'=>['arg']}))
    ("{{<\tx arg >}}", q({''=>'x','_'=>['arg']}))

    # Text around shortcodes
    (LSKIP 2, '{{<x>}}after', q({''=>'x','_'=>[]}after))
    ('before{{<x>}}', q(before{''=>'x','_'=>[]}))
    ('before{{<x>}}after', q(before{''=>'x','_'=>[]}after))

    # Multiple shortcodes
    (LSKIP 2, '{{<x>}}between{{<y>}}', q({''=>'x','_'=>[]}between{''=>'y','_'=>[]}))
    ('before{{<x>}}between{{<y>}}', q(before{''=>'x','_'=>[]}between{''=>'y','_'=>[]}))
    ('before{{<x>}}between{{<y>}}after', q(before{''=>'x','_'=>[]}between{''=>'y','_'=>[]}after))
    ;

for my $case (@$good) {
    #diag Dumper $case;
    my $testname = elide($case->[1]) . " (line $case->[0])";
    my $text = $case->[1];
    is( exception { App::unbelievable::_process_shortcodes('test1.md', \&templater, $text, \&callback) }, undef, "runs OK: $testname" );
    is($text, $case->[2], $testname);
}

my $syntax_error = List::AutoNumbered->new(__LINE__); $syntax_error->
    # Unterminated shortcode
    load(LSKIP 1, '{{<x', qr{Unterminated shortcode.*at 1:1})->
    ('{{<x {{<', qr{Unterminated shortcode.*at 1:1})
    ;

for my $case (@$syntax_error) {
    #diag Dumper $case;
    my $testname = elide($case->[1]) . " (line $case->[0])";
    my $text = $case->[1];
    like( exception { App::unbelievable::_process_shortcodes('test1.md', \&templater, $text, \&callback) }, $case->[2], "dies OK: $testname" );
}

done_testing;
