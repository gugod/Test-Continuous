#!/usr/bin/env perl -w
use strict;
use lib 't';

use Test::More tests => 1;

use Test::Continuous;

use Cwd qw(chdir);

our @notified;
{
    no warnings;
    sub Test::Continuous::_tests_to_run { ("t/dubious.t") }
};

require 'mock.pl';

chdir("t/SimpleApp");

Test::Continuous::_run_once;

is_deeply(
    \@notified,
    [
        "0 planned, only 0 passed.\n Non-zero exit status: t/dubious.t\n",
        "t/dubious.t:\nCan't find string terminator \"'\" anywhere before EOF at t/dubious.t line 7.",
        "t/dubious.t:\n# Looks like your test exited with 255 before it could output anything.",
    ]
);
