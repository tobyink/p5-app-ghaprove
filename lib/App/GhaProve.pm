use 5.006;
use strict;
use warnings;

package App::GhaProve;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

sub _system { scalar system( @_ ) }

sub go {
	my ( @args ) = @_;
	my $system = ref( $args[0] ) eq 'CODE' ? shift(@args) : \&_system;
	
	my $testing_mode = $ENV{GHA_TESTING_MODE}  || 0;
	my $coverage     = $ENV{GHA_TESTING_COVER} || 0;
	
	if ( $coverage =~ /^(true|1)$/i ) {
		if ( length $ENV{HARNESS_PERL_SWITCHES} ) {
			$ENV{HARNESS_PERL_SWITCHES} .= ' ';
		}
		else {
			$ENV{HARNESS_PERL_SWITCHES} = '';
		}
		$ENV{HARNESS_PERL_SWITCHES} .= '-MDevel::Cover';
	}
	
	my @errors;
	
	if ( $testing_mode !~ /^(extended|1)$/i ) {
		delete $ENV{EXTENDED_TESTING};
		print "# ~~ Standard testing\n";
		push @errors, $system->( 'prove', @args );
	}

	if ( $testing_mode =~ /^(extended|both|1|2)$/i ) {
		$ENV{EXTENDED_TESTING} = 1;
		print "# ~~ Extended testing\n";
		push @errors, $system->( 'prove', @args );
	}
	
	my ( $max ) = sort { $b <=> $a } @errors;
	
	if ( $max > 254 ) {
		$max = 254;
	}
	
	return $max;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::GhaProve - provides gha-prove app

=head1 SYNOPSIS

From command-line:

  $ gha-prove -b -r -v 't'
  ...

In script:

  use App::GhaProve;
  my @args = qw( -b -r -v t );
  my $exit = 'App::GhaProve'->go( @args );
  exit( $exit );

With a callback (instead of C<< CORE::system >>):

  use App::GhaProve;
  my @args = qw( -b -r -v t );
  my $exit = 'App::GhaProve'->go( sub { ... }, @args );
  exit( $exit );

=head1 DESCRIPTION

C<< gha-prove >> is just a small wrapper around the C<< prove >> command.
It will inspect C<< GHA_* >>> environment variables and this will affect
how it calls C<< prove >>, perhaps calling C<< prove >> multiple times.
It is intended to be used in continuous integration environments, such as
GitHub Actions.

=head1 ENVIRONMENT

=over

=item C<< GHA_TESTING_COVER=1 >> or C<< GHA_TESTING_COVER=true >>

Turn on Devel::Cover.

=item C<< GHA_TESTING_MODE=0 >> or C<< GHA_TESTING_MODE=standard >> 

Run test suite without EXTENDED_TESTING.

=item C<< GHA_TESTING_MODE=1 >> or C<< GHA_TESTING_MODE=extended >> 

Run test suite with EXTENDED_TESTING=1.

=item C<< GHA_TESTING_MODE=2 >> or C<< GHA_TESTING_MODE=both >> 

Run test suite twice, using each of the above.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=App-GhaProve>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

