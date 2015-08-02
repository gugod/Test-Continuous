use Test::Class::Load 't/lib';
undef($ENV{TEST_CONTINUOUS}); # In case it's set.
Test::Class->runtests(@ARGV);
