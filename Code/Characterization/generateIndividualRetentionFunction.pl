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
my $lastOccurrence;
my $line;
my $numItems;
my $numTimeUnits;
my $numTotalItems;
my $occ;
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
			print "\n\t***ERROR: not expected end of file!!!\n\n";
			exit;
		}

		chomp($line);
		($userId, $startTime, $endTime, @items) = split(/[ \t]/,$line);

		foreach $item ( @items ){
			 ($itemId, $count) = split(/:/,$item);

			$trainItems{$userId}{$itemId} = $endTime;

			$numItems++;
		}

		splice(@items);

		if($numItems >= $trainSize){
			last;
		}
	}


	for($i=$i+1;$i<$numTimeUnits; $i++){
		if( !(defined($line = <FIN>)) ){
			print "\n\t***ERROR1: not expected end of file!!!\n\n";
			exit;
		}

		chomp($line);
		($userId, $startTime, $endTime, @items) = split(/[ \t]/,$line);

		foreach $item ( @items ){
			 ($itemId, $count) = split(/:/,$item);

			$lastOccurrence = 0;
			if( exists($trainItems{$userId}{$itemId}) ){
				$lastOccurrence = $trainItems{$userId}{$itemId};
			}

			if( !exists($hashOfItems{$userId}{$lastOccurrence}) ){
				$hashOfItems{$userId}{$lastOccurrence} = 0;
			}
			
			$hashOfItems{$userId}{$lastOccurrence} += $count;
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

	foreach $lastOccurrence ( keys(%{$hashOfItems{$user}}) ){
	
		$probability = $hashOfItems{$user}{$lastOccurrence}/$totalFrequency{$user};
		$hashOfOccurrence{$user}{$lastOccurrence} = (1-$probability)/$probability;

		if( !defined($meanPerOccurrence{$lastOccurrence}) ){
			$meanPerOccurrence{$lastOccurrence} = (1-$probability)/$probability;
			$numUsers{$lastOccurrence} = 1;
		}
		else{
			$meanPerOccurrence{$lastOccurrence} += (1-$probability)/$probability;
			$numUsers{$lastOccurrence} += 1;
		}

	}

}

foreach $user ( keys(%hashOfOccurrence) ){
	
	foreach $occ ( keys(%{$hashOfOccurrence{$user}}) ){
	
		if( !exists($stdDevPerRank{$occ}) ){
			$meanPerOccurrence{$occ} = $meanPerOccurrence{$occ}/$numUsers{$occ};
			$stdDevPerRank{$occ} = ($hashOfOccurrence{$user}{$occ} - $meanPerOccurrence{$occ}) * ($hashOfOccurrence{$user}{$occ} - $meanPerOccurrence{$occ});
		}
		else{
			$stdDevPerRank{$occ} += ($hashOfOccurrence{$user}{$occ} - $meanPerOccurrence{$occ}) * ($hashOfOccurrence{$user}{$occ} - $meanPerOccurrence{$occ});
		}
	}
}

foreach $occ ( sort{$a <=> $b} keys(%meanPerOccurrence) ){
	print FOUT $occ,"\t", $meanPerOccurrence{$occ}, "\t", sqrt($stdDevPerRank{$occ}/$numUsers{$occ}), "\n";
}
close(FOUT);


sub usage{
	print "\nIn order to run this script you should give 3 input parameters:\n";
	print " \tInput data file name\n";
	print " \tOutput data file name \n";
	print " \tPercentage of training set \n\n";
};
