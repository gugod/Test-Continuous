#!/usr/bin/env perl -w
use strict;
use lib 't';
require 'mock.pl';

use Test::More tests => 1;
use Test::Continuous;

use Cwd qw(chdir);

require 'mock.pl';


@ARGV = ( 't/simple.t', 'include' );

chdir("t/SimpleApp");

Test::Continuous::_run_once;

my @notified = read_notifications();

is_deeply(
    \@notified,
    [ "ALL PASSED\n", 'include/include-me.t:
# Yay! I feel included! \(^.^)/' ]
, 'directories and files can be passed as file arguments');
