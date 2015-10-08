#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 6;

use Math::Utils qw(copysign);

my $sn = copysign(-12);
ok($sn == -1, "copysign(-12) returned $sn");

$sn = copysign(12);
ok($sn == 1, "copysign(12) returned $sn");

$sn = copysign(0);
ok($sn == 1, "copysign(0) returned $sn");

$sn = copysign(-12, 5);
ok($sn == 12, "copysign(-12, 5) returned $sn");

$sn = copysign(12, -5);
ok($sn == -12, "copysign(12, -5) returned $sn");

$sn = copysign(-12, 0);
ok($sn == 12, "copysign(-12, 0) returned $sn");

