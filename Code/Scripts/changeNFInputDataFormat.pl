#!/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my $line;
my $userId;
my $startTime;
my $endTime;
my $item;
my $itemId;
my $score;

my @items;


#verifica o número de parametros informados
die usage() if $#ARGV != 1;

open FIN,"<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

open FOUT,">".$ARGV[1] or die "Can't open the output file $ARGV[1]!";

while( defined($line = <FIN>) ){
	chomp($line);

	($userId, $startTime, $endTime, @items) = split(/[ \t]/, $line);

	foreach $item (@items){
		($itemId, $score) = split(/:/, $item);

		print FOUT "$userId\t$itemId\t$score\t$startTime\n";
	}
	splice(@items);
}
close(FIN);
close(FOUT);

sub usage{
        print "\nIn order to run this script you should give 2 input parameters:\n";
        print "\tInput file name \n";
        print "\tOutput file name\n\n";
}
