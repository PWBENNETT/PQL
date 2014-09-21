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
    my (@source) = @_;
    return bless { source => \@source } => $class;
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
