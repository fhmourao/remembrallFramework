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
my $rank;
my $rankSize;
my $startTime;
my $user;
my $userId;

my @items;
my @meanPerRank;
my @numUsers;
my @stdDevPerRank;

my %hashOfItems;
my %hashOfRank;
my %totalFrequency;

### Verify input parameters
die usage() if $#ARGV != 1;

### Retrieve input parameters

# Open input file
open FIN, "<". $ARGV[0] or die "Can't open the input file $ARGV[0]!";

open FOUT, ">". $ARGV[1] or die "Can't open the output file $ARGV[1]!";

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

			if( exists($hashOfItems{$userId}) ){
				if( exists($hashOfItems{$userId}{$itemId}) ){
					$hashOfItems{$userId}{$itemId} += $count;
				}
				else{
					$hashOfItems{$userId}{$itemId} = $count;
				}
				$totalFrequency{$userId} = $totalFrequency{$userId} + $count;
			}
			else{
				$hashOfItems{$userId}{$itemId} = $count;
				$totalFrequency{$userId} = $count;
			}
		}

		splice(@items);
	}
}
close(FIN);

foreach $user ( keys(%hashOfItems) ){
	$rank = 0;

	foreach $frequency ( sort { $b <=> $a} (values(%{$hashOfItems{$user}})) ){
		$probability = $frequency/$totalFrequency{$user};
		if($probability == 1.0){
			$hashOfRank{$userId}[$rank] = 1.0
		}
		else{
			$hashOfRank{$userId}[$rank] = $probability/(1-$probability);
		}

		if( !defined($meanPerRank[$rank]) ){
			$meanPerRank[$rank] = $hashOfRank{$userId}[$rank];
			$numUsers[$rank] = 1;
		}
		else{
			$meanPerRank[$rank] += $hashOfRank{$userId}[$rank];
			$numUsers[$rank] += 1;
		}

		$rank++;
	}
}

foreach $user ( keys(%hashOfRank) ){
	
	$rankSize = $#{$hashOfRank{$userId}} + 1;
	for($rank = 0; $rank<$rankSize ; $rank++){
		if( !defined($meanPerRank[$rank]) ){
			$meanPerRank[$rank] = $meanPerRank[$rank]/$numUsers[$rank];
			$stdDevPerRank[$rank] = ($hashOfRank{$userId}[$rank] - $meanPerRank[$rank]) * ($hashOfRank{$userId}[$rank] - $meanPerRank[$rank]);
		}
		else{
			$stdDevPerRank[$rank] += ($hashOfRank{$userId}[$rank] - $meanPerRank[$rank]) * ($hashOfRank{$userId}[$rank] - $meanPerRank[$rank]);
		}
	}

}

$rankSize = $#meanPerRank + 1;
for($rank = 0; $rank<$rankSize ; $rank++){

	print FOUT $rank,"\t", $meanPerRank[$rank], "\t", sqrt($stdDevPerRank[$rank]/$numUsers[$rank]), "\n";
}
close(FOUT);


sub usage{
	print "\nIn order to run this script you should give 2 input parameters:\n";
	print " \tInput data file name\n";
	print " \tOutput data file name \n\n";
};
