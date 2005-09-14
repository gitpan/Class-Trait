#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

# dont bother testing Class::Trait itself
# as none of the methods are really public
# and all interaction is done through the 
# 'import' interface anyway.

plan tests => 6;

pod_coverage_ok('Class::Trait::Config');
pod_coverage_ok('Class::Trait::Base');

# we wrap this in a block and 
# turn off warnings, so that we 
# dont get warned that Class::Trait
# is loaded after it is too late to
# run INIT, we know this happens and
# it just doesn't really affect this 
# test at all
{
    local $SIG{__WARN__} = sub {
        my $msg = shift;
        return if ($msg =~ /^Too late to run INIT block/);
        CORE::warn $msg;
    };
    
    pod_coverage_ok('Class::Trait::Reflection');
}

pod_coverage_ok('Class::Trait::Lib::TEquality');
pod_coverage_ok('Class::Trait::Lib::TPrintable');
pod_coverage_ok('Class::Trait::Lib::TComparable');