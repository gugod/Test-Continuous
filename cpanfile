
requires "App::Prove"         => 3.23;
requires "File::Spec"         => 3.29;
requires "File::Temp"         => 0.21;
requires "List::MoreUtils"    => 0.22;
requires "Log::Dispatch"      => 2.22;
requires "Module::ExtractUse" => 0.23;
requires "TAP::Harness"       => 3.16;
requires "File::ChangeNotify" => 0.12;
requires "Git::Repository"    => 0;
requires "Test::More"         => 0.42;

on test => sub {
    requires "YAML"            => 0.77;
    requires "Test::Class"     => 0.50;
    requires "Test::Exception" => 0.40;
};

feature 'notify', 'Graphical notifications' => sub {
    recommends "Log::Dispatch::DesktopNotification" => 0;
};
