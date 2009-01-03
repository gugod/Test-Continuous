use strict;
use warnings;

package Test::Continuous::Formatter;
use base 'TAP::Formatter::Console';
use Test::Continuous::Notifier;
use self;

use 5.008;
our $VERSION = "0.0.2";

sub summary {
    my ($aggregate) = args;
    my $summary;
    my $non_zero_exit_status = 0;

    if ($aggregate->all_passed) {
        $summary = "ALL PASSED\n";
    }
    else {
        local $, = ",";
        my $total  = $aggregate->total;
        my $passed = $aggregate->passed;
        $summary = "${total} planned, only ${passed} passed.\n";

        my @t = $aggregate->descriptions;
        for my $t (@t) {
            $t =~ /(t\/.*$)/;
            my $tfile = $1;
            my ($parser) = $aggregate->parsers($t);
            if (my @r = $parser->failed()) {
                $summary .= "Failed test(s) in $tfile: @r\n";
            }

            if ( my $exit = $parser->exit ) {
                $summary .= "  Non-zero exit status: $tfile\n";
                $non_zero_exit_status = 1;
            }
        }
    }

    for (split(/\n(?!  )/, $summary )) {
        s/ +/ /gs;
        Test::Continuous::Notifier->send_notify(
            "$_\n",
            $non_zero_exit_status ? 'alert' : $aggregate->all_passed ? 'info' : 'warning'
        );
    }
}

1;

=head1 NAME

Test::Continuous::Formatter - TAP Formatter for Test::Continuous

=head1 SYNOPSIS

You shouldn't use this module directly.

=head1 DESCRIPTION

This package inherits from L<TAP::Formatter::Console>, and dispatch
test summary to different output channels.

=over

=item summary

Overrides the C<summary> method from parent. Send a processed output
to a C<Log::Dispatcher> object.

=back

=cut

