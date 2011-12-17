use FindBin;
use File::Temp;
use YAML;

$ENV{PERL5LIB} = join(":", $FindBin::Bin."/lib", $FindBin::Bin."/../lib", $ENV{PERL5LIB});

my $temp = File::Temp->new;
$temp->unlink_on_destroy(0);

$ENV{PERL_TEST_CONTINUOUS_TEST_NOTIFY_OUTPUT} = $temp->filename;

sub read_notifications {
    YAML::LoadFile($ENV{PERL_TEST_CONTINUOUS_TEST_NOTIFY_OUTPUT});
}

1;
