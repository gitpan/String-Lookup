require 5.014;
use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "String::Lookup",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> "convert strings to ID's authoritatively and vice-versa",
 VERSION_FROM	=> 'lib/String/Lookup.pm',
 LICENSE	=> 'perl',

 PREREQ_PM	=> {qw(
                   )},
);
