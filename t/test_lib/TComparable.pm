package TComparable;

use strict;
use warnings;

use Class::Trait 'base';

## overload operator
our %OVERLOADS = (
    '=='  => "equalTo",
    '!='  => "notEqualTo",
    '<=>' => "compare"
);


our @REQUIRES = qw(compare);

sub equalTo {
   my ($self, $right) = @_;
   return ($self->compare($right) == 0) ? 1 : 0;
}

sub notEqualTo {
   my ($self, $right) = @_;
   return ($self->equalTo($right)) ? 0 : 1;
}

1;
