#!/usr/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my %hashOfMedian;
my %hashOfTrainItems;
my %hashOfUsers;

### Recupera parametros de entrada
die usage() if $#ARGV != 2;

open TRAIN_FILE, "<".$ARGV[0] or die "Can't open the training file $ARGV[0]!";
open RECOMMENDATION_FILE, "<".$ARGV[1] or die "Can't open the recommendation file $ARGV[1]!";
open FOUT, ">".$ARGV[2] or die "Can't open the output file $ARGV[2]!";

loadTrainSet();

getMedianPerMoment();

getReconsumableItems();

sub getMedianPerMoment{
	my $numUsers;
	my $startTime;
	my $numberOfItems;
	my $median;
	my $counter;
	my $itemId;
	my $selectedItem;

	foreach $startTime ( keys(%hashOfTrainItems) ){
		$numUsers = $hashOfUsers{$startTime};
		$numberOfItems = scalar keys(%{$hashOfTrainItems{$startTime}});
		$median = int($numberOfItems/2 + 0.5);

		$counter = 0;
		foreach $itemId ( sort{ $hashOfTrainItems{$startTime}{$b} <=> $hashOfTrainItems{$startTime}{$a}} keys(%{$hashOfTrainItems{$startTime}}) ){
			$counter++;
			if( $counter == $median){
				$selectedItem = $itemId;
				last;
			}
		}

		$hashOfMedian{$startTime} = $hashOfTrainItems{$startTime}{$selectedItem};
	}
}

sub getReconsumableItems{
	my $numRecItems;
	my $numReconsumableItems;
	my $line;
	my $userId;
	my $startTime;
	my $item;
	my $itemId;
	my $score;

	my @recommendations;
	

	$numRecItems = 0;
	$numReconsumableItems = 0;

	while( defined($line = <RECOMMENDATION_FILE>) ){

		($userId, $startTime, @recommendations) = split(/[ \t]/, $line);

		foreach $item ( @recommendations ) {
			($itemId, $score) = split(/:/, $item);

			if( exists($hashOfTrainItems{$startTime}{$itemId} ) ){
				if( exists($hashOfMedian{$startTime}) ){
					if( $hashOfTrainItems{$startTime}{$itemId} > $hashOfMedian{$startTime}){
						$numReconsumableItems++;
					}
				}
			}
			$numRecItems++;
		}

		splice(@recommendations);
	}

	print FOUT "Percentage of re-consumable items: ", $numReconsumableItems/$numRecItems, "\n";
	close(FOUT);
}

sub loadTrainSet{
	my $line;
	my $userId;
	my $startTime;
	my $endTime;
	my $item;
	my $itemId;
	my $score;
	my $i;
	my $numTimeUnits;

	my @items;

	while( defined($line = <TRAIN_FILE>) ){
		chomp($line);

		($userId, $numTimeUnits) = split(/[ \t]/, $line);
		
		for($i=0; $i<$numTimeUnits; $i++){
			if( !defined($line = <TRAIN_FILE>) ){
				print "\n\t***ERROR: Wrong file format!!!\n";
				exit;
			}
			
			($userId, $startTime, $endTime, @items) = split(/[ \t]/, $line);

			foreach $item (@items){
				($itemId, $score) = split(/:/, $item);

				if( !exists($hashOfTrainItems{$startTime}{$itemId}) ){
					$hashOfTrainItems{$startTime}{$itemId} = 0;
				}
				$hashOfTrainItems{$startTime}{$itemId} += 1;
			}
			splice(@items);

			if( !exists($hashOfUsers{$startTime}) ){
				$hashOfUsers{$startTime} = 0;
			}
			$hashOfUsers{$startTime} += 1;
		}
	}
	close(TRAIN_FILE);

}

sub usage{
        print "\nIn order to run this script you should give 3 input parameters:\n";
	print "\tTraining file name\n";
	print "\tRecommendation file name\n";
        print "\tOutput file name \n\n";
}
