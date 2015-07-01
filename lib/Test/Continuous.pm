use strict;
use warnings;

package Test::Continuous;

use 5.008;

our $VERSION = '0.75';

use File::Find;
use Cwd;
use Module::ExtractUse;
use List::MoreUtils qw(after before uniq);
use Test::Continuous::Formatter;
use File::ChangeNotify;
use Git::Repository;
use YAML;

my @prove_args;
my @tests;
my @changes;
my @not_files;
my @classes;

sub _classify_argv {
    if (@ARGV) {
        @not_files  = grep   { !-f $_ }     @ARGV;
        @tests      = grep   {  -f $_ }     @ARGV;
        @classes    = after  { $_ eq '::' } @not_files;
        @prove_args = before { $_ eq '::' } @not_files;
    }
}

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

sub _get_exclude_list {
    my $exclude_list = [
        qr/\.(bzr|
            cdv|
            dep|
            dot|
            nib|
            plst|
            git|
            hg|
            pc|
            svn|
            komodoproject|
            bak)$/x,

        qr/^(_MTN|
            blib|
            CVS|
            RCS|
            SCCS|
            _darcs|
            _sgbak|
            autom4te\.cache|
            cover_db|
            _build)$/x,

        qr(~$),
        qr/\.#.*$/,
        qr/^#.*#$/,
        qr/\..*\.swp$/,
        qr/^core\.\d+$/,
        qr/[.-]min\.js$/
    ];

    # Attempt to get the git directory Test::Continuous was run in
    my $path = getcwd;
    my $git_repo_top_level = Git::Repository->run( 'rev-parse', '--show-toplevel', {
        cwd => $path,
    });
    my ( $git_ignore, $git_dir );

    # If the git command came up with a git repo use it's .gitignore
    if ($git_repo_top_level) {
        $git_dir = $git_repo_top_level;
        $git_ignore = $git_repo_top_level."/.gitignore";
    # Otherwise use a .gitignore in the cwd
    } else {
        $git_dir = getcwd;
        $git_ignore = $git_dir.'.gitignore';
    }

    # If a .gitignore exists add its expanded contents to the exclude list
    if ( -e $git_ignore ) {
        # Git command found here: http://stackoverflow.com/a/467053/630490
        my @git_ignored_files = Git::Repository->run( 'ls-files', '-o', '-i', '--exclude-standard', {
            cwd => $git_dir,
        });
        # Prepend the git dir to get an absolute path
        @git_ignored_files = map { $git_dir.'/'.$_ } @git_ignored_files;
        @$exclude_list = ( @$exclude_list, @git_ignored_files );
    }

    return $exclude_list;
}

sub _match_against_excluded {
    my $element = shift;
    my $excluded = shift || _get_exclude_list();

    foreach ( @$excluded ) {
        return 1 if ref eq 'Regexp' and $element =~ $_;
        return 1 if $element eq $_;
    }
    return 0;
}

sub _run_once {
    my $build = shift;
    _classify_argv();
    my @tests = _tests_to_run;
    my @command_args = ( @prove_args, @tests, '::', @classes );

    print "\033[2J\033[0;0H"; #cls
    print "prove --norc " . join(" ", @command_args) . "\n";
    system(qw(prove --norc -v -m --formatter Test::Continuous::Formatter), @command_args);
}

sub _rebuild {
    return unless grep { $_ eq "-b" } @prove_args;

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
    _classify_argv();

    unless (@tests) {
        find sub {
            my $filename = $File::Find::name;
            return unless $filename =~ /\.t$/ && -f $filename;
            push @tests, $filename;
        }, getcwd;
    }

    print "[MSG] Will be continuously testing $_\n" for @tests;

    my $watcher = File::ChangeNotify->instantiate_watcher(
        directories => [ getcwd ],
        exclude => _get_exclude_list(),
    );

    @changes = ();
    _run_once(_rebuild([]));

    my $running = 0;
    while ( @changes = $watcher->wait_for_events() ) {
        my $excluded_files = _get_exclude_list();
        # Skip this file if it matches the exclude array
        my @included_changes = grep { not _match_against_excluded($_->path, $excluded_files) } @changes;
        if ( @included_changes ) {
           print "[MSG]:" .  $_->path . " was changed.\n" for @included_changes;
           _run_once( _rebuild(\@included_changes) );
           print "\n\n" . "-" x 60 ."\n\n";
           sleep 3;
        }
    }
}

1;

__END__

=head1 NAME

Test::Continuous - Run your test suite continuously when developing.

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

Copyright (c) 2008 - 2015 Kang-min Liu C<< <gugod@gugod.org> >>.

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
