#!/bin/perl
use strict;
use warnings;

### Declaration of variables
my $count;
my $endTime;
my $frequency;
my $i;
my $item;
my $itemId;
my $line;
my $numTimeUnits;
my $numTotalItems;
my $probability;
my $startTime;
my $totalFrequency;
my $userId;

my @items;

my %hashOfItems;
my %userHistory;

### Verify input parameters
die usage() if $#ARGV != 1;

### Retrieve input parameters

# Open input file
open FIN, "<". $ARGV[0] or die "Can't open the input file $ARGV[0]!";

open FOUT, ">". $ARGV[1] or die "Can't open the output file $ARGV[1]!";

$totalFrequency = 0;
while( defined($line = <FIN>) ){
	chomp($line);
     
	($userId, $numTimeUnits, $numTotalItems) = split(/[ \t]/, $line);

	for($i=0; $i<$numTimeUnits; $i++){

		if( !(defined($line = <FIN>)) ){
			print "\n\t***ERROR; not expected end of file!!!\n\n";
			exit;
		}

		chomp($line);
		($userId, $startTime, $endTime, @items) = split(/[ \t]/,$line);

		foreach $item ( @items ){
			 ($itemId, $count) = split(/:/,$item);

			if( !exists($userHistory{$itemId}) ){
				if( exists($hashOfItems{$itemId}) ){
					$hashOfItems{$itemId} += 1;
				}
				else{
					$hashOfItems{$itemId} = 1;
				}
				
				$userHistory{$itemId} = 1;
			}
		}

		splice(@items);
	}
	
	$totalFrequency+=1;
	%userHistory = ();
}
close(FIN);

foreach $item ( keys(%hashOfItems) ){
	print FOUT "$item\t", $hashOfItems{$item}/$totalFrequency, "\n";
}
close(FOUT);

sub usage{
	print "\nIn order to run this script you should give 2 input parameters:\n";
	print " \tInput data file name\n";
	print " \tOutput data file name \n\n";
};
