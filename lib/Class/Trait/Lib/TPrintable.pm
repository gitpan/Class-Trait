
package TPrintable;

use strict;
use warnings;

our $VERSION = '0.01';

use overload ();
	
use Class::Trait 'base';    
    
## overload operator

our %OVERLOADS = ('""' => "toString");

## requires

our @REQUIRES = qw(toString);

### methods

# return the unmolested object string
sub stringValue {
	my ($self) = @_;
	return overload::StrVal($self);
}

1;

__END__

=head1 NAME 

TPrintable - Trait for adding stringification abilities to your object 

=head1 DESCRIPTION

TPrintable gives your object automatic stringification abilities, as well as access to your original stringified object value.

=head1 REQUIREMENTS

=over 4

=item B<toString>

This method should return the stringified object.

=back

=head1 OVERLOADS

=over 4

=item B<"">

=back

=head1 METHODS

=over 4

=item B<stringValue>

This returns the normal perl stringified value, bypassing whatever C<toString> might return.

=back

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com> 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
