use warnings;
use strict;
package Test::Continuous;

use 5.008;

our $VERSION = '0.0.1';

use Exporter::Lite;
use App::Prove;
use File::Find;
use Cwd;

our @EXPORT = qw(&runtests);
{
    no warnings;
    *{App::Prove::_exit} = sub {};
}

sub _run_once {
    my $prove = App::Prove->new;
    $prove->process_args(
        "--formatter" => "Test::Continuous::Formatter",
        "-m",
        "--norc", "--nocolor", "-Q", "-l", "t"
    );
    $prove->run;
}

my %files;
sub _changed {
    my $modified = 0;
    find sub {
        my $filename = $File::Find::name;
        return if $filename =~ /~$/;
        return if ! -f $filename;

        my $mtime = (stat($filename))[9];
        if (exists $files{$filename}) {
            if ( $files{$filename} < $mtime) {
                $modified = 1;
                print STDERR "[MSG] $filename is updated\n";
            }
        }
        else {
            $modified = 1;
        }
        $files{$filename} = $mtime;
    }, getcwd;
    return $modified;
}

sub runtests {
    while (1) {
        _run_once if _changed;
        sleep 5;
    }
}

1;

__END__

=head1 NAME

Test::Continuous - Run your tests suit continusouly when developing .

=head1 VERSION

This document describes Test::Continuous version 0.0.1

=head1 SYNOPSIS

    % cd MyModule/
    % perl -MTest::Continuous -e runtests

=head1 DESCRIPTION

<I>Continuous Testing</I> is a concept to re-run software tests
as soon as the developer saved the source code.


See also L<http://groups.csail.mit.edu/pag/continuoustesting/> for the
original implementation of Continuous Testing as a Eclipse plugin.

See also Zentest L<http://www.zenspider.com/ZSS/Products/ZenTest/> for
the same concept of implementation in Ruby's world.

=head1 INTERFACE

=over

=item runtests

This is the only function that you should be calling, directly
from command line:

    perl -MTest::Continuous -e runtests

It'll start monitoring the mtime of all files under current working
directy. If there's any update, it'll run your module test under t/
directory with L<App::Prove>.

Test result are displayed on terminal. Also dispatched to Growl if
C<Log::Dispatch::MacGrowl> is installed. Big plus for perl programmers
on Mac.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Test::Continuous requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<App::Prove>, L<Log::Dispatcher>, L<Log::Dispatch::MacGrowl>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-continuous@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Kang-min Liu C<< <gugod@gugod.org> >>. All rights reserved.

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
