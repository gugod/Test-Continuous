use Test::Class::Load 't/lib';
undef($ENV{AUTOPROVE_OPTS}); # In case it's set.
Test::Class->runtests(@ARGV);
