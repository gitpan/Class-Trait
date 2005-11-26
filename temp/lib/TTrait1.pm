package TTrait1;

use strict;
use warnings;

use Class::Trait 'base';

sub name {
    return "We're in ".__PACKAGE__;
}

1;
