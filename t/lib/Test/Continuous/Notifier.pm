package Test::Continuous::Notifier;
use YAML;

sub send_notify {
    my (undef, $msg) = @_;

    open my $fh, ">>", $ENV{PERL_TEST_CONTINUOUS_TEST_NOTIFY_OUTPUT}
        or die "Fail storing notification: $!";

    print $fh YAML::Dump($msg);

    close($fh);
}

1;

