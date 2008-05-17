use strict;
use warnings;

package Test::Continuous::Formatter;
use base 'TAP::Formatter::Console';

use IO::String;
use self;
use Log::Dispatch;
use Log::Dispatch::Screen;

use 5.008;
our $VERSION = "0.0.2";

{
    my $dispatcher;
    sub _dispatcher {
        return $dispatcher if $dispatcher;

        $dispatcher = Log::Dispatch->new;
        $dispatcher->add(
            Log::Dispatch::Screen->new(name => "screen", min_level => "debug")
        );

        eval {
            require Log::Dispatch::MacGrowl;
            $dispatcher->add(
                Log::Dispatch::MacGrowl->new(
                    name => "growl",
                    min_level => "debug",
                    app_name => "Test::Continuous",
                    title => "Test Report",
                    sticky => 0,
                ));
        };

        return $dispatcher;
    }
}

sub _send_notify {
    self->_dispatcher->notice(args[0]);
}

sub summary {
    my ($aggregate) = args;
    my $summary;
    my $non_zero_exit_status = 0;

    if ($aggregate->all_passed) {
        $summary = "ALL PASSED";
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

    if (my $growl = self->_dispatcher->remove("growl")) {
        $growl->{icon_file} = '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/' .
            ($non_zero_exit_status
                 ? 'AlertCautionIcon.icns'
                 : $aggregate->all_passed
                 ? 'ToolbarInfo.icns' : 'AlertStopIcon.icns');
        self->_dispatcher->add($growl);
    }

    print "\n" . "-" x 45 . "\n";
    for (split(/\n(?!  )/, $summary )) {
        s/ +/ /gs;
        self->_send_notify("$_\n");
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

