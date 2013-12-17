use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Test/Continuous.pm';

abstract 'Run your test suite continuously when developing.';

repository 'git://github.com/gugod/Test-Continuous.git';

build_requires  'Test::More'        => '0.42';

requires(
    "App::Prove"         => 3.23,
    "File::Spec"         => 3.29,
    "File::Temp"         => 0.21,
    "List::MoreUtils"    => 0.22,
    "Log::Dispatch"      => 2.22,
    "Module::ExtractUse" => 0.23,
    "TAP::Harness"       => 3.16,
    "File::ChangeNotify" => 0.12
);

test_requires YAML => 0.77;

features(
    'Graphical notifications' => [
        -default => 1,
        "Log::Dispatch::DesktopNotification" => 0
    ]
);

tests 't/*.t';
author_tests 'xt/*.t';

auto_install;
install_script 'bin/autoprove';

WriteAll;
