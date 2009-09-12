package Args;
use strict;
use warnings;
use vars qw($default_arg $ARGS @ARGS %arg %arg2);

# no exports

$Args::Simple::VERSION = "1.0";

$default_arg = "1E0";

sub process_args {
  @_ = @ARGV if @_ == 0;
  @ARGS = @_;
  $ARGS = join(" ",@ARGS);
  %arg = %arg2 = ();
  my @ARG = ();
  foreach my $arg (@ARGS) {
    if (length($arg) > 1 
	&& substr($arg,0,1) eq "-"
	&& substr($arg,1,1) !~ /\d/) {   # don't treat -4, -3.14159 as switch!

      if (substr($arg,1,1) eq "-") {

	my ($k,$v) = split /=/, substr($arg,2);
	$v = $default_arg if !defined $v;
	$k = "" if !defined $k;  # handle  '--'  argument
	$arg{$k} = $v;
	$arg2{$k}{$v}++;   # %Args::arg2 is undocumented feature

      } else {

	my $k = substr($arg,1,1);
	my $v = substr($arg,2);
	$v = $default_arg if $v eq "";
	$arg{$k} = $v;
	$arg2{$k}{$v}++;   # %Args::arg2 for handling duplicates

      }
    } else {

      push @ARG, $arg;

    }
  }
  @ARGV = @ARG;
}

sub debug_args {
  print STDERR "\$ARGS::ARGS are $ARGS::ARGS\n\n";
  print STDERR "\@ARGS::ARGS are ";
  print STDERR join " ", @ARGS::ARGS;
  print STDERR "\n\n";
  print STDERR "\%ARGS::arg are:\n";
  foreach my $k (sort keys %ARGS::arg) {
    print STDERR "\t\t$k\t\t$ARGS::arg{$k}\n";
  }
  print STDERR "\n";

}

sub Args::Simple::import {
  &process_args(@_);
}

1;

__END__
=head1 NAME

Args::Simple - quick, dirty, and convenient command-line argument parser

=head1 VERSION

Version 1.0

=head1 SYNOPSIS

  use Args::Simple;
  use Args::Simple @args;

  if (defined $Args::arg{$key}) {
    print "You specified the argument 
  }

=head1 DESCRIPTION

Populates the C<%Args::arg> table with values from C<@ARGV> 
(command-line
arguments) that match  "--<key>", "--<key>=<value>",
"-<k>", or "-<k><value>"  where C<key> and C<value> are arbitary
strings of code, and C<k> is an arbitrary one character string.
Consumes these arguments from C<@ARGV> and returns the arguments
that were not consumed.

Unlike some other command-line processing modules in CPAN,
C<Args::Simple> does not require any pre-specification of the options
that the script will accept, and it makes it convenient to make
quick changes like this:

    # old version
    $n = 15;
    $result = doSomething($n);
    print "The results of something were $result\n";

    # new version
    #   1. lets user override default $n value with  -n<x> or --n=<x>  options
    #   2. suppresses output if  --quiet  argument is supplied
    $n = $Args::arg{"n"} || 15;
    $result = doSomething();
    print "The results of something were $result\n" unless $Args::arg{"quiet"};

without needing to specify ahead of time that the program will
accept the "n" and "quiet" arguments.

The fact that command-line options are consumed makes it convenient
to add option handling to your program at any time. For example,
suppose you have a script that expects 2 or 3 arguments. But then
you decide it would be convenient to do some additional configuration
of the script using some command-line switches. Your script may
still continue to use code like:

    ($input,$output,$n) = @ARGV;
    if (!defined $n) {
        warn "Third argument not provided. Assuming 15.\n";
        $n = 15;
    }

while handling any command-line options that you specify and without
needing to check if the items in C<@ARGV> are regular arguments
or command-line switches.

=head1 AN EXAMPLE

Let's look at this simple script to see how the C<Args::Simple> module
handles different command-line arguments:

    # demo-Args.pl: print out how the Args module handles @ARGV
    use Args::Simple;
    foreach $arg (sort keys %Args::arg) {
        print "Command-line argument: $arg = $Args::arg{$arg}\n";
    }
    print "\@ARGV is [\"", join '","', @ARGV, "\"]\n";

Running the script:

    perl demo-Args.pl file1 --key=value --arg -b -n40 -stop file2

will produce the output:

    Command-line argument: arg = 1E0
    Command-line argument: b = 1E0
    Command-line argument: key = value
    Command-line argument: n = 40
    Command-line argument: s = top
    @ARGV is ["file1","file2"]

=head1 EXPLANATION OF EXAMPLE

All the command-line arguments that began with a C<-> (dash) were
used to populate C<%Args::arg> and were removed from C<@ARGV>.
Any arguments that did not begin with a dash were returned in
C<@ARGV>. There were four different styles of command line
arguments that were handled by this example:

=over 4

=item --<key>

For command-line arguments that begin with C<--> and do not
contain an C<=> (equals) character, a value of C<$Args::default_arg>
is assigned to $Args::arg{C<key>}. C<$Args::default_arg>
is a special value that evaluates to 1 in a numeric context but
not to C<1> in a string context. See the section on
C<$Args::default_arg> below. Thus the arguments

    --no-print --verbose

will populate C<%Args::arg> with the values

     "no-print" => "1E0"
     "verbose"  => "1E0"



=item -<k>

For command-line arguments that consist of a single dash followed
by a single character, the value of C<$Args::default_arg>
is assigned to $Args::arg{C<k>}. So the arguments

    -b -c -d

will populate C<%Args::arg> with the values

    "b" => "1E0"
    "c" => "1E0"
    "d" => "1E0"

B<Note>: If the single character is a digit (0-9), then the
argument is B<not> treated like a command-line switch
and it will propagate to C<@ARGV>. There are plenty of
scripts that want to be able to take a negative number as
an argument, so for this module to consume those arguments
would probably be the wrong thing to do. If you B<do> wish
to use a single digit as a switch, you can always specify
the option with a double-dash, i.e.

    --4

instead of

    -4 .

=item --<key>=<value>

Command-line arguments that begin with C<--> and contain an C<=>
(equals) character are parsed as a key-value pair. The value will
be assigned to $Args::arg{C<key>}. For example the arguments

    --water=wet --fire=hot --one=1 --5=five

will populate C<%Args::arg> with the values

    "water" => "wet"
    "fire"  => "hot"
    "one"   => "1"
    "5"     => "five"

=item -<k><value>

For command-line arguments that begin with a single C<-> (dash)
followed by more than one character, the first character after
the dash is interpreted as the key, and the remaining characters
are used as the value for populating C<%Args::arg>. The
arguments

    -n30 -f/dev/null -quiet

will populate C<%Args::arg> with the values

    "n" => "30"
    "f" => "/dev/null"
    "q" => "uiet"

Note that some command-line processing schemes allow for
bundling of simple switches, that is, to say C<-rst>
to mean C<-r -s -t>. This type of bundling is not supported
by this module.

Also note that if the key character would be a digit (0-9), then the
argument will B<not> treated like a command-line switch
and it will propagate to C<@ARGV>. There are plenty of
scripts that want to be able to take a negative number as
an argument, so for this module to consume those arguments
would probably be the wrong thing to do. If you B<do> wish
to use a single digit as a switch, you can always specify
the option with a double-dash, i.e.

    --2=.71828182845905

instead of

    -2.71828182845905

=back

=head1 ADDITIONAL INFORMATION

The C<Args::Simple> module populates a few other variables 
of interest in the C<Args::> namespace.

=head2 $Args::default_arg

C<$Args::default_arg> is a special argument that evaluates to
1 in a numeric context but not to C<1> in a string context. 
This distinction allows you to determine whether an argument
was invoked as

    --key

or as

    --key=1 ,

should that distinction be important to you.

    # if program invoked with arguments:  --abc --def=1
    $Args::arg{"abc"}==1;     # true
    $Args::arg{"abc"} eq "1"; # false
    $Args::arg{"def"}==1;     # true
    $Args::arg{"def"} eq "1"; # true

=head2 @Args::ARGS and $Args::ARGS

The C<Args::Simple> module may consume the arguments that are originally
passed to the program. The list variable C<@Args::ARGS> stores
a copy of the original arguments in the original order. The
scalar variable C<$Args::ARGS> stores the original set of
command-line arguments in a scalar variable.

    if ($Args::ARGS =~ /john/i) {
        print "We mentioned John somewhere in the original command line\n";
    }

=head2 Special cases

Some other information about how the module handles
interesting sets of arguments.

=over 4

=item Repeated arguments

If the same argument key is specified more than once, only the
last value will be used to populate C<%Args::arg>. The complete
set of arguments will still be available in C<@Args::ARGS> (see
the above section).

    # invoke with --c=cookie -c6
    use Args::Simple;
    print $Args::arg{"c"};     #  will print "6"

=item Multiple equals signs

In an argument of the form C<--key=value1=value2>, only the
first equals sign is significant. The whole string C<value1=value2>
will become the value assigned to the C<key> in C<%Args::arg>.

=item Argument is a single dash

The argument C<-> is B<not> processed by the C<Args::Simple> module
and is returned in C<@ARGV>.

=item Argument is a double dash

The argument C<--> B<is> processed by the C<Args::Simple> module.
It assigns the default value (C<$Args::default_arg>) to
a key of the empty string in the C<%Args::arg> table.

=item Argument has a trailing equals sign

For an argument of the form C<--key=>, with no more characters
after the equals sign, a value of an empty string is assigned
to the key in the C<%Args::arg> table.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Marty O'Brien, all rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
