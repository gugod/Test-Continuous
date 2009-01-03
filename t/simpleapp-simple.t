#!/usr/bin/env perl -w
use strict;
use lib 't';

use Test::More tests => 1;

use Test::Continuous;
use Test::Continuous::Formatter;

use Cwd qw(chdir);

our @notified;

require 'mock.pl';


{
    no warnings;
    sub Test::Continuous::_tests_to_run { ("t/simple.t") }
}

chdir("t/SimpleApp");

Test::Continuous::_run_once;

is_deeply(
    \@notified,
    [ "ALL PASSED\n" ]
);
