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
my $numItems;
my $numTimeUnits;
my $numTotalItems;
my $numUsers;
my $probability;
my $startTime;
my $totalFrequency;
my $trainSize;
my $user;
my $userId;

my @items;

my %hashOfItems;
my %trainItems;

### Verify input parameters
die usage() if $#ARGV != 2;

### Retrieve input parameters

# Open input file
open FIN, "<". $ARGV[0] or die "Can't open the input file $ARGV[0]!";

open FOUT, ">". $ARGV[1] or die "Can't open the output file $ARGV[1]!";

my $TRAIN_PERCENTAGE = $ARGV[2];

$totalFrequency = 0;
while( defined($line = <FIN>) ){
	chomp($line);
     
	($userId, $numTimeUnits, $numTotalItems) = split(/[ \t]/, $line);

	$numItems = 0;
	$trainSize = $TRAIN_PERCENTAGE * $numTotalItems;
	for($i=0; $i<$numTimeUnits; $i++){

		if( !(defined($line = <FIN>)) ){
			print "\n\t***ERROR; not expected end of file!!!\n\n";
			exit;
		}

		chomp($line);
		($userId, $startTime, $endTime, @items) = split(/[ \t]/,$line);

		foreach $item ( @items ){
			 ($itemId, $count) = split(/:/,$item);

			if( !exists($trainItems{$itemId}) ){
				$trainItems{$itemId} += $count;
			}
			else{
				$trainItems{$itemId} = $count;
			}

			$numItems++;
		}

		splice(@items);

		if($numItems >= $trainSize){
			last;
		}
	}

	for($i=$i+1;$i<$numTimeUnits; $i++){

		if( !(defined($line = <FIN>)) ){
			print "\n\t***ERROR; not expected end of file!!!\n\n";
			exit;
		}

		chomp($line);
		($userId, $startTime, $endTime, @items) = split(/[ \t]/,$line);

		foreach $item ( @items ){
			 ($itemId, $count) = split(/:/,$item);

			$frequency = 0;
			if( exists($trainItems{$itemId}) ){
				$frequency = sprintf("%.1f", $trainItems{$itemId});
			}

			if( exists($hashOfItems{$frequency}) ){
				$hashOfItems{$frequency} += $count;
			}
			else{
				$hashOfItems{$frequency} = $count;
			}

			$totalFrequency += $count;
		}

		splice(@items);
	}

}
close(FIN);

foreach $frequency ( sort { $a <=> $b} (keys(%hashOfItems)) ){
	$probability = $hashOfItems{$frequency}/$totalFrequency;
	print FOUT $frequency, "\t", (1-$probability)/$probability, "\n";
}
close(FOUT);

sub usage{
	print "\nIn order to run this script you should give 3 input parameters:\n";
	print " \tInput data file name\n";
	print " \tOutput data file name \n";
	print " \tPercentage of training set \n\n";
};
