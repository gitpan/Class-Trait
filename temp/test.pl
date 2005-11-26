#!/usr/bin/perl

use strict;
use warnings;

BEGIN { 
    use lib '../lib', 'lib';
}
{
    package Foo;
    use Class::Trait;
    Class::Trait->import('TTrait1', 'TTrait2');
    Class::Trait->initialize;

    sub new { bless {}, shift }
}

my $foo = Foo->new;
print $foo->name;

