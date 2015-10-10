#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 33;

use Math::Utils qw(:compare);

my $fltcmp = generate_fltcmp();         # Use default tolerance.

ok(&$fltcmp(sqrt(2), 1.414213562) == 0, "sqrt(2) check.");

my($eq, $ne, $gt, $ge, $lt, $le) = generate_relational(1.0e-6);

my $x = 0;
my $y = 0.25;

for (0 .. 15)
{
	ok(&$lt($x, $y), "$x < $y check.");
	ok(&$gt(-$x, -$y), "-$x > -$y check.");

	$x += 1/64;
}

