use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Test/Continuous.pm';

abstract 'Run your tests suite continusouly when developing.';

build_requires  'Test::More'        => '0.42';

requires
    "IO::String" => 0,
    "Module::ExtractUse" => 0,
    "File::Modified" => 0,
    "TAP::Harness" => "3.09",
    "App::Prove" => "3.09",
    "Log::Dispatch" => 0;

features(
    'Notify with Growl' => [
        -default => ($^O eq 'darwin') ,
        requires("Log::Dispatch::MacGrowl" => 0)
    ]
);

auto_install;

WriteAll;


