#!/usr/bin/env perl -w
use strict;
use lib 't';
require 'mock.pl';

use Test::More tests => 17;
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

@ARGV = ();
$ENV{AUTOPROVE_OPTS} = '--autoprove-skip-initial --autoprove-bogus';
throws_ok {Test::Continuous::runtests()} qr/Unknown option/,
    'Good + Bad AUTOPROVE_OPTS Option dies';

@ARGV = ('--autoprove-skip-initial', '--autoprove-bogus');
undef($ENV{AUTOPROVE_OPTS});
throws_ok {Test::Continuous::runtests()} qr/Unknown option/,
    'Good + Bad Command Line Option dies';

@ARGV = ();
$ENV{AUTOPROVE_OPTS} = '--autoprove-skip-initial-bogus';
throws_ok {Test::Continuous::runtests()} qr/Unknown option/,
    'Bad AUTOPROVE_OPTS option dies';

@ARGV = ('--autoprove-skip-initial-bogus');
undef($ENV{AUTOPROVE_OPTS});
throws_ok {Test::Continuous::runtests()} qr/Unknown option/,
    'Bad AUTOPROVE_OPTS option dies';

@ARGV = ();
undef($ENV{AUTOPROVE_OPTS});
lives_ok {Test::Continuous::runtests()} 'Undef AUTOPROVE_OPTS and empty ARGV works';

@ARGV = ();
$ENV{AUTOPROVE_OPTS} = '--autoprove-skip-initial';
lives_ok {Test::Continuous::runtests()} '--autoprove-skip-initial AUTOPROVE_OPTS works';

@ARGV = ('--autoprove-skip-initial');
undef($ENV{AUTOPROVE_OPTS});
lives_ok {Test::Continuous::runtests()} '--autoprove-skip-initial ARGV works';

@ARGV = ('--autoprove-skip-initial');
$ENV{AUTOPROVE_OPTS} = '--autoprove-skip-initial';
lives_ok {Test::Continuous::runtests()} '--autoprove-skip-initial AUTOPROVE_OPTS and ARGV works';

# Case insensitivity test
@ARGV = ();
$ENV{AUTOPROVE_OPTS} = '--autoPROVE-sKIp-INitial';
lives_ok {Test::Continuous::runtests()} 'Case insensitive --autoprove-skip-initial AUTOPROVE_OPTS works';

# Case insensitivity test
@ARGV = ('--autoPROVE-sKIp-iNitial');
undef($ENV{AUTOPROVE_OPTS});
lives_ok {Test::Continuous::runtests()} 'Case insensitive --autoprove-skip-initial ARGV works';

# Run initial tests with no ENV/ARGV
@ARGV = ();
undef($ENV{AUTOPROVE_OPTS}); # Make sure this isn't set to anything
$count=0; # reset count of how many times _run_once() is called
Test::Continuous::runtests();
#
# We should call _run_once() for the initial tests when runtests()
# starts.
is(
    $count,
    1,
    '_run_once() properly called once when not skipping initial tests'
);

# Run initial tests with no ENV and with --shuffle ARGV
@ARGV = ('--shuffle');
undef($ENV{AUTOPROVE_OPTS}); # Make sure this isn't set to anything
$count=0; # reset count of how many times _run_once() is called
Test::Continuous::runtests();
#
# We should call _run_once() for the initial tests when runtests()
# starts.
is(
    $count,
    1,
    '--shuffle handled okay in ARGV'
);

# Run initial tests with no ARGV and with --shuffle ENV
@ARGV = ();
$ENV{AUTOPROVE_OPTS} = '--shuffle';
$count=0; # reset count of how many times _run_once() is called
Test::Continuous::runtests();
#
# We should call _run_once() for the initial tests when runtests()
# starts.
is(
    $count,
    1,
    '--shuffle handled okay in ENV'
);

# Skip tests via ENV
@ARGV = ();
$ENV{AUTOPROVE_OPTS} = '--autoprove-skip-initial';
$count = 0;  # Stores how many times _run_once runs
Test::Continuous::runtests();
#
# We should NOT call _run_once() for the initial tests when runtests()
# starts, and we exit before we call it for changes.
is(
    $count,
    0,
    'Initial tests not run when skipping initial tests in ENV'
);

# Skip tests via ARGV
@ARGV = ('--autoprove-skip-initial');
undef($ENV{AUTOPROVE_OPTS});
$count = 0;  # Stores how many times _run_once runs
Test::Continuous::runtests();
#
# We should NOT call _run_once() for the initial tests when runtests()
# starts, and we exit before we call it for changes.
is(
    $count,
    0,
    'Initial tests not run when skipping initial tests in ARGV'
);

# ARGV overrides ENV, no-skip
@ARGV = ('--autoprove-no-skip-initial');
$ENV{AUTOPROVE_OPTS} = '--autoprove-skip-initial';
$count = 0;  # Stores how many times _run_once runs
Test::Continuous::runtests();
#
# We should NOT call _run_once() for the initial tests when runtests()
# starts, and we exit before we call it for changes.
is(
    $count,
    1,
    'Initial tests run when not skipping initial tests in ARGV overriding ENV'
);

# ARGV overrides ENV, skip
@ARGV = ('--autoprove-skip-initial');
$ENV{AUTOPROVE_OPTS} = '--autoprove-no-skip-initial';
$count=0; # reset count of how many times _run_once() is called
Test::Continuous::runtests();
#
# We should call _run_once() for the initial tests when runtests()
# starts.
is(
    $count,
    0,
    'Initial tests not run when skipping initial tests in ARGV overriding ENV'
);
