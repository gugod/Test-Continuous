#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Test::Continuous;
use Test::Continuous::Formatter;

use Cwd qw(chdir);

{
    no strict;
    no warnings;
    sub Test::Continuous::Formatter::_send_notify {
        my ($self, $notice) = @_;
        like $notice, qr/ALL PASSED/;
    }
}

chdir("t/SimpleApp");

@Test::Continuous::tests = ("t/simple.t");

Test::Continuous::_run_once;
