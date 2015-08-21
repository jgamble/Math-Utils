package Math::Utils;

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	fortran => [ qw(log10 copysign) ],
	compare => [ qw(generate_fltcmp generate_relational) ],
	utility => [ qw(sign) ],
	polynomial => [ qw(horner pl_add pl_sub pl_div) ],
);

our @EXPORT_OK = (
	@{ $EXPORT_TAGS{fortran} },
	@{ $EXPORT_TAGS{compare} },
	@{ $EXPORT_TAGS{utility} },
	@{ $EXPORT_TAGS{polynomial} },
);

our $VERSION = '0.02';

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
    my(undef, undef,
        $apx_gt, undef, $apx_lt) = generate_relational(1.5e-5);

or

    use Math::Utils qw(:utility);    # Other useful functions

    $dir = sign($z - $w);

    @ternaries = sign(@coefficients);


=head1 EXPORT

All functions can be exported by name, or by using a tag that they're
grouped under.

=cut

=head2 utility tag

=head3 sign()

  $s = sign($x);
  @slist = sign(@values);

Returns -1 if the argument is negative, 0 if the argument is zero, and 1
if the argument is positive.

In list form applies the same operation to each member of the list.

=cut

sub sign
{
	return wantarray? map(($_ < 0)? -1: (($_ > 0)? 1: 0), @_):
		($_[0] < 0)? -1: (($_[0] > 0)? 1: 0);
}

=head2 fortran tag

These are functions that originated in FORTRAN, and were implented
in Perl in the module L<Math::Fortran>, by J. A. R. Williams.

They are here with a name change -- copysign() was known as sign()
in Math::Fortran.

=head3 copysign()

  $ms = copysign($m, $n);
  $s = copysign($x);
 
Take the sign of the second argument and apply it to the first. Zero
is considered part of the positive signs.

    copysign(-5, 0);  # Returns 5.
    copysign(-5, 7);  # Returns 5.
    copysign(-5, -7);  # Returns -5.
    copysign(5, -7);  # Returns -5.

If there is only one argument, return -1 if the argument is negative,
otherwise return 1. For example, copysign(1, -4) and copysign(-4) both
return -1.

=cut

sub copysign
{
	return ($_[1] < 0)? -abs($_[0]): abs($_[0]) if (@_ == 2);
	return ($_[0] < 0)? -1: 1;
}

=head3 log10()

  $xlog10 = log10($x);
  @xlog10 = log10(@x);

Return the log base ten of the argument. A list form of the function
is also provided.

=cut

sub log10
{
	my $log10 = log(10);
	return wantarray? map(log($_)/$log10, @_): log($_[0])/$log10;
}

=head2 compare tag

Create comparison functions for floating point (non-integer) numbers.

Since exact comparisons of floating point numbers tend to be iffy,
the comparison functions use a tolerance chosen by you. You may then
use the functions from then on confident that comparisons will be
consistent.

If you do not pass in a tolerance, a default tolerance of 1.49-e8
(approximately the square root of an Intel Pentium's
L<machine epsilon|http://en.wikipedia.org/wiki/Machine_epsilon/>)
will be used.

=head3 generate_fltcmp()

Returns a comparison function that will compare values using a tolerance
that you supply. The generated function will return -1 if the first
argument compares as less than the second, 0 if the two arguments
compare as equal, and 1 if the first argument compares as greater than
the second.

  my $fltcmp = generate_fltcmp(1.5e-7);

  my(@xpos) = grep {&$fltcmp($_, 0) == 1} @xvals;

=cut

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

=head3 generate_relational()

Returns a list of comparison functions that will compare values using a
tolerance that you supply. The generated functions will be the equivalent
of the equal, not equal, greater than, greater that or equal, less than,
and less than or equal operators.


  my($eq, $ne, $gt, $ge, $lt, $le) = generate_relational(1.5e-7);

  my(@approx_5) = map {&$eq($_, 5)} @xvals;

Of course, if you were only interested in not equal, you could use:

  my(undef, $ne) = generate_relational(1.5e-7);

  my(@not_around5) = grep {&$ne($_, 5)} @xvals;

Internally, the functions all created using generate_fltcmp().

=cut

sub generate_relational
{
	my $fltcmp = generate_fltcmp($_[0]);

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


=head2 polynomial tag

Perform some polynomial operations on plain lists of coefficients.

The coefficient lists are presumed to go from low order to high, e.g.:

    1 + 2x + 4x**2 + 8x**3

becomes

    (1, 2, 4, 8)

In all functions the coeffcient list is passed by reference to the function.

It is assumed that any leading zeros in the coefficient lists have
already been removed before calling these functions, and that any leading
zeros found in the returned lists will be handled by the caller.

=head3 horner()

    $y = horner(\@coefficients, $x);
    @yvalues = horner(\@coefficients, \@xvalues);
   
Returns either a y-value for a corresponding x-value, or a list of
y-values on the polynomial for a corresponding list of x-points,
using Horner's method.

=cut

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

=head3 pl_add()

    $polyn_ref = pl_add(\@m, \@n);
   
Add two lists of numbers as though they were polynomial coefficients.

=cut

sub pl_add
{
	my(@av) = @{$_[0]};
	my(@bv) = @{$_[1]};
	my $ldiff = scalar @av - scalar @bv;

	my @result = ($ldiff < 0)?
		splice(@bv, scalar @bv + $ldiff, -$ldiff):
		splice(@av, scalar @av - $ldiff, $ldiff);

	unshift @result, map($av[$_]+$bv[$_], 0..scalar @av);

	return \@result;
}

=head3 pl_sub()


    $polyn_ref = pl_sub(\@m, \@n);
    
Subtract the second list of numbers from the first as though they were polynomial coefficients.

=cut

sub pl_sub
{
	my(@av) = @{$_[0]};
	my(@bv) = @{$_[1]};
	my $ldiff = scalar @av - scalar @bv;

	my @result = ($ldiff < 0)?
		splice(@bv, scalar @bv + $ldiff, -$ldiff):
		splice(@av, scalar @av - $ldiff, $ldiff);

	unshift @result, map($av[$_]-$bv[$_], 0..scalar @av);

	return \@result;
}

=head3 pl_div()

    ($q_ref, $r_ref) = pl_div(\@coefficients1, \@coefficients2);
 
Synthetic division for polynomials. Divides the first list of coefficients
by the second list.

Returns references to the quotient and the remainder.
   
=cut

sub pl_div
{
	my @numerator = @{$_[0]};
	my @divisor = @{$_[1]};

	my @quotient;

	my $n_degree = $#numerator;
	my $d_degree = $#divisor;
	my $q_degree = $n_degree - $d_degree;

	#
	# Sanity check if either set of coefficients
	# are empty lists.
	#
	return ([0], \@numerator) if ($q_degree < 0);
	return (undef, undef) if ($d_degree < 0);

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

	return (\@quotient, \@numerator);
}

=head3 pl_derivative()

    $poly_ref = pl_derivative(\@coefficients)

Returns the derivative of a polynomial.

=cut

sub poly_derivative
{
	my @coefficients = @_;
	my $degree = $#coefficients;

	return [] if ($degree <= 1);

	$coefficients[$_] *= $_ for (2..$degree);

	shift @coefficients;
	return \@coefficients;
}

=head3 pl_antiderivative()

    $poly_ref = pl_antiderivative(\@coefficients)

Returns the antiderivative of a polynomial. The constant value is
always set to zero and will need to be changed by the caller if a
different constant is needed.

=cut

sub pl_antiderivative
{
	my @coefficients = @{$_[0]};
	my $degree = scalar @coefficients;
	my $n = 1;

	#
	# Sanity check if its an empty list.
	#
	return [0] if ($degree < 1);

	$coefficients[$_] /= ++$n for (1..$degree - 1);

	unshift @coefficients, 0;
	return \@coefficients;
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

Copyright 2015 by John M. Gamble


=cut

1; # End of Math::Utils
