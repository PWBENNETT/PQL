package PQL;

use 5.020;
use utf8;
no diagnostics;

use Carp qw( confess );
use DBI;
use PQL::Logger;

require PQL::columnset;
require PQL::rowset;
require PQL::student;

sub connect {
    my $class = shift;
    my %args
        = (@_ == 1 and ref($_[0]) =~ /^DBI::db/o) ? (dbh => $_[0])
        : (@_ >= 3) ? (dbh => DBI->connect(@_))
        : ref($_[0]) ? %{%_[0]}
        : @_
        ;
    return bless \%args => ref($class)||$class;
}

sub study {
    my $self = shift;
    $self->{ plan_stats } = PQL::student->study($self->{ plan });
    return $self;
}

sub optimize {
    ...
}

sub explain {
    my $self = shift;
    my %args;
    if (@_ == 1 and not ref $_[0]) {
        $args{ $_[0] } = 1;
    }
    elsif (ref $_[0]) {
        %args = %{$_[0]};
    }
    else {
        %args = @_;
    }
    my %missing;
    eval "require Tree::DAG_Node" or $missing{'Tree::DAG_Node'} = $@;
    eval "require Text::Table" or $missing{'Text::Table'} = $@;
    eval "require Number::Format" or $missing{'Number::Format'} = $@;
    if (keys %missing) {
        confess(
            "The following modules are needed to explain() a plan, but could not be loaded:\n"
            . join('', map { '  ' . $_ . ': ' . $missing{ $_ } } keys %missing)
        );
    }
    ...
}

sub tow_graph {
    my $self = shift;
    eval "require GraphViz2" or confess("The GraphViz2 module is needed to tow_graph() a query, but it could not be loaded: $@");
    ...
}

sub tow_svg {
    eval "require Image::LibRSVG" or confess("The Image::LibRSVG module is needed to tow_svg() a query, but it could not be loaded: $@");
    ...
}

sub render {
    my $self = shift;
    my ($dialect) = @_;
    $dialect ||= $self->{ dialect } || 'SQL:2011';
    my %missing;
    eval "require SQL::Abstract" or $missing{'SQL::Abstract'} = $@;
    eval "require SQL::Translator" or $missing{'SQL::Translator'} = $@;
    if (keys %missing) {
        confess(
            "The following modules are needed to render() a query as SQL, but could not be loaded:\n"
            . join('', map { '  ' . $_ . ': ' . $missing{ $_ } } keys %missing)
        );
    }
    ...
}

sub execute {
    my $self = shift;
    my ($sql, $binds) = $self->render();
    my $sth = $self->{ dbh }->prepare($sql);
    unless ($binds) {
        $sth->execute();
        return $sth;
    }
    if (ref $binds eq 'ARRAY') {
        $sth->execute(@$binds);
        return $sth;
    }
    for my $k (keys %$binds) {
        my $bound = $binds->{ $k };
        if (ref $bound) {
            $sth->bind_param_inout(":$k" => $bound);
        }
        else {
            $sth->bind_param(":$k" => $bound);
        }
    }
    $sth->execute();
    return $sth;
}

1;
