package PQL;

use 5.020;
use utf8;
no diagnostics;

use DBI;
use PQL::Logger;

require PQL::columnset;
require PQL::criteria;
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
    return $self if ($self->{ plan_stats }->{ last_updated } || 0) >= ($self->{ plan }->{ last_updated } || time);
    $self->{ plan_stats } = PQL::student->study($self->{ plan });
    $self->{ study_time } = time;
    return $self;
}

sub optimize {
    my $self = shift;
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
    _i_need(qw(
        Tree::DAG_Node
        Text::Table
        Number::Format
    ));
    ...
}

sub tow_graph {
    my $self = shift;
    _i_need(qw(
        GraphViz2
        Number::Format
    ));
    ...
}

sub tow_svg {
    my $self = shift;
    _i_need(qw(
        Image::LibRSVG
        GraphViz2
        Number::Format
    ));
    my $gv = $self->tow_graph(@_);
    ...
}

sub render {
    my $self = shift;
    my ($dialect) = @_;
    $dialect ||= $self->{ dialect } || 'SQL:2011';
    _i_need(qw(
        SQL::Abstract
        SQL::Translator
    ));
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
            my $name = (':')x!($k =~ /^:/o) . $k;
            $sth->bind_param_inout($name => $bound);
        }
        else {
            my $name = (':')x!($k =~ /^:/o) . $k;
            $sth->bind_param($name => $bound);
        }
    }
    $sth->execute();
    return $sth;
}

sub _i_need {
    my @reqs = @_;
    my (undef, undef, undef, $caller) = caller(1);
    my %missing;
    for my $req (@reqs) {
        eval "require $req" or $missing{ $req } = $@;
    }
    if (keys %missing) {
        fatal(
            "The following module list is needed by ${caller}(), but could not be loaded:\n"
            . join('', map { '  ' . $_ . ': ' . $missing{ $_ } } keys %missing)
        );
    }
    return scalar keys %missing;
}

1;
