package Bar;
use base 'Test::Class';
use Test::More;
sub addition : Tests { is 1 + 1, 2, '1 + 1 is 2' }
1;
