package Foo;
use base 'Test::Class';
use Test::More;
sub concatination : Tests { is 'foo' . 'bar', 'foobar', '"foo" . "bar" is "foobar"' }
1;
