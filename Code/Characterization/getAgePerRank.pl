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
my %hashOfAge;
my %hashOfRank;

### Verify input parameters
die usage() if $#ARGV != 2;

### Retrieve input parameters

# Open input file
open FIN, "<". $ARGV[0] or die "Can't open the input file $ARGV[0]!";

open ITEM_AGE, "<". $ARGV[1] or die "Can't open the input file $ARGV[1]!";

open FOUT, ">". $ARGV[2] or die "Can't open the output file $ARGV[2]!";

loadAge();

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
			}
			else{
				$hashOfItems{$userId}{$itemId} = $count;
			}
		}

		splice(@items);
	}

}
close(FIN);

foreach $user ( keys(%hashOfItems) ){
	$rank = 0;

	foreach $item ( sort { $hashOfItems{$user}{$b} <=> $hashOfItems{$user}{$a}} (keys(%{$hashOfItems{$user}})) ){
		$hashOfRank{$user}[$rank] = $hashOfAge{$user}{$item};

		if( !defined($meanPerRank[$rank]) ){
			$meanPerRank[$rank] = $hashOfRank{$user}[$rank];
			$numUsers[$rank] = 1;
		}
		else{
			$meanPerRank[$rank] += $hashOfRank{$user}[$rank];
			$numUsers[$rank] += 1;
		}

		$rank++;
	}
}

foreach $userId ( keys(%hashOfRank) ){
	
	$rankSize = $#{$hashOfRank{$userId}} + 1;
	for($rank = 0; $rank<$rankSize ; $rank++){
		if( !defined($stdDevPerRank[$rank]) ){
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

sub loadAge{
	my $user;
	my $item;
	my $line;
	my $age;

	while( defined($line = <ITEM_AGE>) ){
		chomp($line);

		($user, $item, $age) = split(/\t/, $line);

		$hashOfAge{$user}{$item} = $age;
	}
	close(ITEM_AGE);
}

sub usage{
	print "\nIn order to run this script you should give 3 input parameters:\n";
	print " \tInput data file name\n";
	print " \tInput data file name of item's age\n";
	print " \tOutput data file name \n\n";
};
