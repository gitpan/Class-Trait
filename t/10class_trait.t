#!/usr/local/bin/perl
use warnings;
use strict;
use Data::Dumper;
use Test::More tests => 2;
use Test::Exception;

BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib', 'test_lib';
}

# we have to use it directly because it uses an INIT block to flatten traits
use BasicTrait;

can_ok(BasicTrait => 'name');
is(BasicTrait->name, 'TSimple', '... and it should have the method from the trait');
