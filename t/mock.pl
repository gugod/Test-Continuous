use FindBin;
use File::Temp qw(tempfile);
use YAML;

$ENV{PERL5LIB} = join(":", $FindBin::Bin."/lib", $FindBin::Bin."/../lib", $ENV{PERL5LIB});

$ENV{PERL_TEST_CONTINUOUS_TEST_NOTIFY_OUTPUT} = "/tmp/tcnotification$$";

{
    open my $fh, ">", $ENV{PERL_TEST_CONTINUOUS_TEST_NOTIFY_OUTPUT};
    close $fh;
}

sub read_notifications {
    YAML::LoadFile($ENV{PERL_TEST_CONTINUOUS_TEST_NOTIFY_OUTPUT});
}

1;
