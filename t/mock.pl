our @notified;
{
    no strict;
    no warnings;

    sub Test::Continuous::Notifier::send_notify {
        my (undef, $msg) = @_;
        push @notified, $msg;
    }
}
1;
