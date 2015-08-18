#!perl -T
use 5.008003;
use strict;
use warnings;
use Test::More tests => 1;

use Math::Utils qw(:compare);

my $fltcmp = generate_fltcmp();         # Use default tolerance.

ok(&$fltcmp(sqrt(2), 1.414213562) == 0, "sqrt(2) check.");

