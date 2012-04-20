
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 2 + 8 + 8 + 2 + 4;
use strict;
use warnings;

# modules that we need
use Scalar::Util qw( reftype );
use String::Lookup;

# initializations
my $foo= 'foo';
my $bar= 'bar';

# set up the hash
my $ro_hash;
my $object= tie my %hash, 'String::Lookup',
  flush => sub {
      my ( $list, $todo )= @_;
      is( reftype($list), 'ARRAY', 'first param in flush' );
      is( reftype($todo), 'ARRAY', 'second param in flush' );
      is( join( ',', @$list[ 1, 2 ] ), "$foo,$bar", 'strings in list' );
      is( join( ',', @{$todo} ), '1,2', 'strings in list' );
  };

isa_ok( $object, 'String::Lookup', 'check object of tie' );
$ro_hash= %hash;
is( reftype($ro_hash), 'HASH', 'check fast access hash' );

# string 1
ok( !exists $hash{ \$foo }, 'check non-existence of string' );
ok( !exists $hash{ 1     }, 'check non-existence of id' );
is( $hash{ \$foo },    1, 'simple string lookup' );
is( $hash{ \$foo },    1, 'same simple string lookup' );
is( $ro_hash->{$foo},  1, 'fast same simple string lookup' );
is( $hash{ 1     }, $foo,    'simple id lookup' );
ok( exists $hash{ \$foo }, 'check existence of string' );
ok( exists $hash{ 1     }, 'check existence of id' );

# string 2
ok( !exists $hash{ \$bar }, 'check non-existence of another string' );
ok( !exists $hash{ 2     }, 'check non-existence of another id' );
is( $hash{ \$bar },    2, 'another simple string lookup' );
is( $hash{ \$bar },    2, 'another same simple string lookup' );
is( $ro_hash->{$bar},  2, 'fast another same simple string lookup' );
is( $hash{ 2     }, $bar, 'another simple id lookup' );
ok( exists $hash{ \$bar }, 'check existence of another string' );
ok( exists $hash{ 2     }, 'check existence of another id' );

# checking error conditions
ok( !eval { $hash{ \$foo }= 3 }, 'check assignment error' );
diag $@
  if !ok( $@ =~ m#^Cannot assign values to a lookup hash#, 'right error?' );
