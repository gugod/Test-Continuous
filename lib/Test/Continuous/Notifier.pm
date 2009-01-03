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

my %status_icon = (
    'alert'   => 'AlertCautionIcon.icns',
    'warning' => 'AlertStopIcon.icns',
    'info'    => 'ToolbarInfo.icns',
);

sub send_notify {
    my ($text, $status) = args;
    $status ||= 'info';
    if (my $growl = self->_dispatcher->remove("growl")) {
        $growl->{icon_file} = '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/' .
            ($status_icon{$status} || 'ToolbarInfo.icns');
        self->_dispatcher->add($growl);
    }
    self->_dispatcher->notice($text);
}


1;
