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
my $probability;
my $rankSize;
my $startTime;
my $trainSize;
my $user;
my $userId;

my @items;

my %hashOfItems;
my %hashOfOccurrence;
my %meanPerOccurrence;
my %stdDevPerRank;
my %numUsers;
my %trainItems;
my %totalFrequency;

### Verify input parameters
die usage() if $#ARGV != 2;

### Retrieve input parameters

# Open input file
open FIN, "<". $ARGV[0] or die "Can't open the input file $ARGV[0]!";

open FOUT, ">". $ARGV[1] or die "Can't open the output file $ARGV[1]!";

my $TRAIN_PERCENTAGE = $ARGV[2];

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

			if( !exists($trainItems{$userId}{$itemId}) ){
				$trainItems{$userId}{$itemId} = 0;
			}
			$trainItems{$userId}{$itemId} += $count;

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
			if( exists($trainItems{$userId}{$itemId}) ){
				$frequency = sprintf("%.2f", $trainItems{$userId}{$itemId});
			}

			if( !exists($hashOfItems{$userId}{$frequency}) ){
				$hashOfItems{$userId}{$frequency} = 0;
			}
			
			$hashOfItems{$userId}{$frequency} += $count;
			if( !exists($totalFrequency{$userId}) ){
				$totalFrequency{$userId} = 0;
			}
			$totalFrequency{$userId} += $count;
		}

		splice(@items);
	}

}
close(FIN);

foreach $user ( keys(%hashOfItems) ){

	foreach $frequency ( keys(%{$hashOfItems{$user}}) ){
	
		$probability = $hashOfItems{$user}{$frequency}/$totalFrequency{$user};
		$hashOfOccurrence{$userId}{$frequency} = (1-$probability)/$probability;

		if( !defined($meanPerOccurrence{$frequency}) ){
			$meanPerOccurrence{$frequency} = (1-$probability)/$probability;
			$numUsers{$frequency} = 1;
		}
		else{
			$meanPerOccurrence{$frequency} += (1-$probability)/$probability;
			$numUsers{$frequency} += 1;
		}

	}

}

foreach $user ( keys(%hashOfOccurrence) ){
	
	foreach $frequency ( keys(%{$hashOfOccurrence{$user}}) ){
	
		if( !exists($stdDevPerRank{$frequency}) ){
			$meanPerOccurrence{$frequency} = $meanPerOccurrence{$frequency}/$numUsers{$frequency};
			$stdDevPerRank{$frequency} = ($hashOfOccurrence{$user}{$frequency} - $meanPerOccurrence{$frequency}) * ($hashOfOccurrence{$user}{$frequency} - $meanPerOccurrence{$frequency});
		}
		else{
			$stdDevPerRank{$frequency} += ($hashOfOccurrence{$user}{$frequency} - $meanPerOccurrence{$frequency}) * ($hashOfOccurrence{$user}{$frequency} - $meanPerOccurrence{$frequency});
		}
	}
}

foreach $frequency ( sort{$a <=> $b} keys(%meanPerOccurrence) ){
	print FOUT $frequency,"\t", $meanPerOccurrence{$frequency}, "\t", sqrt($stdDevPerRank{$frequency}/$numUsers{$frequency}), "\n";
}
close(FOUT);


sub usage{
	print "\nIn order to run this script you should give 3 input parameters:\n";
	print " \tInput data file name\n";
	print " \tOutput data file name \n";
	print " \tPercentage of training set \n\n";
};
