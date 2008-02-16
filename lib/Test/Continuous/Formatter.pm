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
                    icon_file =>
                        '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/' .
                        (self->{test_failed} ? 'AlertStopIcon.icns' : 'ToolbarInfo.icns'),
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

    my $str;
    my $io = IO::String->new($str);
    self->stdout($io);

    self->SUPER::summary($aggregate);

    $str =~ s/^\s*//s;
    $str =~ s/\s*$//s;
    my @lines = split(/\n/, $str);
    shift @lines; shift @lines;

    my $summary = join("\n", @lines);
    if ($summary =~ /FAIL/s) {
        self->{test_failed} = 1;
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

