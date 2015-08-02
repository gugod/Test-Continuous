#!/usr/bin/env perl -w
use strict;
use lib 't';
require 'mock.pl';

use Test::More tests => 7;
use Test::Exception;
use Test::Continuous;

use Cwd qw(chdir);

package null_wait_for_events;
# This package defines a replacement used in place for
# File::ChangeNotify that always returns undef on wait_for_events(), so
# that the tests done on changes are never done in
# Test::Continuous::runtests() (we don't want to loop forever there).
sub new {
    my $class = {};
    bless($class);
    return $class;
}
sub wait_for_events {
    return (); # So this exits runtests()
}


package main;

my $count = 0;  # Stores how many times _run_once runs

{
    no warnings 'redefine';  # We're redefining functions
    
    # We change the constructor to point at our null class
    sub File::ChangeNotify::instantiate_watcher { return null_wait_for_events->new(); }

    # We don't actually do any tests anymore, but we keep count of how
    # many times this is called.
    sub Test::Continuous::_run_once { $count++; }
};


chdir("t/SimpleApp");

$ENV{TEST_CONTINUOUS} = 'SKIP_INITIAL,BOGUS';
throws_ok {Test::Continuous::runtests()} qr/Unknown option/,
    'Good + Bad TEST_CONTINUOUS Option dies';

$ENV{TEST_CONTINUOUS} = 'SKIP_INITIAL_BOGUS';
throws_ok {Test::Continuous::runtests()} qr/Unknown option/,
    'Bad TEST_CONTINUOUS option dies';

undef($ENV{TEST_CONTINUOUS});
lives_ok {Test::Continuous::runtests()} 'Undef TEST_CONTINUOUS works';

$ENV{TEST_CONTINUOUS} = 'SKIP_INITIAL';
lives_ok {Test::Continuous::runtests()} 'SKIP_INITIAL TEST_CONTINUOUS works';

# Case insensitivity test
$ENV{TEST_CONTINUOUS} = 'skip_initial';
lives_ok {Test::Continuous::runtests()} 'skip_initial TEST_CONTINUOUS works';

undef($ENV{TEST_CONTINUOUS}); # Make sure this isn't set to anything
$count=0; # reset count of how many times _run_once() is called

Test::Continuous::runtests();

# We should call _run_once() for the initial tests when runtests()
# starts.
is(
    $count,
    1,
    '_run_once() properly called once when not skipping initial tests'
);


$ENV{TEST_CONTINUOUS} = 'SKIP_INITIAL';
$count = 0;  # Stores how many times _run_once runs

Test::Continuous::runtests();

# We should NOT call _run_once() for the initial tests when runtests()
# starts, and we exit before we call it for changes.
is(
    $count,
    0,
    '_run_once() not called for initial tests when skipping initial tests'
);
