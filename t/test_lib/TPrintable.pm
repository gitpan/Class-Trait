package TPrintable;

use strict;
use warnings;

use Class::Trait 'base';

## overload operator
our %OVERLOADS = (
    '""' => "toString"     
);

our @REQUIRES = qw(toString);

# return the unmolested object string
sub stringValue {
    my ($self) = @_;
    return overload::StrVal($self);
}

1;
