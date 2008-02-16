package Test::Continuously::Formatter;
use base 'TAP::Formatter::Console';

use Mac::Growl ':all';
use IO::String;

sub summary {
    my ( $self, $aggregate ) = @_;

    my $str;
    my $io = IO::String->new($str);
    $self->stdout($io);

    $self->SUPER::summary($aggregate);

    RegisterNotifications(
        "Test::Continuously",
        ["TestResult"],
        ["TestResult"]
    );

    $str =~ s/^\s*//s;
    $str =~ s/\s*$//s;
    my @lines = split(/\n/, $str);
    shift @lines; shift @lines;

    for (split(/\n(?!  )/, join("\n", @lines) )) {
        s/ +/ /gs;
        PostNotification(
            "Test::Continuously",
            "TestResult",
            "Test Summary Report",
            $_,
        );
    }
}

1;
