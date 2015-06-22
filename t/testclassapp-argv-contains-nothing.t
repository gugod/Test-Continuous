#!/usr/bin/env perl -w
use strict;
use lib 't';
use Test::More tests => 3;
require 'mock.pl';

use Test::Continuous;
use Test::Continuous::Notifier;

use Cwd 'chdir';

chdir('t/TestClassApp');

{
    local @ARGV = qw();

    Test::Continuous::_run_once;

    my @notifications = read_notifications();

    like $notifications[0], qr/ALL PASSED/,          'tests pass';
    like $notifications[1], qr/Bar\->addition/,      'Bar tests run';
    like $notifications[1], qr/Foo\->concatination/, 'Foo tests run';
}
