package Test::Continuously::Formatter;
use base 'TAP::Formatter::Console';

use IO::String;
use self;
use Log::Dispatch;
use Log::Dispatch::Screen;

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
                    app_name => "Test::Continuously",
                    title => "Test Report",
                    icon_file => '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns',
                    sticky => 0,
                ));
        };

        return $dispatcher;
    }
}

sub _send_notify {
    self->_dispatcher->notice(message => args[0]);
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

    print "\n" . "-" x 45 . "\n";
    for (split(/\n(?!  )/, join("\n", @lines) )) {
        s/ +/ /gs;
        self->_send_notify("$_\n");
    }
}

1;
