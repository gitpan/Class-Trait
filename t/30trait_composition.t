#!/usr/local/bin/perl
use warnings;
use strict;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;

BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib', 'test_lib';
}

# we have to use it directly because it uses an INIT block to flatten traits
use Circle;

can_ok("Circle", "new");
my $circle = Circle->new();

my @method_labels = (
	# TEquality
	qw(
	notEqualTo
	isSameTypeAs
	),
	# TMagnitude
	qw(
	lessThanOrEqualTo
	greaterThan
	greaterThanOrEqualTo
	isBetween
	),
	# TGeometry
	qw(
	area
	bounds
	diameter
	scaleBy
	),
	# TColor
	qw(
	getRed
	setRed
	getBlue
	setBlue
	getGreen
	setGreen
	equalTo
	),
	# TCircle
	qw(
	lessThan
	equalTo
	)
);

foreach my $method (@method_labels) {
	can_ok($circle, $method);
}

my $circle2 = Circle->new();

# check == operator	from TComparable
cmp_ok($circle, '==',  $circle2, 
	'... and they should be equal');
	
# check != operator	from TComparable
ok(!($circle != $circle2), 
	'... and they shouldnt be not equal');	

