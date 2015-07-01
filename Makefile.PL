use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Test/Continuous.pm';

abstract 'Run your test suite continuously when developing.';

repository 'git://github.com/gugod/Test-Continuous.git';

tests 't/*.t';
author_tests 'xt/*.t';

install_script 'bin/autoprove';

cpanfile;
WriteAll;
