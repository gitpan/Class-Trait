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
use TraitTest;
my $SIMPLE_TEST = 'TraitTest';
my $SIMPLE_TEST_BASE = 'TraitTestBase';

can_ok($SIMPLE_TEST, 'new');

my $trait_1 = $SIMPLE_TEST->new(3);
my $trait_2 = $SIMPLE_TEST->new(3);

isa_ok($trait_1, $SIMPLE_TEST);
	isa_ok($trait_1, $SIMPLE_TEST_BASE);
isa_ok($trait_2, $SIMPLE_TEST);
	isa_ok($trait_2, $SIMPLE_TEST_BASE);

# check that it "can" execute the methods 
# that it should have gotten from the traits
foreach my $method (qw/strVal stringValue equalTo notEqualTo/) {
	can_ok($trait_1, $method);
}

# check "" operator from TPrintable
is("$trait_1", '3.000 (overridden stringification)', 
    '... and it should be stringified correctly');

# check == operator	from TComparable
cmp_ok($trait_1, '==',  $trait_2, 
	'... and they should be equal');
	
# check != operator	from TComparable
ok(!($trait_1 != $trait_2), 
	'... and they shouldnt be not equal');	

# check the aliased stringValue function
like($trait_1->strVal, qr/$SIMPLE_TEST=HASH\(0x[a-fA-F0-9]+\)/, 
    '... and should return a reasonable strVal');
	


# ---------------------------------------------------
# NOTE: 2.29.2004 - SL
# ---------------------------------------------------
# This Test is failing on Mac OS X, not sure why.
# This is the error text, I am not sure I understand
# what is going on from it:
# ---------------------------------------------------
# Operation 'eq': no method found,                 
#         left argument in overloaded package TraitTest,
#         right argument in overloaded package TraitTest at /Library/Perl/Test/More.pm line 1037.
# ---------------------------------------------------	
#my $trait2 = $SIMPLE_TEST->new(2);
#is_deeply( [$trait2, $trait3], [sort {$a <=> $b} $trait3, $trait2], 
#    '... and we should also be able to use the overloaded sort');
# ---------------------------------------------------