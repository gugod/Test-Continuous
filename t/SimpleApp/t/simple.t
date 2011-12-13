use lib 'lib';
use lib 't/lib';
use lib 't/SimpleApp/lib';

use Test::More tests => 1;
use SimpleApp;

is SimpleApp::simple(), 'simple';
