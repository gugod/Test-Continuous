use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Test/Continuous.pm';

abstract 'Run your tests suite continusouly when developing.';

build_requires  'Test::More'        => '0.42';

requires(
    "App::Prove"         => "3.09",
    "Archive::Tar"       => 0,
    "File::Modified"     => 0,
    "File::Spec"         => 0,
    "File::Spec"         => 0,
    "File::Temp"         => 0,
    "IO::File"           => 0,
    "Log::Dispatch"      => 0,
    "Module::ExtractUse" => 0,
    "TAP::Harness"       => "3.09",
    "TAP::Parser"        => 0,
);

features(
    'Notify with Growl' => [
        -default => ($^O eq 'darwin'),
        "Log::Dispatch::MacGrowl" => 0
    ]
);

auto_install;

WriteAll;


