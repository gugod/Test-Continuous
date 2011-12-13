use strict;
use warnings;

package Test::Continuous::Notifier;
use Log::Dispatch;
use Log::Dispatch::Screen;
use self;

{
    my $dispatcher;
    sub _dispatcher {
        return $dispatcher if $dispatcher;

        $dispatcher = Log::Dispatch->new;
        $dispatcher->add(
            Log::Dispatch::Screen->new(name => "screen", min_level => "debug")
        );

        eval {
            require Log::Dispatch::DesktopNotification;
            $dispatcher->add(
                Log::Dispatch::DesktopNotification->new(
                    name => "continuous_notify",
                    min_level => "debug",
                    app_name => "Test::Continuous",
                    title => "Test Report",
                    sticky => 0,
                ));
        };

        return $dispatcher;
    }
}

my %status_icon = (
    'alert'   => 'AlertCautionIcon.icns',
    'warning' => 'AlertStopIcon.icns',
    'info'    => 'ToolbarInfo.icns',
);

sub send_notify {
    my ($text, $status) = args;
    $status ||= 'info';
    if (my $notify = self->_dispatcher->remove("continuous_notify")) {
        $notify->{icon_file} = '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/' .
            ($status_icon{$status} || 'ToolbarInfo.icns');
        self->_dispatcher->add($notify);
    }
    self->_dispatcher->$status($text);
}


1;

=head1 NAME

Test::Continuous::Notifier - Send notification to different targets.

=head1 SYNOPSIS

    Test::Continuous::Notifier->send_notify($msg, $status)

=head1 DESCRIPTION

This is used only internally.

=head1 METHODS

=over

=item send_notify($msg, [$status])

Must be called as a class method.

C<$msg> is required, and should contain trailing a C<\n> character in
case the output stream is not auto-flushing.

C<$status> is optional, and should be one of C<"info">, C<"warning">,
or C<"alert">. The default value is C<"info">.

=back

=cut
