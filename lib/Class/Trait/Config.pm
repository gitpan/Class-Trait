
package Class::Trait::Config;

use strict;
use warnings;

our $VERSION  = '0.04';

# we are going for a very struct-like class here
# to try and keep the syntactical noise down.

# We never intend this class to be
# subclassed, so the constructor is
# very simple on purpose. 
# you can consider this class to be
# effectively sealed.
sub new {
	return bless {
			name         => "",
			sub_traits   => [],
			requirements => {},
			methods      => {},
			overloads    => {},
			conflicts    => {}
			}, "Class::Trait::Config";
}

# just use basic l-valued methods 
# for clarity and speed.
sub name         : lvalue { $_[0]->{name}         }
sub sub_traits   : lvalue { $_[0]->{sub_traits}   }
sub requirements : lvalue { $_[0]->{requirements} }
sub methods      : lvalue { $_[0]->{methods}      }
sub overloads    : lvalue { $_[0]->{overloads}    }
sub conflicts    : lvalue { $_[0]->{conflicts}    }

# a basic clone function for moving
# in and out of the cache.
sub clone {
	return bless {
		name         => $_[0]->{name},
		sub_traits   => [ @{$_[0]->{sub_traits}}   ],
		requirements => { %{$_[0]->{requirements}} },
		methods      => { %{$_[0]->{methods}}      }, 
		overloads    => { %{$_[0]->{overloads}}    },
		conflicts    => { %{$_[0]->{conflicts}}    }		
		}, "Class::Trait::Config";
}

1;

__END__

=head1 NAME

Class::Trait::Config - Trait configuration information storage package.

=head1 SYNOPSIS

This package is used internally by Class::Trait to store Trait configuration information. It is also used by Class::Trait::Reflection to gather information about a Trait.

=head1 DESCRIPTION

This class is a intentionally very C-struct-like. It is meant to help encapsulate the Trait configuration information in a clean easy to access way.

This class is effectively sealed. It is not meant to be extended, only to be used. 

=head1 METHODS

=over 4

=item B<new>

Creates a new empty Class::Trait::Config object, with fields initialized to empty containers. 

=item B<name>

An C<lvalue> subroutine for accessing the C<name> string field of the Class::Trait::Config object.

=item B<sub_traits>

An C<lvalue> subroutine for accessing the C<sub_traits> array reference field of the Class::Trait::Config object.

=item B<requirements>

An C<lvalue> subroutine for accessing the C<requirements> hash reference field of the Class::Trait::Config object. Note, the requirements field is a hash reference to speed requirement lookup, the values of the hash are simply booleans.

=item B<methods>

An C<lvalue> subroutine for accessing the C<methods> hash reference field of the Class::Trait::Config object.

=item B<overloads>

An C<lvalue> subroutine for accessing the C<overloads> hash reference field of the Class::Trait::Config object.

=item B<conflicts>

An C<lvalue> subroutine for accessing the C<conflicts> hash reference field of the Class::Trait::Config object. Note, the conflicts field is a hash reference to speed conflict lookup, the values of the hash are simply booleans.

=item B<clone>

Provides deep copy functionality for the Class::Trait::Config object. This will be sure to copy all sub-elements of the object, but not to attempt to copy and subroutine references found.

=back

=head1 SEE ALSO

B<Class::Trait>, B<Class::Trait::Reflection>

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com> 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut