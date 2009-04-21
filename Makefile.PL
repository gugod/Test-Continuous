use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Test/Continuous.pm';

abstract 'Run your tests suite continusouly when developing.';

build_requires  'Test::More'        => '0.42';

requires(
    "Exporter::Lite"     => 0.02,
    "File::Modified"     => 0.07,
    "File::Spec"         => 3.29,
    "File::Temp"         => 0.21,
    "List::MoreUtils"    => 0.22,
    "Log::Dispatch"      => 2.22,
    "Module::ExtractUse" => 0.23,
    "TAP::Harness"       => 3.16,
    "self"               => 0.32,
);

features(
    'Graphical notifications' => [
        -default => 1,
        "Log::Dispatch::DesktopNotification" => 0
    ]
);

tests 't/*.t';
author_tests 'xt/*.t';

auto_install;

WriteAll;


