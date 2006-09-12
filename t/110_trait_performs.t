#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );
}

{

    package TestIt;

    use Class::Trait qw/RenameDoesToPerforms/;

    sub new { bless {}, shift }
}

can_ok 'TestIt', 'new';
ok my $test = TestIt->new, '... and calling it should succeed';
isa_ok $test, 'TestIt', '... and the object it returns';

can_ok $test, 'reverse';
is $test->reverse('this'), 'siht', '... and methods should work correctly';

can_ok $test, 'performs';
ok $test->performs('RenameDoesToPerforms'),
  '... and it should return true for traits it can do';
ok !$test->performs('NoSuchTrait'),
  '... and it should return false for traits it cannot do';

ok !$test->can('does'), '... and it should not have a "does()" method';
ok !$test->can('is'),   '... or an "is()" method';
