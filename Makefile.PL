use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Test/Continuous.pm';

build_requires  'Test::More'        => '0.42';

requires
    "TAP::Harness" => "3.09",
    "App::Prove" => "3.09",
    "Log::Dispatch" => 0;

features(
    'Notify with Growl' => [
        -default => 1,
        requires("Log::Dispatch::MacGrowl" => 0)
    ]
);

auto_install;

WriteAll;


