#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );
}

# NOTE:

# This test proves that traits can work under mod_perl, if care is taken about
# how things are loaded. All traits should be imported from within your
# startup file, and then the Class::Trait->initialize() method should be
# called after all are loaded. This should result in the correct behavior.

{

    local $SIG{__WARN__} = sub {
        my $msg = shift;
        if ( $msg =~ /^Too late to run INIT block/ ) {
            pass('... got the expected warning');
            return;
        }
        else {
            warn $msg;
        }
    };

    eval "use BasicTrait;";

    ok( BasicTrait->does("TSimple"), '.. BasicTrait is TSimple' );
}
