
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => ( 4 * 4 ) + ( 2 * 4 );
use strict;
use warnings;

# modules that we need
use String::Lookup;

# initializations
my $foo= 'foo';
my $bar= 'bar';

# all permutations for offset / increment check
foreach (
  [   0, 10,  10,  20 ],
  [   1,  5,   6,  11 ],
  [ 100,  0, 101, 102 ],
  [ 314,  1, 315, 316 ],
) {
    my ( $offset, $increment, $id_foo, $id_bar )= @{$_};

    # set up the hash
    tie my %hash, 'String::Lookup',
      offset    => $offset,
      increment => $increment;

    # check lookups
    is( $hash{ \$foo }, $id_foo, 'simple string lookup' );
    is( $hash{$id_foo}, $foo,    'simple id lookup' );
    is( $hash{ \$bar }, $id_bar, 'another simple string lookup' );
    is( $hash{$id_bar}, $bar,    'another simple id lookup' );
}

# all permutations for init / offset check
foreach (
  [  5, 11 ],
  [ 15, 16 ],
) {
    my ( $offset, $id )= @{$_};

    # set up the hash
    tie my %hash, 'String::Lookup',
      init   => { $foo => 10 },
      offset => $offset;

    # check lookup
    is( $hash{ \$foo },  10, 'string lookup after init' );
    is( $hash{10},     $foo, 'id lookup after init' );
    is( $hash{ \$bar }, $id, 'another string lookup after init' );
    is( $hash{$id},    $bar, 'another id lookup after init' );
}
