#!/bin/perl
use strict;
use warnings;

### Declaration of variables
my $count;
my $distance;
my $endTime;
my $i;
my $item;
my $itemId;
my $k;
my $line;
my $meanInterval;
my $numItems;
my $numOccurrences;
my $numTimeUnits;
my $numTotalItems;
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
				$trainItems{$itemId}[0] += 1;
			}
			else{
				$trainItems{$itemId}[0] = 1;
			}
			$trainItems{$itemId}[$trainItems{$itemId}[0]] = $startTime;

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

			if( exists($trainItems{$itemId}) ){
				$numOccurrences = $trainItems{$itemId}[0];
				if($numOccurrences > 1){
					$meanInterval = 0;
					for($k=2; $k<=$numOccurrences; $k++){
						$meanInterval += $trainItems{$itemId}[$k] - $trainItems{$itemId}[$k-1];
					}
					$meanInterval = sprintf("%.2f",$meanInterval/($numOccurrences-1));
					$distance = sprintf("%.2f",$startTime - $trainItems{$itemId}[$numOccurrences]);

					if( exists($hashOfItems{$distance}{$meanInterval}) ){
						$hashOfItems{$distance}{$meanInterval} += 1;
					}
					else{
						$hashOfItems{$distance}{$meanInterval} = 1;
					}

					$totalFrequency += 1;
				}
			}

		}
		splice(@items);
	}

}
close(FIN);

foreach $distance ( sort {$a <=> $b} (keys(%hashOfItems)) ){
	foreach $meanInterval ( sort { $a <=> $b} (keys(%{$hashOfItems{$distance}})) ){
		$probability = $hashOfItems{$distance}{$meanInterval}/$totalFrequency;
		print FOUT $distance, "\t", $meanInterval, "\t", (1-$probability)/$probability, "\n";
	}
}
close(FOUT);

sub usage{
	print "\nIn order to run this script you should give 3 input parameters:\n";
	print " \tInput data file name\n";
	print " \tOutput data file name \n";
	print " \tPercentage of training set \n\n";
};
