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
);

our @EXPORT_OK = (
	@{ $EXPORT_TAGS{fortran} },
	@{ $EXPORT_TAGS{compare} },
	@{ $EXPORT_TAGS{utility} },
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
in Perl in the module Math::Fortran, by J. A. R. Williams.

They are here with a name change -- copysign() was known as sign()
in Math::Fortran.

=head3 copysign()

  $ms = copysign($m, $n);
  $s = copysign($x);
 
Take the sign of the second argument and apply it to the first.

If there is only one argument, return -1 if the argument is negative,
otherwise return 1.

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

Create a comparison function for floating point (non-integer) numbers.

Since exact comparisons of floating point numbers tend to be iffy,
the functions returns a comparison function using a tolerance chose
by the programmer. The programmer may then use that function from
then on confident that comparisons will be consistent.

If the programmer does not pass in a tolerance, the comparison function
returned will have a default tolerance of 1.49-e8, which is roughly
the square root of the machine epsilon on Intel's Pentium chips.

=head3 generate_fltcmp()

Returns a comparison function that will compare values using a tolerance
that you supply. The generated function will return -1 if the first
argument compares as less than the second, 0 if the two arguments
compare as equal, and 1 if the first argument compares as greater than
the second.

  my $fltcmp = generate_fltcmp(1.5e-7);

  my(@xpos) = map {&$fltcmp($_, 0) == 1} @xvals;

If you do not provide a tolerance, a default tolerance of 1.49e-8
(approximately the square root of an Intel Pentium's
L<machine epsilon|http://en.wikipedia.org/wiki/Machine_epsilon/>) will be used.

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

  my(@not_around5) = map {&$ne($_, 5)} @xvals;

Internally, the functions all created using generate_fltcmp().

=cut

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
