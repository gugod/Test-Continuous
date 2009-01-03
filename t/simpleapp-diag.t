#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Test::Continuous;
use Test::Continuous::Formatter;

my @notified = ();
{
    no strict;
    no warnings;

    sub Test::Continuous::_tests_to_run { ("t/diag.t") }

    sub Test::Continuous::Formatter::_send_notify {
        my ($self, $msg) = @_;
        push @notified, $msg;

    }
}


use Cwd qw(chdir);

chdir("t/SimpleApp");
Test::Continuous::_run_once;

is_deeply(
    \@notified,
    [
        "ALL PASSED\n",
        "t/diag.t: # Send a diag message",
    ]
);

