
package Class::Trait;

use strict;
use warnings;

our $VERSION  = '0.02';

use overload ();
use Data::Dumper;

## ----------------------------------------------------------------------------
## Debugging functions
## ----------------------------------------------------------------------------

# make a sub
sub DEBUG { 0 }

# this is accessable to the package
my $debug_indent = 0;

{
    # this however is not accessable 
    # to anyone but the debug function    
    my $debug_line_number = 1;
    # debuggin'
    sub debug { 
        return unless DEBUG;
        # otherwise debug
        my $formatted_debug_line_number = sprintf("%03d", $debug_line_number);
        print STDERR "debug=($formatted_debug_line_number) ", ("    " x $debug_indent), @_, "\n";
        $debug_line_number++;
    }
}

## ----------------------------------------------------------------------------

# a trait cache, so we can avoid re-processing 
# traits we already have processed. This is 
# checked by the trait_load function prior to
# reading the trait in

my %CACHE = ();

# load the config class
use Class::Trait::Config;

# base class for traits
use Class::Trait::Base;

# save packages that need to be checked
# for meeting requirements here

my %TRAITS_TO_APPLY = ();

## ----------------------------------------------------------------------------

sub import {
    shift;
	# just loading the module 
	# does not mean we have any 
	# traits to give it, so we 
	# return if there is nothing
	return unless @_;
	# but if we have something, then ...
    my ($package) = caller();    
    # if we are being asked to 
    # make a trait a trait then ...
	if ($_[0] eq "debug") {
		no strict 'refs';
		no warnings 'redefine';
		*{"Class::Trait::DEBUG"} = sub { 1 };
	}
	elsif ($_[0] eq "base") {
		no strict 'refs';
		# push our base into the front 
		# of the ISA list
		unshift @{"${package}::ISA"} => 'Class::Trait::Base';
	}
	# otherwise we are using traits
	else {
		debug "^ compiling/processing traits for $package";    
		$debug_indent++ if DEBUG;    
		apply_traits($package, compile_traits($package, @_));
		$debug_indent-- if DEBUG;      
	}
}

sub apply_traits {    
    my ($package, $composite_trait_config) = @_;
    debug "> proccessing traits for $package";        
    $debug_indent++ if DEBUG;
    if ($package->isa('Class::Trait::Base')) {
        apply_traits_to_trait($package, $composite_trait_config);
    }
    else { 
        debug "~ application of traits for $package scheduled for INIT phase";        
        $TRAITS_TO_APPLY{$package} = $composite_trait_config;
    }    
    $debug_indent-- if DEBUG;
    debug "< finished proccessing traits for $package";            
}

INIT {
    debug "> applying traits to packages";
    $debug_indent++ if DEBUG;
	my ($package, $trait);
	while (($package, $trait) = each %TRAITS_TO_APPLY) {
		apply_traits_to_package($package, $trait);
	}
    $debug_indent-- if DEBUG;
    debug "> finished applying traits to packages";        
    debug "% TRAIT PROCESSING COMPLETE %";
    debug "<< dumping trait cache: " . Dumper(\%CACHE);    
}

## ----------------------------------------------------------------------------
## trait-to-package application 
## ----------------------------------------------------------------------------     

sub apply_traits_to_package {
    my ($package, $trait) = @_;
    debug "@ applying trait ($trait->{name}) to package ($package)";
    $debug_indent++ if DEBUG;
    _verify_requirements($package, $trait);
    _add_trait_methods($package, $trait);
    _add_trait_overloads($package, $trait);    
    $debug_indent-- if DEBUG;
	# now storing the trait in the package so that 
	# it can be accessable through reflection. 
    debug "^ storing reference to traits in $package";
    no strict 'refs';
    ${"${package}::TRAITS"} = $trait;
	*{"${package}::is"}	= \&is;
}

sub is {
    my ($class, $trait_name) = @_;
    $class = ref($class) || $class;
    no strict 'refs';
    return _recursive_is(${"${class}::TRAITS"}, $trait_name);  
}

sub _recursive_is {
    my ($trait, $trait_name) = @_;
    return 1 if ($trait->name eq $trait_name);    
	foreach my $sub_trait_name (@{$trait->sub_traits}) {
        # if its on the second level, then we are here
        return 1 if ($sub_trait_name eq $trait_name);
        # if not, then we need to descend lower
        return 1 if (_recursive_is($CACHE{$sub_trait_name}, $trait_name));
	} 
    return 0;
}

# -----------------------------------------------
# private methods used by trait application
# -----------------------------------------------

sub _verify_requirements {
    my ($package, $trait) = @_;
    debug "? verifying $package fufills the requirements for $trait->{name}";
    $debug_indent++ if DEBUG;
    foreach my $requirement (keys %{$trait->requirements}) {
		# if the requirement is an operator
		# then we need to put the paren in
		# front, as that is how overload.pm
		# does it, this will tell us if the
		# operator has been overloaded or not
		$requirement = "($requirement" unless is_method_label($requirement);
		# now check if the package fufills the
		# requirement or not, and die if it fails
        ($package->can($requirement)) || die "requirement ($requirement) for $trait->{name} not in $package\n";
		# if it doesn't fail we can go on to the next   
		debug "+ requirement ($requirement) for $trait->{name} fufilled in $package";
    }
    $debug_indent-- if DEBUG;    
}

sub _add_trait_methods {
	my ($package, $trait) = @_;
	debug "> adding trait ($trait->{name}) methods into $package";
	# we are messing with symbol tables so
	# turn this off for now
	$debug_indent++ if DEBUG;
	no strict 'refs';
	my ($method_label, $method);
	while (($method_label, $method)	= each %{$trait->methods}) {
		# if the method is not defined inside
		# the local class's symbol table then
		unless (defined &{"${package}::$method_label"}) {
			# we add it ....
			debug "+ adding method ($method_label) into $package";
			*{"${package}::$method_label"} = $method;
		}
		else {
			# otherwise we let the local class's
			# version override the trait version
			debug "~ $package locally implements method ($method_label)";		
		}
	}
	$debug_indent-- if DEBUG;
}

sub _add_trait_overloads {
	my ($package, $trait) = @_;
	debug "> adding trait ($trait->{name}) overloads into $package";
	# make sure we dont overwrite any overloads
	# so we must first check to see if they are
	# defined in the local class and build a 
	# temporary set of overloads to apply.
	$debug_indent++ if DEBUG;	
	my %overloads;
	my ($operator, $method_label); 
	while (($operator, $method_label) = each %{$trait->overloads}) {
		unless (defined &{"${package}::($operator"}) {
			debug "+ adding operator ($operator) into $package";
			$overloads{$operator} = $method_label;		
		}
		else {
			debug "~ $package locally implements operator ($operator)";
		}
	}
	$debug_indent-- if DEBUG;			
	# now add the temporary set of overloads we build
	overload::OVERLOAD($package, %overloads);
}

## ----------------------------------------------------------------------------
## trait-to-trait application
## ----------------------------------------------------------------------------

sub apply_traits_to_trait {
    my ($package, $trait) = @_;
    debug "^ storing sub-traits ($trait->{name}) into trait $package";
    no strict 'refs';
    *{"${package}::TRAITS"} = $trait;
}

## ----------------------------------------------------------------------------
## trait compiling
## ----------------------------------------------------------------------------

# takes a trait declaration and compiles 
# it into a trait configuration we can use
# to apply to a particular package
# NOTE:
# this function utilizes functions from the
# section labled "trait operations", which
# can be found at line no. 505

sub compile_traits {
    my ($package, @trait_declarations) = @_;
    debug "> compling traits for $package";    
    $debug_indent++ if DEBUG;
    # now we can process our traits
    my @traits = ();
    # loop through the declarations
    for (my $i = 0; $i < scalar @trait_declarations; $i++) {
        # get the name
        my $trait_name = $trait_declarations[$i];
        debug "+ found trait ($trait_name)";
        $debug_indent++ if DEBUG;
        # and load the trait
        my $trait_config = load_trait($trait_name);
        # then if the next element is a hash ref
        # meaning there are changes to be made to
        # the trait (exclusion or aliasing), then
        # process that accordingly
        if (ref($trait_declarations[$i + 1]) eq "HASH") {
            debug "+ found trait declarations for $trait_name in $package";
            # get the changes
            my $trait_changes = $trait_declarations[++$i];
            $debug_indent++ if DEBUG;
            # check for aliases first
            # NOTE:
            # we need to do this before we check
            # for excludes to allow for a method
            # to be aliased to a new name, then 
            # the old name excluded to avoid a 
            # conflict. 
            if (exists ${$trait_changes}{alias}) {
                debug "> found alias declaration";
                $debug_indent++ if DEBUG;
                alias_trait_methods($trait_config, %{$trait_changes->{alias}});
                $debug_indent-- if DEBUG;    
            }
            # now check for exludes
            if (exists ${$trait_changes}{exclude}) {
                debug "> found exclude declaration";
                $debug_indent++ if DEBUG;
                exclude_trait_methods($trait_config, @{$trait_changes->{exclude}});
                $debug_indent-- if DEBUG;
            }
            $debug_indent-- if DEBUG;
            debug "< finished processing trait declarations for $trait_name in $package";            
        }
		# our trait is all ready now, so we can
		# then push it onto the list
		push @traits => $trait_config;
        $debug_indent-- if DEBUG;    
    }
    # finally sum them all together into 
    # one config (minus any overriding trait)
    my $composite_trait_config = sum_traits(@traits);
    $debug_indent-- if DEBUG;
    debug "< finished compling traits for $package";    
    # now our composite trait is complete
    return $composite_trait_config;
}

## ----------------------------------------------------------------------------
## trait loader
## ----------------------------------------------------------------------------

sub load_trait {
    my ($trait) = @_;
    
    # check first to see if we already
    # have the trait in our cache 
    if ($CACHE{$trait}) {
        debug "~ found trait ($trait) in cache";
        # return a copy out of our cache
        return fetch_trait_from_cache($trait);
    }
    
    debug "> loading trait ($trait)";
    $debug_indent++ if DEBUG;
    
    # load the trait ...
    eval { 
        debug "+ requiring ${trait}.pm";
        $debug_indent++ if DEBUG;
        require "${trait}.pm"; 
        $debug_indent-- if DEBUG;
    };
    if ($@) {
        die "Trait ($trait) could not be found : $@\n";
    }
    
    # otherwise ...
    
    # check to make sure it is the proper type
    $trait->isa('Class::Trait::Base') || die "$trait is not a proper trait (inherits from Class::Trait::Base)\n";

    # initialize our trait configuration
    my $trait_config = Class::Trait::Config->new();
	$trait_config->name = $trait;

    _get_trait_requirements($trait_config);
    _get_trait_methods($trait_config);
    _get_trait_overloads($trait_config);
    
    no strict 'refs';
    # if this trait has sub-traits, we need to process them.
    if ($trait->isa('Class::Trait::Base') && defined %{"${trait}::TRAITS"}) {
        debug "! found sub-traits in trait ($trait)";
        $debug_indent++ if DEBUG;
        $trait_config = _override_trait(\%{"${trait}::TRAITS"}, $trait_config);
        $debug_indent-- if DEBUG;
        debug "< dumping trait ($trait) with subtraits (" . (join ", " => @{$trait_config->{sub_traits}}) . ") : " . Dumper($trait_config);        
    }
    
    # put the trait into the cache to
    # avoid having to be processed again
    store_trait_in_cache($trait, $trait_config);
    
    $debug_indent-- if DEBUG;
    debug "< finished loading trait ($trait)";    
    # then return the fresh config
    return $trait_config;    
}

# -----------------------------------------------
# private methods used by trait loader
# -----------------------------------------------

sub _override_trait {
    my ($trait, $overriding_trait) = @_;
	# create a new trait config to represent 
	# the combined traits
    my $trait_config = Class::Trait::Config->new();
    $trait_config->name = $overriding_trait->name;
    $trait_config->sub_traits = [ 
						# if we have a composite trait we dont want to
						# include the name here as it is actually defined
						# better in the sub_traits field, but if we don't
						# have a composite, then we want to include the 
						# trait name
						((COMPOSITE() eq $trait->name) ? () : $trait->name), 
						@{$trait->sub_traits} 
						];
    # let the overriding trait override 
    # the methods in the regular trait
    $trait_config->methods = { %{$trait->methods}, %{$overriding_trait->methods} };
    # the same for overloads
    $trait_config->overloads = { %{$trait->overloads}, %{$overriding_trait->overloads} };
    # now combine the requirements as well
    $trait_config->requirements = { %{$trait->requirements}, %{$overriding_trait->requirements} };
    # but we need to check them 
    debug "? checking for requirement fufillment";
    $debug_indent++ if DEBUG;    
    foreach my $requirement (keys %{$trait_config->requirements}) {
        if (is_method_label($requirement)) {
            if (exists ${$trait_config->methods}{$requirement}) {
                debug "+ method requirement ($requirement) is fufilled in overriding trait";
                delete ${$trait_config->requirements}{$requirement};
                next;
            }
        }
        else {
            if (exists ${$trait_config->overloads}{$requirement}) {
                debug "+ overload requirement ($requirement) is fufilled in overriding trait";
                delete ${$trait_config->requirements}{$requirement};
                next;
            }
        }
        debug "* requirement ($requirement) not fufilled in overriding trait";        
    }
    $debug_indent-- if DEBUG;    
    # now deal with conflicts
    debug "? checking for conflict resultion";
    $debug_indent++ if DEBUG;
    foreach my $conflict (keys %{$trait->conflicts}) {
        if (is_method_label($conflict)) {
            if (exists ${$trait_config->methods}{$conflict}) {
                debug "+ method conflict ($conflict) is resolved in overriding trait";
                delete ${$trait_config->requirements}{$conflict};
                next;
            }
        }
        else {
            if (exists ${$trait_config->overloads}{$conflict}) {
                debug "+ overload conflict ($conflict) is resolved in overriding trait";
                delete ${$trait_config->requirements}{$conflict};
                next;
            }
        }
        debug "* conflict ($conflict) not resolved in overriding trait";        
        $trait_config->conflicts->{$conflict}++;
    }
    $debug_indent-- if DEBUG;
    return $trait_config;
}

sub _get_trait_requirements {
    my ($trait_config) = @_;
    # this function messes with symbol tables
    # and symbol refs, so turn strict off in 
    # its context
    no strict 'refs';    
    (defined $trait_config->name) || die "Trait must be loaded first before information can be gathered\n";
    my $trait = $trait_config->name;
    debug "< getting requirements for ${trait}";    
    # get any requirements in the trait
    # and turn it into a hash so we can
    # track stuff easier
    $trait_config->requirements = { map { $_ => 1 } @{"${trait}::REQUIRES"} } 
        if defined @{"${trait}::"}{REQUIRES};
}

sub _get_trait_methods {
	my ($trait_config) = @_;
	# this function messes with symbol tables
	# and symbol refs, so turn strict off in 
	# its context
	no strict 'refs';	
	(defined $trait_config->name) || die "Trait must be loaded first before information can be gathered\n";
	my $trait = $trait_config->name;
	debug "< getting methods for ${trait}";	
	# NOTE: read the below expression from bottom to top
	$trait_config->methods = {
			# and stash the label and method (code ref) in a hash
			map 	{ $_ => \&{"${trait}::$_"} 	} 
			# remove all but the methods ...
			grep 	{ 
					# make sure no-one tried to implement DESTROY or AUTOLAOD 
					# in a triat though, it is not allowed, because it will
					# complicate things way too much.
					(/(DESTROY|AUTOLOAD)/ && die "traits are not allowed to implement $1\n") 
						# as long is it is not that, check the methods
						|| defined &{"${trait}::$_"} } 
			# get the contents of the symbol table ...
			keys 	%{"${trait}::"}
		};
}

sub _get_trait_overloads {
    my ($trait_config) = @_;
    # this function messes with symbol tables
    # and symbol refs, so turn strict off in 
    # its context
    no strict 'refs';    
    (defined $trait_config->name) || die "Trait must be loaded first before information can be gathered\n";
    my $trait = $trait_config->name;
    debug "< getting overloads for ${trait}";    
    # get the overload parameter hash
    $trait_config->overloads = { %{"${trait}::OVERLOADS"} } if defined %{"${trait}::OVERLOADS"};
}

## ----------------------------------------------------------------------------
## trait cache operations
## ----------------------------------------------------------------------------

# NOTE:
# the traits are stored as a copy and 
# then fetched as a copy. This is becuase
# we alter our version when we apply
# declarations (excludes, aliases), and so
# we need to make sure our cache stays clean.

sub store_trait_in_cache {
    my ($trait_name, $trait_config) = @_;
    debug "^ storing ($trait_name) in cache";    
    $CACHE{$trait_name} = $trait_config->clone();
}

sub fetch_trait_from_cache {
    my ($trait_name) = @_;
    debug "< fetching ($trait_name) from cache";
    return $CACHE{$trait_name}->clone();
}

## ----------------------------------------------------------------------------
## trait operations
## ----------------------------------------------------------------------------

# -----------------------------------------------
# exclusion 
# -----------------------------------------------
sub exclude_trait_methods {
    my ($trait_config, @exclusions) = @_;
    debug "- excluding methods for trait ($trait_config->{name})";
    $debug_indent++ if DEBUG;
    foreach my $exculsion (@exclusions) {
        # check we have the method being excluded
        (exists ${$trait_config->methods}{$exculsion}) 
            # otherwise we throw an exception here
            || die "attempt to exclude method ($exculsion) that is not in trait ($trait_config->{name})\n";
        debug "- excluding method ($exculsion)";            
        # if we do have it, so lets exclude it
        delete ${$trait_config->methods}{$exculsion};
        # and be sure to add it to the list of requirements
        # unless its already there
        $trait_config->requirements->{$exculsion}++;
    }
    $debug_indent-- if DEBUG;        
}

# -----------------------------------------------
# aliasing
# -----------------------------------------------
sub alias_trait_methods {
    my ($trait_config, %aliases) = @_;
    debug "=> aliasing methods for trait ($trait_config->{name})";
	# Now when aliasing methods for a trait,
	# we need to be sure to move any operator overloads 
	# that are bound to the old method to use the new method
	# this helps us assure that the intentions of trait is
	# fufilled. So to facilitate this, we reverse the normal
	# overload hash (operator => method) to be keyed by method
	# (method => operator), this way we can access it easier.
	my %overloads_by_method = reverse %{$trait_config->overloads};
	# no process the aliases
    $debug_indent++ if DEBUG;
    foreach my $old_name (keys %aliases) {
        # check we have the method being aliases
        (exists ${$trait_config->methods}{$old_name}) 
            # otherwise we throw an exception here
            || die "attempt to alias method ($old_name) that is not in trait ($trait_config->{name})\n";
        debug "=> aliasing method ($old_name) to ($aliases{$old_name})";                
        # if we do have it, so lets alias it
        $trait_config->methods->{$aliases{$old_name}} = $trait_config->methods->{$old_name};
        # if we find the old method in the overloads, 
		# then we change it to the new one here
        $trait_config->overloads->{$overloads_by_method{$old_name}} = $aliases{new_name} 
            if exists $overloads_by_method{$old_name};
    }
    $debug_indent-- if DEBUG;    
}

# -----------------------------------------------
# summation
# -----------------------------------------------

# a constant to reprsent the name of
# a composite trait, a composite trait's
# name is best described as the concatenation
# of all the names of its subtraits, but 
# rather than duplicate that information in 
# the name field and the sub-traits field, 
# we assign a COMPOSITE constant as a 
# placeholder/flag
use constant COMPOSITE => "COMPOSITE";

sub sum_traits {
    my (@traits) = @_;    
    if (scalar @traits == 1) {
        # if we have only one trait, it doesn't make
        # sense to sum it since there is nothing to
        # sum it against
        debug "< only one trait, no need to sum";
        return $traits[0];
    }        
    debug "> summing traits (" . (join ", " => map { $_->{name} } @traits) . ")";
    
    # initialize our trait configuration
    my $trait_config = Class::Trait::Config->new();
	# we are making a composite trait, 
	# so lets call it as such
	$trait_config->name = COMPOSITE;
	
    $debug_indent++ if DEBUG;    
    # and process our traits
    foreach my $trait (@traits) {	
        push @{$trait_config->sub_traits} => $trait->name;
        debug "+ adding trait ($trait->{name}) to composite trait";
        $debug_indent++ if DEBUG;        
        # first lets check the methods     
        _fold_in_methods($trait, $trait_config);
        # then check the overloads 
        _fold_in_overloads($trait, $trait_config);
        $debug_indent-- if DEBUG;        
    }
    $debug_indent-- if DEBUG;
    # now that we have added all our methods we can 
    # check to see if any of our requirements have 
    # been fufilled during that time

    debug "? checking requirements for sum-ed traits ($trait_config->{name})";
    $debug_indent++ if DEBUG;    
    foreach my $trait (@traits) {    
        _check_requirements($trait, $trait_config);
    }
    $debug_indent -- if DEBUG;    

    # now we have cleared up any requirements and 
    # combined all our methods, we can return the config
    debug "< traits summed successfully";    
    return $trait_config;
}

# -----------------------------------------------
# private methods used by summation
# -----------------------------------------------

sub _fold_in_methods {
    my ($trait, $trait_config) = @_;
    debug "> folding in methods for trait ($trait->{name})"; 
    $debug_indent++ if DEBUG;    
    foreach my $method_label (keys %{$trait->methods}) {
        if (exists ${$trait_config->conflicts}{$method_label}) {
            debug "* method ($method_label) is already in conflict";
            # move to the next method as we cannot add this one
            next;
        }
        # if the method label already exists in 
        # our combined config, then ...
        if (exists ${$trait_config->methods}{$method_label}) {
            # check to make sure it is not the same method
            # possibly from a shared base/sub-trait
            unless (are_methods_equal(
                        $trait_config->methods->{$method_label}, 
                        $trait->methods->{$method_label}
                        )) {
                # this is a conflict, we need to add the
                # method label onto the requirements and 
                # we need to label that a method is in conflict.
                debug "* method ($method_label) is in conflict, added to the requirements";        
                # method is in conflict...
                $trait_config->conflicts->{$method_label}++;            
                # so remove any copies ...
                delete ${$trait_config->methods}{$method_label};
                # and it is considered to be a requirement 
                # for the implementing class
                $trait_config->requirements->{$method_label}++;
            }
            else {
                debug "~ method ($method_label) is a duplicate, no action was taken";    
            }
        }
        else {
            debug "+ method ($method_label) added successfully";
            # move it 
            $trait_config->methods->{$method_label} = $trait->methods->{$method_label};
        }        
    }
    $debug_indent-- if DEBUG;    
}


sub _fold_in_overloads {
	my ($trait, $trait_config) = @_;
	debug "> folding in overloads for trait ($trait->{name})"; 	
	$debug_indent++ if DEBUG;	
	foreach my $overload (keys %{$trait->overloads}) {
		if (exists ${$trait_config->conflicts}{$overload}) {
			debug "* overload ($overload) is already in conflict";
			# move to the next overload as we cannot add this one
			next;
		}	
		# if we already have it then 
		if (exists ${$trait_config->overloads}{$overload}) {
			# before we get hasty, lets check out if
			# the method called for this overload is
			# also in conflict (which if it isn't 
			# likely means that they were the same
			# method) (see method equality function)
			my $overload_method = ${$trait_config->overloads}{$overload};
			unless (${$trait_config->conflicts}{$overload_method}) {
				debug "~ operator ($overload)  is a duplicate, no action was taken";
				next;
			}
			debug "* operator ($overload) in conflict, added to requirements";	
			# note the conflict and ...
			$trait_config->conflicts->{$overload}++;	
			# get rid of it (conflicts results in exclusions)
			delete ${$trait_config->overloads}{$overload};
			# since the overload is now excluded, then it then
			# becomes a requirement for the implementing package
			$trait_config->requirements->{"${overload}"}++;
		}
		else {
			debug "+ operator ($overload) added successfully";		
			# otherwise add it to the list of methods
			$trait_config->overloads->{$overload} = $trait->overloads->{$overload};
		}
	}
	$debug_indent-- if DEBUG;	
}

sub _check_requirements {
    my ($trait, $trait_config) = @_;
    # now check the requirements
    debug "? checking for trait ($trait->{name})";
    foreach my $requirement (keys %{$trait->requirements}) {
        # if the method does not exist in
        # our new combined method group
        unless (exists ${$trait_config->methods}{$requirement}) {
            $debug_indent++ if DEBUG;
            debug "* requirement ($requirement) not fufilled";
            $debug_indent-- if DEBUG;        
            # make it a reuiqement for the package
            $trait_config->requirements->{$requirement}++;
        }
    }    
}

## ----------------------------------------------------------------------------
## utility methods
## ----------------------------------------------------------------------------

sub are_methods_equal {
    my ($method_1, $method_2) = @_;
    # make sure we are given proper code refs 
    (ref($method_1) eq "CODE" && ref($method_2) eq "CODE") || die "are_methods_equal not called with methods\n";
    # then decide if they are the same method (same address)
    return ("$method_1" eq "$method_2") ? 1 : 0;
}

# short quick predicate functions
sub is_method_label { $_[0] =~ /[a-zA-Z_][a-zA-Z_0-9]+/ }
sub is_operator { not is_method_label(shift) }


1;

__END__

=head1 NAME

Class::Trait - An implementation of Traits in Perl

=head1 SYNOPSIS

    # to turn on debugging (do this before
    # any other traits are loaded)
    use Class::Trait 'debug';
    
    # nothing happens, but the module is loaded
    use Class::Trait;
    
    # loads these two traits and flatten them
    # into the current package
    use Class::Trait qw(TPrintable TComparable);	
    
    # loading a trait and performing some
    # trait operations (alias, exclude) first
    use Class::Trait (
            'TPrintable' => {
                    alias => { "stringValue" => "strVal" },
                    exclude => [ "stringValue" ]
                },
            );
            
    # loading two traits and performing
    # a trait operation (exclude) on one 
    # module to avoid method conflicts
    use Class::Trait 
            'TComparable' => {
                    # exclude the basic equality method
                    # from TComparable and use the ones
                    # in TEquality instead.
                    exclude => [ "notEqualTo", "equalTo" ]
                },
            'TEquality' # <- use equalTo and notEqualTo from here
            );			
            
    # when building a trait, you need it
    # to inherit from the trait meta/base-class
    # so do this ...
    use Class::Trait 'base';		

=head1 DESCRIPTION

This document attempts to explain Traits in terms of Perl.

=head2 Trait composition

A Trait can be defined as a package containing:

=over 4

=item *
A set of methods

=item *
A hash of overloaded operators mapped to the method labels

=item *
An array of required method labels

=back

Here is an example of the syntax for a very basic trait:

    package TPrintable;
    
    use Class::Trait 'base';
    
    our @REQUIRES = qw(toString);
    
    our %OVERLOADS = ('""' => toString);
    
    sub stringValue {
        my ($self) = @_;
        require overload;
        return overload::StrVal($self);
    }
    
    1;

The above example requires the user of the trait to implement a C<toString> method, which the overloaded C<""> operator then utilizes. The trait also provides a C<stringValue> method to the consuming class.

=head2 Trait usage

When a class uses a Trait:

=over 4

=item *
All requirements of the traits (or composite trait) must be meet either by the class itself or by one of its base classes.

=item *
All the non-conflicting trait (or composite trait) methods are flattened into the class, meaning an entry is created directly in the class's symbol table and aliased to the original trait method. 

=item *
If a method label in a class conflicts with a method label in the trait (or composite trait), the class method is chosen and the trait method is discarded. This only applies to methods defined directly in the class's symbol table, methods inherited from a base class are overridden by the trait method.

=back	  

Here is a simple example of the usage of the above trait in a class.

    package MyClass;
    
    use Class::Trait (
           'TPrintable' => { 
               alias => { "strVal" => "stringValue" }
               exclude => [ "stringValue" ]
               }
            );
    
    sub stringValue { ... }

The above example would use the C<TPrintable> trait, aliasing C<stringValue> to the method label C<strVal>, and then excluding C<stringValue>. This is done to avoid a conflict with C<stringValue> method implemented in the class that uses the trait.

=head2 Trait operations

When using a trait, the class can make changes to the structure of a trait through the following methods.

=over 4 

=item * Exclusion	

An array of method labels to exclude from trait.

=item * Alias

A hash of old method labels to new method labels.

=item * Summation

A number of traits can be combined into one.

=back

=head3 Exclusion

This excludes a method from inclusion in the class which is using the trait. It does however cause the method to be added to the traits required methods. This is done because it is possible that other methods within the trait rely on the excluded method, and therefore it must be implemented somewhere in order for the other method to work.

=head3 Aliasing

Aliasing is not renaming or redefining, it does not remove the old method, but instead just introduces another label for that method. The old method label can be overridden or excluded without affecting the new method label. 

One special note is that aliasing does move any entry in the overloaded operators to use the new method name, rather than the new method name. This is done since many times aliasing is used in conjunction with exclusion to pre-resolve conflicts. This avoids the orphaning of the operator. 

=head3 Summation

When two or more traits are used by a class (or another trait), the traits are first compiled into a composite trait. The resulting composite trait is:

=over 4

=item *
A union of all non-conflicting methods of all traits.

=item *
A union of all non-conflicting operators of all traits.

=item *
A union of all unsatisfied requirements of all traits.

=back

=head4 Method conflicts

Method equality if determined by two conditions, the first being method label string equality, the second being the hex address of the code reference (found by stringifying the subroutine reference). 

If a method in one of the traits is deemed to be in conflict with a method in another trait, the result is the exclusion of that method from the composite trait. The method label is then added to the requirements array for the composite trait. 

Method conflict can be avoided by using exclusion or a combination of aliasing and exclusion.

=head4 Operator conflicts

Operator conflicts also result in the exclusion of the operator from the composite trait and the operator then becomes a requirement.

=head4 Requirement satisfaction

One trait may satisfy the requirements of another trait when they are combined into a composite trait. This results in the removal of the requirement from the requirements array in the composite trait. 

=head1 EXPORTS

=over 4

=item B<$TRAITS>

While not really exported, Class::Trait leaves the actual Class::Trait::Config object applied to the package stored as scalar in the package variable at C<$TRAITS>. 

=item B<is>

Class::Trait will export this method into any object which uses traits. By calling this method you can query the kind of traits the object has implemented. The method works much like the perl C<isa> method in that it performs a depth-first search of the traits hierarchy and  returns true (1) if the object implements the trait, and false (0) otherwise.

  $my_object_with_traits->is('TPrintable');

=back

=head1 DEBUGGING

Class::Trait is really an experimental module. It is not ready yet to be used seriously in production systems. That said, about half of the code in this module is dedicated to formatting and printing out debug statements to STDERR when the debug flag is turned on. 

  use Class::Trait 'debug';

The debug statements prints out pretty much every action taken during the traits compilation process and on occasion dump out B<Data::Dumper> output of trait structures. If you are at all interested in traits or in this module, I recommend doing this, it will give you lots of insight as to what is going on behind the scences.

=head1 CAVEAT

Currently due to our use of the INIT phase of the perl compiler, this will not work with mod_perl. This is on the L<TO DO> list though. I am open to any suggestions on how I might go about fixing this.

=head1 TO DO

I consider this implementation of Traits to be pretty much feature complete in terms of the description found in the papers. Of course improvements can always be made, below is a list of items on my to do list:

=over 4

=item B<Make this work with mod_perl>

Currently due to our use of the INIT phase of the perl compiler, this will not work with mod_perl. My only thought is to use the PerlChildInit handler, but I don't currently have the time to investigate and test this though.

=item B<Tests>

I have revamped the test suite alot this time around. But it could always use more. Currently we have 158 tests in the suite. I ran it through Devel::Cover and found that the coverage is pretty good, but can use some help:

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt branch   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 /Class/Trait.pm                91.4   58.6   50.0   95.7    6.2    8.9   80.0
 /Class/Trait/Base.pm           90.5   50.0    n/a  100.0    n/a    0.1   83.9
 /Class/Trait/Config.pm        100.0    n/a    n/a  100.0  100.0    2.9  100.0
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

Obviously Class::Trait::Config is fine.

To start with Class::Trait::Reflection is not even tested at all. I am not totally happy with this API yet, so I am avoiding doing this for now.

The pod coverage is really low in Class::Trait since virtually none of the methods are documented (as they are not public and have no need to be documented). The branch coverage is low too because of all the debug statements that are not getting execute (since we do not have DEBUG on). 

The branch coverage in Class::Trait::Base is somwhat difficult. Those are mostly rare error conditions and edge cases, none the less I would still like to test them.

Mostly what remains that I would like to test is the error cases. I need to test that Class::Traits blows up in the places I expect it to.

=item B<Reflection API>

The class Class::Traits::Reflection gives a basic API to access to the traits used by a class. Improvements can be made to this API as well as the information it supplies. 

=item B<Tools>

Being a relatively new concept, Traits can be difficult to digest and understand. The original papers does a pretty good job, but even they stress the usefulness of tools to help in the development and understanding of Traits. The 'debug' setting of Class::Trait gives a glut of information on every step of the process, but is only useful to a point. A Traits 'browser' is something I have been toying with, both as a command line tool and a Tk based tool. 

=back

=head1 SEE ALSO

Class::Trait is an implementation of Traits as described in the the documents found on this site L<http://www.iam.unibe.ch/~scg/Research/Traits/>. In particular the paper "Traits - A Formal Model", as well as another paper on statically-typed traits (which is found here : L<http://www.cs.uchicago.edu/research/publications/techreports/TR-2003-13>). 

B<Class::Trait::Base>, B<Class::Trait::Config>, B<Class::Trait::Reflection>

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

The development of this module was initially begun by Curtis "Ovid" Poe, E<lt>poec@yahoo.comE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
