# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Args-Simple.t'

#########################

use Test::More tests => 27;

# test 1: module loads
BEGIN { use_ok('Args::Simple') };

#########################

# test 2-4: simple arguments
ok(!defined $Args::arg{'a'}, "trivial \%Args::arg starts clean");
Args::process_args(qw(-a --bcd));
ok($Args::arg{'a'} == 1 && $Args::arg{'a'} ne "1", "default -k arg");
ok($Args::arg{'bcd'} == 1 && $Args::arg{'bcd'} eq $Args::default_arg, "default --key arg");


# test 5-7: complex arguments
ok(!defined $Args::arg{'xyz'}, "trivial \%Args:arg not polluted");
Args::process_args(qw(--xyz=5 -xyz=5));
ok($Args::arg{'xyz'} == 5, "--key=value arg");
ok($Args::arg{'x'} eq "yz=5", "-kvalue arg");

# test 8: Args::process_args overwrites @ARGV
#         and options are consumed from @ARGV
@ARGV = (1,2,3,4);
Args::process_args(qw(--3=.1415926535 4 --5 6 -7.5 -8E6 --9 10));
#ok(@ARGV==3 && $ARGV[0]==4 && $ARGV[1]==6);
ok($ARGV[0]==4 && $ARGV[1]==6,    # update: -[0-9] passes, so -7.5, -8E6 also fall to @ARGV
	"overwrites \@ARGV and consumes from \@ARGV");
ok(@ARGV==5 && $ARGV[2] == -7.5 && $ARGV[3] == -8000000,
	"-[0-9] arguments are preserved");

# test 9-11: @Args::ARGS, $Args::ARGS populated
Args::process_args(qw(a -b --cde --fg=hi jkl));
ok(@ARGV == 2, "\@ARGV populated");
ok(@Args::ARGS == 5, "\@Args::ARGS populated");
ok($Args::ARGS eq "a -b --cde --fg=hi jkl", "\$Args::ARGS populated");

# test 12-13:  "-" is not treates an a switch
Args::process_args(qw(-));
ok("@ARGV" eq "-", "\"-\" argument preserved");
ok(0 == scalar keys %Args::arg, "\"-\" arg preserved");

# test 14-15: "--" argument
Args::process_args(qw(- --));
ok(defined $Args::arg{""}, "handle -- arg");
ok($Args::arg{""} eq $Args::default_arg, "handle -- arg");

# test 16-17: "---" argument
Args::process_args(qw(--- ----));
ok(defined $Args::arg{"-"} && defined $Args::arg{"--"}, "handle ---,---- args");
ok($Args::arg{"-"}==1 && $Args::arg{"--"} eq $Args::default_arg, "handle ---,---- args");

# test 18-25: trailing =, 0, true 0
Args::process_args(qw(--= --f1 --f2= --f3=0 -h1 -i0 -k0.0));
ok(defined $Args::arg{""} 
	&& defined $Args::arg{"f1"} 
	&& defined $Args::arg{"f2"}, "handle trailing =");
ok($Args::arg{""} eq "", "handle --= arg");
ok($Args::arg{"f1"} == 1 && $Args::arg{"f1"} eq $Args::default_arg, "handle default arg");
ok(!$Args::arg{"f2"} && $Args::arg{"f2"} ne "0", "handle trailing =");
ok(defined $Args::arg{"f3"} && !$Args::arg{"f3"}, "handle false 0");
ok(defined $Args::arg{"h"} && $Args::arg{"h"}, "handle 1");
ok(defined $Args::arg{"i"} && $Args::arg{"i"} == 0, "handle false 0");
ok(defined $Args::arg{"k"} && $Args::arg{"k"} && $Args::arg{"k"} == 0, "handle true 0");

# test 26: duplicate -- only last element should be saved in %Args::arg
Args::process_args(qw(-b1 -b2 --b=3 --b=456 -b));
ok($Args::arg{'b'} == 1 && $Args::arg{'b'} eq $Args::default_arg, "handle duplicates");

# end of tests
