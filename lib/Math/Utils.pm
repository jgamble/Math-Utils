package Math::Utils;

use 5.008003;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	fortran => [ qw(log10 copysign) ],
	compare => [ qw(generate_fltcmp generate_relational) ],
	utility => [ qw(sign) ],
	polynomial => [ qw(horner addcf subcf divcf) ],
);

our @EXPORT_OK = (
	@{ $EXPORT_TAGS{fortran} },
	@{ $EXPORT_TAGS{compare} },
	@{ $EXPORT_TAGS{utility} },
	@{ $EXPORT_TAGS{polynomial} },
);

our $VERSION = '0.01';

=head1 NAME

Math::Utils - Useful computational or mathematical functions.

=head1 SYNOPSIS

    use Math::Utils qw(:fortran);    # Functions originated from Fortran

    #
    # $dist will be negative or positive $offest, depending
    # on whether ($from - $to) is positive or negative.
    #
    my $dist = 2 * copysign($offset, $from - $to);

    #
    # Base 10 logarithm.
    #
    my $scale = log10($pagewidth);

or

    use Math::Utils qw(:compare);    # Make comparison functions with tolerance.

    #
    # Floating point comparison function.
    #
    my $fltcmp = generate_fltmcp(1.0e-7);

    if (&$fltcmp($x0, $x1) < 0)
    {
        add_left($data);
    }
    else
    {
        add_right($data);
    }

    #
    # Or we can create single-operation comparison functions.
    #
    # Here we are only interested in the greater than and less than
    # comparison functions.
    #
    my(undef, undef, $apx_gt, undef, $apx_lt) = generate_relational(1.5e-5);

or

    use Math::Utils qw(:utility);    # Other useful functions

    $dir = sign($z - $w);

    @ternaries = sign(@coefficients);


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=cut


#
# @slist = sign(@values);
# $s = sign($x);
#
sub sign
{
	return wantarray? map(($_ < 0)? -1: (($_ > 0)? 1: 0), @_):
		($_[0] < 0)? -1: (($_[0] > 0)? 1: 0);
}

#
# $s = copysign($x);
# $ms = copysign($m, $n);
#
sub copysign
{
	return ($_[1] < 0)? -abs($_[0]): abs($_[0]) if (@_ == 2);
	return ($_[0] < 0)? -1: 1;
}

#
# $xlog10 = log10($x);
# @xlog10 = log10(@x);
#
sub log10
{
	my $log10 = log(10);
	return wantarray? map(log($_)/$log10, @_): log($_[0])/$log10;
}

#
# Create a comparison function for floating point (non-integer) numbers.
#
# Since exact comparisons of floating point numbers tend to be iffy,
# the functions returns a comparison function using a tolerance chose
# by the programmer. The programmer may then use that function from
# then on confident that comparisons will be consistent.
#
# If the programmer does not pass in a tolerance, the comparison function
# returned will have a default tolerance of 1.49-e8, which is roughly
# the square root of the machine epsilon on Intel's Pentium chips.
#
sub generate_fltcmp
{
	my $tol = $_[0] // 1.49e-8;

	return sub {
		my($x, $y) = @_;
		return -1 if ($x + $tol < $y);
		return 1 if ($x - $tol > $y);
		return 0;
	}
}

sub generate_relational
{
	my $tol = $_[0] // 1.49e-8;
	my $fltcmp = generate_fltcmp($tol);

	#
	# In order: eq, ne, gt, ge, lt, le.
	#
	return (
		sub {return &$fltcmp(@_) == 0;},	# eq
		sub {return &$fltcmp(@_) != 0;},	# ne
		sub {return &$fltcmp(@_) >  0;},	# gt
		sub {return &$fltcmp(@_) >= 0;},	# ge
		sub {return &$fltcmp(@_) <  0;},	# lt
		sub {return &$fltcmp(@_) <= 0;},	# le
	);
}

#
# $mdn = dotp(\@m, \@n);
#
sub dotp
{
	my(@av) = @{$_[0]};
	my(@bv) = @{$_[1]};
	my $len = scalar @av;
	my $d = 0;

	if (scalar @bv == $len)
	{
		$d += $av[$_] * $bv[$_] for (0 .. $len);
	}
	return $d;
}

#
# @results = horner(\@coefficients, \@xvalues);
# $result = horner(\@coefficients, $xvalue);
#
# Returns a list of y-points on the polynomial for a corresponding
# list of x-points, using Horner's method.
#
sub horner
{
	my @coefficients = @{$_[0]};
	my $xval_ref = $_[1];

	my @values;

	#
	# It could happen. Someone might type \$x instead of $x.
	#
	@values = (ref $xval_ref eq "ARRAY")? @$xval_ref:
		(((ref $xval_ref eq "SCALAR")? $$xval_ref: $xval_ref));

	#
	# Move the leading coefficient off the polynomial list
	# and use it as our starting value(s).
	#
	my @results = (pop @coefficients) x scalar @values;

	foreach my $c (reverse @coefficients)
	{
		foreach my $j (0..$#values)
		{
			$results[$j] = $results[$j] * $values[$j] + $c;
		}
	}

	return wantarray? @results: $results[0];
}

#
# @p = addcf(\@m, \@n);
#
# Add two lists of numbers as though they were polynomial coefficients.
# The coefficient lists are presumed to go from low order to high, e.g.:
#     1 + 2x + 4x**2 + 8x**3
# becomes
#     (1, 2, 4, 8);
#
sub addcf
{
	my(@av) = @{$_[0]};
	my(@bv) = @{$_[1]};
	my $ldiff = scalar @av - scalar @bv;

	my @result = ($ldiff < 0)? splice(@bv, scalar @bv + $ldiff, -$ldiff): splice(@av, scalar @av - $ldiff, $ldiff);
	unshift @result, map($av[$_]+$bv[$_], 0..scalar @av);

	return \@result;
}

#
# @p = subcf(\@m, \@n);
# 
# The coefficient lists are presumed to go from low order to high, e.g.:
#     1 + 2x + 4x**2 + 8x**3
# becomes
#     (1, 2, 4, 8);
#
sub subcf
{
	my(@av) = @{$_[0]};
	my(@bv) = @{$_[1]};
	my $ldiff = scalar @av - scalar @bv;

	my @result = ($ldiff < 0)? splice(@bv, scalar @bv + $ldiff, -$ldiff): splice(@av, scalar @av - $ldiff, $ldiff);
	unshift @result, map($av[$_]-$bv[$_], 0..scalar @av);

	return \@result;
}

#
# ($q_ref, $r_ref) = divcf(\@coefficients1, \@coefficients2);
#
# Synthetic division for polynomials. Returns references to the quotient
# and the remainder.
#
# Polynomial coefficients are from low degree to high, e.g.:
#  ax^3 + bx^2 + cx + d
# are listed
#  @coefficients1 = (d, c, b, a);
#
sub divcf
{
	my @numerator = @{$_[0]};
	my @divisor = @{$_[1]};

	my @quotient;

	#
	# Just checking... removing any leading zeros.
	#
	pop @numerator while (@numerator);
	pop @divisor while (@divisor);

	my $n_degree = $#numerator;
	my $d_degree = $#divisor;
	my $q_degree = $n_degree - $d_degree;

	return ([0], \@numerator) if ($q_degree < 0);
	return (undef, undef) if ($d_degree < 0);

	#
	### poly_divide():
	#### @numerator
	#### by
	#### @divisor
	#
	my $lead_coefficient = $divisor[0];

	#
	# Perform the synthetic division. The remainder will
	# be what's left in the numerator.
	#
	for my $j (reverse 0..$q_degree)
	{
		#
		# Get the next term for the quotient. We shift
		# off the lead numerator term, which would become
		# zero due to subtraction anyway.
		#
		my $q = (pop @numerator)/$lead_coefficient;

		push @quotient, $q;

		for my $k (1..$d_degree)
		{
			$numerator[$k - 1] -= $q * $divisor[$k];
		}
	}

	#
	# And once again, check for leading zeros in the remainder.
	#
	pop @numerator while (@numerator);
	push @numerator, 0 unless (@numerator);

	return (\@quotient, \@numerator);
}


=head1 AUTHOR

John M. Gamble, C<< <jgamble at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-util at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 by John M. Gamble

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Math::Utils
