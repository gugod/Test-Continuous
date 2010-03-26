use strict;
use warnings;

package Test::Continuous::Formatter;
use base 'TAP::Formatter::Base';
use Test::Continuous::Notifier;
use Test::Continuous::Formatter::Session;
use self;

use 5.008;

our $VERSION = "0.0.2";

sub open_test {
    my ($test, $parser ) = @args;

    my $session = Test::Continuous::Formatter::Session->new(
        {
            name      => $test,
            formatter => $self,
            parser    => $parser
        }
    );

    $self->{__tc_output} = "";

    $session->header;

    return $session;
}

sub summary {
    my ($aggregate) = @args;

    my $summary;
    my $non_zero_exit_status = 0;

    if ($aggregate->all_passed) {
        $summary = "ALL PASSED\n";
    }
    else {
        local $, = ",";
        my $total  = $aggregate->total;
        my $passed = $aggregate->passed;
        $summary = "${total} planned, only ${passed} passed.\n";

        my @t = $aggregate->descriptions;
        for my $t (@t) {
            $t =~ /(t\/.*$)/;
            my $tfile = $1;
            my ($parser) = $aggregate->parsers($t);
            if (my @r = $parser->failed()) {
                $summary .= "Failed test(s) in $tfile: @r\n";
            }

            if ( my $exit = $parser->exit ) {
                $summary .= "  Non-zero exit status: $tfile\n";
                $non_zero_exit_status = 1;
            }
        }
    }

    for (split(/\n(?!  )/, $summary )) {
        s/ +/ /gs;
        Test::Continuous::Notifier->send_notify(
            "$_\n",
            $non_zero_exit_status ? 'alert' : $aggregate->all_passed ? 'info' : 'warning'
        );
    }

    $self->_analyze_test_output;
}

sub _output {
    my $out  = join('', @args);
    $self->{__tc_output} .= "$out\n";
}

sub _analyze_test_output {
    my(@comment, @warning);

    my $output = $self->{__tc_output};

    return if $output =~ /^\s+$/s;

    my @lines = split(/\n\s*/, $output);
    my $description = shift @lines;

    $description =~ m/^(.+)\s\.\./g;
    my $test_file = $1;

    my $parser = TAP::Parser->new({
        tap => join("\n", @lines)
    });

    while (my $result = $parser->next) {

        if ( $result->is_unknown ) {
            my $str = $result->as_string;
            push @warning, $str
                unless $str =~ /^(Dubious|Failed|\s*$)/;
        }
        elsif ( $result->is_comment ) {
            push @comment, $result->as_string;
        }
    }

    if (@warning) {
        Test::Continuous::Notifier->send_notify(
            join("\n", "$test_file:", @warning),
            "warning"
        );
    }
    if (@comment) {
        Test::Continuous::Notifier->send_notify(
            join("\n", "$test_file:",@comment)
        );
    }
}

1;

__END__

=head1 NAME

Test::Continuous::Formatter - TAP Formatter for Test::Continuous

=head1 SYNOPSIS

You shouldn't use this module directly.

=head1 DESCRIPTION

This package inherits from L<TAP::Formatter::Console>, and dispatch
test summary to different output channels.

=over

=item summary

Overrides the C<summary> method from parent. Send a processed output
to a C<Log::Dispatcher> object.

=back

=cut

