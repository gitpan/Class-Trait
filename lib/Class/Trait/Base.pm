
package Class::Trait::Base;
$VERSION  = '0.01';

use strict;
use warnings;

# all that is here is an AUTOLOAD method 
# which is used to fix the SUPER call method
# resolution problem introduced when a 
# trait calls a method in a SUPER class
# since SUPER should be bound after the
# trait is flattened and not before.

sub AUTOLOAD {
	my $auto_load = our $AUTOLOAD;
	# we dont want to mess with DESTORY
	return if ($auto_load =~ m/DESTROY/);
	# otherwise get our arguemnts
	my ($self, @args) = @_;
	# if someone is attempting a call to 
	# SUPER, then we need to handle this.
	if ($auto_load =~ /SUPER::/) {
		# lets get the intended method name
		my ($method) = $auto_load =~ /SUPER::(.*)/;
		no strict 'refs';
		# loop though the ISA, although triats are
		# meant to be used within a single inheritance
		# world, so in theory we should not need to
		# do this, and can rely on the fact there
		# is only one base class in the ISA. But the 
		# reality is that we cannot enforce the
		# single inheritance rule, and therefore
		# we loop.
		foreach my $base (@{ ref($self) . "::ISA"}) {
			# if we found the method
			if ($base->can($method)) {
				# then we should use it and 
				# return the result
				return &{"${base}::$method"}($self, @args);
			}
		}
	}
	# if it was not a call to SUPER, then 
	# we need to let this fail, as it is
	# not our problem
	die "undefined method ($auto_load) in trait\n";
}


1;

__END__

=head1 NAME

Class::Trait::Base - Base class for all Traits

=head1 SYNOPSIS

This class needs to be inheritied by all traits so they can be identified as traits.

	use Class::Trait 'base';

=head1 DESCRIPTION

Not much going on here, just an AUTOLOAD function to help properly dispatch calls to C<SUPER::>.

=head1 SEE ALSO

B<Class::Trait>, B<Class::Trait::Config>

=head1 AUTHOR

Stevan Little E<lt>stevan_little@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Stevan Little

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut