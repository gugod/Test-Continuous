use lib 'lib';
use lib 't/lib';
use lib 't/SimpleApp/lib';

use Test::More;
use SimpleApp;

plan tests => 1;

is SimpleApp::simple(), 'simple';
