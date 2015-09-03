#
# Test if the polynomial functions work with coefficients that are objects.
#
use Test::Simple tests => 1;

use Math::Utils qw(:polynomial);
use Math::Complex;
use strict;
use warnings;

#
# returns 0 (equal) or 1 (not equal). There's no -1 value, unlike other cmp functions.
#
sub polycmp
{
	my($p_ref1, $p_ref2) = @_;

	my @polynomial1 = @$p_ref1;
	my @polynomial2 = @$p_ref2;

	return 1 if (scalar @polynomial1 != scalar @polynomial2);

	foreach my $c1 (@polynomial1)
	{
		my $c2 = shift @polynomial2;
		return 1 if ($c1 != $c2);
	}

	return 0;
}

#
# (x + cplx(-3, 2)) * (x + cplx(3, 2)) = ?
#
my @c1x = (Math::Complex->new(-3, 2), 1);
my @c1y = (Math::Complex->new(3, 2), 1);

my @c1ans = (-13,
	Math::Complex->new(0, 4),
	1
);

my $ans_ref = pl_mult(\@c1x, \@c1y);

ok((polycmp($ans_ref, \@c1ans) == 0),
	" f() = [ " . join(", ", @c1x) . " ] * \n" .
	" f() = [ " . join(", ", @c1y) . " ] = \n" .
	" f'() = [ " . join(", ", @{$ans_ref}) . " ].\n"
);


1;

