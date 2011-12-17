#!/usr/bin/env perl -w
use strict;
use lib 't';
require 'mock.pl';

use Test::More tests => 1;
use Test::Continuous;

use Cwd qw(chdir);

require 'mock.pl';


{
    no warnings;
    sub Test::Continuous::_tests_to_run { ("t/simple.t") }
}

chdir("t/SimpleApp");

Test::Continuous::_run_once;

my @notified = read_notifications();

is_deeply(
    \@notified,
    [ "ALL PASSED\n" ]
);
