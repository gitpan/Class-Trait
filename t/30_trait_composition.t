#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 39;

BEGIN {
    unshift @INC => ('t/test_lib', '/test_lib');
}

# we have to use it directly because it uses an INIT block to flatten traits
use Circle;

# create a circle
can_ok("Circle", "new");
my $circle = Circle->new();

# make sure it is a Circle
isa_ok($circle, 'Circle');

# check the traits in it
my @trait_in_circle = qw/ TCircle TMagnitude TGeometry TColor TEquality /;
ok($circle->is($_), "... circle is $_") foreach @trait_in_circle;

# now check the methods we expect it to have
my @method_labels = (
	qw/ notEqualTo isSameTypeAs /,                                      # TEquality
	qw/ lessThanOrEqualTo greaterThan greaterThanOrEqualTo isBetween /, # TMagnitude
	qw/ area bounds diameter scaleBy /,                                 # TGeometry
	qw/ getRed setRed getBlue setBlue getGreen setGreen equalTo /,      # TColor
	qw/ lessThan equalTo /                                              # TCircle
);

can_ok($circle, $_) foreach @method_labels;

# now check the overloaded operators we expect it to have

# for Circle 
ok(overload::Method($circle, '=='), '... circle overload ==');

# for TCircle 
# NOTE: TCircle overloads == too, but Circle overrides that
ok(overload::Method($circle, '<'), '... circle overload <');

# for TEquality
# NOTE: TEquality overloads == too, but Circle overrides that
ok(overload::Method($circle, '!='), '... circle overload !=');

# for TMagnitude
# NOTE: TMagnitude overloads < too, but TCircle overrides that
ok(overload::Method($circle, '<='), '... circle overload <=');
ok(overload::Method($circle, '>'), '... circle overload >');
ok(overload::Method($circle, '>='), '... circle overload >='); 

# now lets extract the actul trait and examine it

my $trait;
{
	no strict 'refs';
	# get the trait out
	$trait = ${"Circle::TRAITS"};
}

# check to see it is what we want it to be
isa_ok($trait, 'Class::Trait::Config');

# now examine the trait itself
is($trait->name, 'COMPOSITE', '... get the traits name');

ok(eq_array(
        $trait->sub_traits, 
        [ 'TCircle', 'TColor' ])
    , '... this should not be empty');
    
ok(eq_hash(
        $trait->conflicts, 
        { '==' => 1, equalTo => 1 })
    , '... this should not be empty');    

ok(eq_hash(
        $trait->requirements, 
        { 
            '==' => 1,
            equalTo => 1,                                                
            getRadius => 1,
            setRadius => 1,
            getRGB => 1,
            setRGB => 1,
            getCenter => 1,                                    
            setCenter => 1,                                    
        })
    , '... this should not be empty');

ok(eq_hash(
        $trait->overloads, 
        {
            '>=' => 'greaterThanOrEqualTo',
            '<=' => 'lessThanOrEqualTo',
            '>' => 'greaterThan',
            '<' => 'lessThan',
            '!=' => 'notEqualTo'
        })
    , '... this should not be empty');

ok(eq_set(
        [ keys %{$trait->methods} ], 
        [
            'isSameTypeAs',
            'setBlue',
            'area',
            'getBlue',
            'getRed',
            'bounds',
            'notEqualTo',
            'getGreen',
            'lessThanOrEqualTo',
            'setRed',
            'setGreen',
            'scaleBy',
            'lessThan',
            'diameter',
            'greaterThan',
            'isBetween',
            'greaterThanOrEqualTo'
        ])
    , '... this should not be empty');  


