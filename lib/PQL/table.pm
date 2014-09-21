package PQL::table;

use 5.020;
use utf8;
no diagnostics;

use PQL::Logger;

require PQL;
require PQL::criteria;
require PQL::resultset;
require PQL::rowset;
require PQL::student;

use overload (
    '""' => 'render',
    '%{}' => 'select',
    '&{}' => 'project',
    '@{}' => sub { fatal('wat') },
);

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my ($dbh, @tables) = @_;
    my %symtab;
    for my $t (@tables) {
        my $k = ref($t) ? ($t->name) : $t;
        my @ins = map { lc substr($_, 0, 1) } grep { $_ } split /_/, $k;
        @ins = (qw( a )) unless @ins;
        for my $i (map { $ins[ 0 .. $_ ] } (0 .. $#ins)) {
            next if $symtab{ $i };
            $symtab{ $i } = $t;
            @ins = ();
            last;
        }
        last unless @ins;
        my $abbn = join('', @ins) . 'a';
        while (1) {
            next if $symtab{ $abbn }++;
            last;
        }
    }
    return bless {
        dbh => $dbh,
        name => join('_', keys %symtab),
        symtab => \%symtab,
        innards => \@tables,
    } => $class;
}

sub select {
    my $self = shift;
    ...
}

sub project {
    my $self = shift;
    ...
}

sub rename {
    my $self = shift;
    ...
}

sub extend {
    my $self = shift;
    return $self->rename(@_);
}

sub render {
    my $self = shift;
    return join(' ', map { "$_" } @{$self->{ source }});
}

1;
