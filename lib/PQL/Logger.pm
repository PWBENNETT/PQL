package PQL::Logger;

use 5.020;
use utf8;
no diagnostics;

use Carp qw( carp );
use Exporter qw( import );
use IO::All;

our $LOG_VERBOSITY;

our @EXPORT = qw( trace debug info warning error fatal );

BEGIN {
    my $e;
    eval "require Log::Log4perl" or do {
        $e = $@;
    };
    if ($e) {
        carp("Could not load Log4perl: $e -- continuing anyway (to STDOUT/STDERR)");
        *trace   = sub { return unless $LOG_VERBOSITY >= 0; say  (ref($_[0]) eq 'CODE' ? $_[0]->() : $_[0]) };
        *debug   = sub { return unless $LOG_VERBOSITY >= 1; say  (ref($_[0]) eq 'CODE' ? $_[0]->() : $_[0]) };
        *info    = sub { return unless $LOG_VERBOSITY >= 2; say  (ref($_[0]) eq 'CODE' ? $_[0]->() : $_[0]) };
        *warning = sub { return unless $LOG_VERBOSITY >= 3; warn((ref($_[0]) eq 'CODE' ? $_[0]->() : $_[0]) . "\n") };
        *error   = sub { return unless $LOG_VERBOSITY >= 4; warn((ref($_[0]) eq 'CODE' ? $_[0]->() : $_[0]) . "\n") };
        *fatal   = sub { warn((ref($_[0]) eq 'CODE' ? $_[0]->() : $_[0]) . "\n") };
    }
    else {
        my $log = Log::Log4perl->get_logger();
        *trace = sub { $log->trace(@_) };
        *debug = sub { $log->debug(@_) };
        *info = sub { $log->info(@_) };
        *warning = sub { $log->warn(@_) };
        *error = sub { $log->error(@_) };
        *fatal = sub { $log->fatal(@_) };
    }
};

1;
