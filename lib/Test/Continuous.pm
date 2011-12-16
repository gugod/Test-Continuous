use strict;
use warnings;

package Test::Continuous;

use 5.008;

our $VERSION = '0.71';

use App::Prove;
use File::Find;
use Cwd;
use Module::ExtractUse;
use List::MoreUtils qw(uniq);
use Test::Continuous::Formatter;
use File::ChangeNotify;

{
    no warnings;
    *{App::Prove::_exit} = sub {};
}

my @prove_args;
my @tests;
my @changes;
my @files;

sub _tests_to_run {
    my %dep;

    my $p = Module::ExtractUse->new;
    for my $t ( @tests ) {
        $p->extract_use($t);
        for my $used ($p->array) {
            next unless $used =~ s{::}{/}g;
            $used .= ".pm";
            push @{$dep{$used}||=[]}, $t;
        }
    }

    my $cwd = getcwd . "/";
    my @tests_to_run = map {
        s/^$cwd//; $_;
    } uniq sort map {
        if (/\.t$/) {
            $_;
        }
        else {
            my $changed = $_;
            map { @{$dep{$_}} } grep { index($changed, $_) >= 0 } keys %dep;
        }
    } map {
        $_->path;
    } @changes;

    return @tests if @tests_to_run == 0;

    return @tests_to_run;
}

sub _run_once {
    my $build = shift;

    my @tests = _tests_to_run;

    my $prove = App::Prove->new;
    $prove->process_args(
        "-m",
        $build ? "-b" : "-l",
        "--norc",
        @prove_args,
        @tests
    );
    $prove->formatter("Test::Continuous::Formatter");
    $prove->verbose(1);
    $prove->merge(1);
    $prove->run;
}

sub _rebuild {
    my %build;
    if ( -e "Build.PL" ) {
        $build{cmd} = './Build';
        $build{config} = 'Build.PL';
    }
    elsif ( -e "Makefile.PL" ) {
        $build{cmd} = 'make';
        $build{config} = 'Makefile.PL';
    }

    return unless $build{cmd};

    my $changes = shift;

    # Rerun the config file if it changed or hasn't been run
    if ( !-e $build{cmd} or grep { $_ eq $build{config} } @$changes) {
        my $cmd = "$^X $build{config}";
        system $cmd;
        die "$cmd exited with non-zero" unless $? == 0;
    }

    system $build{cmd};
    die "$build{cmd} exited with non-zero" unless $? == 0;

    return 1;
}

sub runtests {
    if (@ARGV) {
        # print "ARGV: " . join ",",@ARGV, "\n";
        while ($ARGV[-1] && -f $ARGV[-1]) {
            push @tests, pop @ARGV;
        }
        @prove_args = @ARGV;
    }

    unless (@tests) {
        find sub {
            my $filename = $File::Find::name;
            return unless $filename =~ /\.t$/ && -f $filename;
            push @tests, $filename;
        }, getcwd;
    }

    print "[MSG] Will be continuously testing $_\n" for @tests;

    # Watch all files excpet for:
    # - vim / Emacs temp files,
    # - git / svn repositoy
    my $watcher = File::ChangeNotify->instantiate_watcher(
        directories => [ getcwd ],
        exclude => [qr/\.(git|svn)/, qr(~$), qr(\.#.*$), qr/\..*\.swp$/]
    );

    my $run = 1;
    while ( @changes = $watcher->wait_for_events() ) {
        if ($run) {
            print "[MSG]:" .  $_->path . " was changed.\n" for @changes;
            _run_once( _rebuild(\@changes) );
            print "\n\n" . "-" x 60 ."\n\n";
        }
        $run = 1-$run;
    }
}

1;

__END__

=head1 NAME

Test::Continuous - Run your test suite continuously when developing.

=head1 VERSION

This document describes Test::Continuous version 0.68

=head1 SYNOPSIS

Very simple usage:

    % cd MyModule/
    % autoprove

You may pass prove arguments:

    % autoprove --shuffle

=head1 DESCRIPTION

I<Continuous Testing> is a concept and tool to re-run software tests
as soon as the developer saves the source code.

C<Test::Continuous> is a tool based on L<App::Prove> that implements
this concept for Perl.

See L<http://groups.csail.mit.edu/pag/continuoustesting/> for the
original implementation of Continuous Testing as an Eclipse plugin.
See also Zentest L<http://www.zenspider.com/ZSS/Products/ZenTest/> for
the same concept implemented in Ruby's world.

=head1 INTERFACE

=over

=item runtests

This function starts monitoring the mtime of all files under current
working directory. If there's any update, it runs your module tests
under t/ directory with L<App::Prove>.

You could call it from command line like this:

    perl -MTest::Continuous -e Test::Continuous::runtests

However, it's recommended to use the L<autoprove> program shipped with
this distribution to do this instead.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Test::Continuous requires no configuration files or environment variables.

Your C<.proverc> is NOT loaded, even though it's based on L<App::Prove>.

=head1 DEPENDENCIES

L<App::Prove>, L<Log::Dispatch>, L<Log::Dispatch::DesktopNotification>,
L<Module::ExtractUse>

=head1 INCOMPATIBILITIES

It might not be compatible with all Test::Harness::* classes. Testing with
remote harness classes basically works, but has some glitches. Help is
appreciated.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-test-continuous@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008,2009,2010,2011 Kang-min Liu C<< <gugod@gugod.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
