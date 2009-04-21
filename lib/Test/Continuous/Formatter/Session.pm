package Test::Continuous::Formatter::Session;
use strict;
use TAP::Formatter::File::Session;

use vars qw($VERSION @ISA);

@ISA = qw(TAP::Formatter::File::Session);

# use self;

# sub result {
#     my ($result) = @args;

#     my $parser    = $self->parser;
#     my $formatter = $self->formatter;

#     if ( $result->is_bailout ) {
#         $formatter->_failure_output(
#                 "Bailout called.  Further testing stopped:  "
#               . $result->explanation
#               . "\n" );
#         return;
#     }

#     if (!$formatter->quiet
#         && (   ( $formatter->verbose && !$formatter->failures )
#             || ( $result->is_test && $formatter->failures && !$result->is_ok )
#             || ( $result->has_directive && $formatter->directives ) )
#       )
#     {
#         $self->{results} .= $result->as_string . "\n";
#     }
# }

# sub close_test {
#     my ($self, @args) = @_;
#     $self->SUPER::close_test(@args);
#     $self->formatter->{__tc_output} = "";
# }

1;
