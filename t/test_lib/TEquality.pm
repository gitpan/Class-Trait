
use strict;
use warnings;

package TEquality;

use Class::Trait 'base';

our %OVERLOADS = (
	'==' => "equalTo",
	'!=' => "notEqualTo"
	);

our @REQUIRES = ("equalTo");

sub notEqualTo {
	my ($left, $right) = @_;
	return not $left->equalTo($right);
}

sub isSameTypeAs {
	my ($left, $right) = @_;
	# we know the left operand is an object
	# right operand must be an object and
	# either right is derived from the same type as left
	# or left is derived from the same type as right	
	return (ref($right) && ($right->isa(ref($left)) || $left->isa(ref($right))));
}

1;

__DATA__