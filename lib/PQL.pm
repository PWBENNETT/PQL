package PQL;

use 5.020;
use utf8;
no diagnostics;

use Exporter qw( import );
use PQL::Logger;

require PQL::criteria;
require PQL::rowset;
require PQL::student;
require PQL::table; # table ISA resulset, or the other way round. potato, potahto

use overload (
    '""' => 'render',
    '%{}' => 'table',
    '&{}' => 'table',
    '@{}' => sub { fatal('wat') },
);

our @EXPORT_OK = qw( bind_param unquoted );
our %EXPORT_TAGS = (
    ':all' => \@EXPORT_OK,
);

sub connect {
    my $class = shift;
    my %args
        = (@_ == 1 and ref($_[0]) =~ /^DBI::db/o) ? (dbh => $_[0])
        : (@_ >= 3) ? do { _i_need(qw( DBI )); (dbh => DBI->connect(@_)) }
        : ref($_[0]) ? %{%_[0]}
        : @_
        ;
    $args{ plan } ||= { };
    $args{ plan_stats } ||= { };
    $args{ sth_stats } ||= { };
    return bless \%args => (ref($class) || $class);
}

sub study {
    my $self = shift;
    return $self if ($self->{ plan_stats }->{ last_updated } || 0) >= ($self->{ plan }->{ last_updated } || time);
    $self->{ plan_stats } = PQL::student->study($self->{ plan });
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

sub prepare {
    my $self = shift;
    if (($self->{ sth_stats }->{ last_updated } || 0) < ($self->{ plan_stats }->{ last_updated } || time)) {
        my $sql = $self->render();
        eval { $self->{ dbh }->ensure_connection() } or do {
            if (my $e = $@) {
                fatal($e);
            }
        };
        $self->{ sth } = $self->{ dbh }->prepare($sql);
        $self->{ sth_stats }->{ last_updated } = time;
    }
    return $self->{ sth };
}

sub execute {
    my $self = shift;
    my $sth
        # allow a ready-made STH as the first argument
        = ref($_[0]) eq 'DBI::st' ? shift(@_)
        # elsif one was not provided, and our cached one is fresh enough, use it
        : ($self->{ sth_stats }->{ last_updated } || 0) > ($self->{ plan_stats }->{ last_updated } || 0) ? $self->{ sth }
        # else, go make (and cache) an STH
        : $self->prepare()
        ;
    my $binds
        # allow plain list, and treat as arrayref
        = @_ > 1 ? [ @_ ]
        # or allow single (possibly ref) scalar
        : @_ > 0 ? $_[0]
        # if all else fails, then they'll get what they asked for -- undef() is purely arbitrary but might help debuggers
        : undef
        ;
    unless (@_ > 0) {
        $sth->execute();
        return $sth;
    }
    if (ref $binds eq 'ARRAY') {
        $sth->execute(@$binds);
        return $sth;
    }
    for my $k (keys %$binds) {
        my $bound = $binds->{ $k };
        my $name = ($k !~ /^:/o ? ':' : '') . $k; # add the ':' if it's missing
        my $method = 'bind_param' . (ref($bound) ? '_inout' : ''); # treat references as read-write arguments, just in case
        $sth->$method($name => $bound);
    }
    $sth->execute();
    return $sth;
}

sub bind_param {
    shift if ((ref($_[0]) || $_[0]) eq __PACKAGE__);
    my $name = ($_[0] !~ /^:/o ? ':' : '') . $_[0];
    return PQL::bind_param->new($name);
}

sub unquoted {
    shift if ((ref($_[0]) || $_[0]) eq __PACKAGE__);
    my $literal = shift;
    return bless \$literal => PQL::unquoted;
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
            . join('', map { '  ' . $_ . ': ' . $missing{ $_ } } sort { lc $a cmp lc $b } keys %missing)
        );
    }
    return @reqs - keys %missing;
}

1;

package PQL::generic;

use overload (
    '""' => 'render',
    fallback => 0,
);

1;

package PQL::bind_param;

use base qw( PQL::generic );

our %singleton_stash;
our %bound_values;

sub new {
    my $class = shift;
    my ($name) = @_;
    $singleton_stash{ $name } ||= bless \$name => (ref($class) || $class);
    return $singleton_stash{ $name };
}

sub set {
    my $self = shift;
    $bound_values{ $$self } = shift;
    return $self;
}

sub render {
    my $self = shift;
    my $v = $bound_values{ $$self } or fatal("$$self is not bound, can't render() it");
    return "$v";
}

package PQL::unquoted;

use base qw( PQL::generic );

sub render {
    return ${$_[0]};
}

1;
