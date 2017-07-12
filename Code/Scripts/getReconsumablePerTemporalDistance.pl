#!/usr/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my %hashOfTrainItems;
my %lastConsumptionPerUser;
my %numUsersPerItem;
my %reconsumptionPerTemporalDistance;

### Recupera parametros de entrada
die usage() if $#ARGV != 2;

open TRAIN_FILE, "<".$ARGV[0] or die "Can't open the training file $ARGV[0]!";
open RECOMMENDATION_FILE, "<".$ARGV[1] or die "Can't open the recommendation file $ARGV[1]!";
open FOUT, ">".$ARGV[2] or die "Can't open the output file $ARGV[2]!";

loadTrainSet();

getReconsumableItems();

sub getReconsumableItems{
	my $line;
	my $userId;
	my $startTime;
	my $item;
	my $itemId;
	my $score;
	my $lastConsumption;
	my $temporalDistance;
	my $percentageOfReconsumption;

	my @recommendations;
	
	my %meanPercentage;
	my %numRecItems;

	while( defined($line = <RECOMMENDATION_FILE>) ){

		($userId, $startTime, @recommendations) = split(/[ \t]/, $line);

		foreach $item ( @recommendations ) {
			($itemId, $score) = split(/:/, $item);

			if( exists($lastConsumptionPerUser{$userId}{$itemId}) ){
				$lastConsumption = $lastConsumptionPerUser{$userId}{$itemId};
			}
			else{
				$lastConsumption = $startTime;
			}

			$temporalDistance = $startTime - $lastConsumption;

			if( exists($reconsumptionPerTemporalDistance{$itemId}{$temporalDistance}) ){
				$percentageOfReconsumption = $reconsumptionPerTemporalDistance{$itemId}{$temporalDistance}/$numUsersPerItem{$itemId};
			}
			else{
				$percentageOfReconsumption = 0.0;
			}

			if( !exists($meanPercentage{$temporalDistance}) ){
				$meanPercentage{$temporalDistance} = 0;
			}
			$meanPercentage{$temporalDistance} += $percentageOfReconsumption;

			if( !exists($numRecItems{$temporalDistance}) ){
				$numRecItems{$temporalDistance} = 0;
			}
			$numRecItems{$temporalDistance}++;
		}

		splice(@recommendations);
	}

	foreach $temporalDistance ( sort{$a <=> $b} keys(%meanPercentage)  ){
		print FOUT $temporalDistance, "\t", $meanPercentage{$temporalDistance}/$numRecItems{$temporalDistance}, "\n";
	}
	close(FOUT);
}

sub loadTrainSet{
	my $line;
	my $userId;
	my $numTimeUnits;
	my $i;
	my $startTime;
	my $endTime;
	my $item;
	my $itemId;
	my $score;
	my $lastTime;
	my $maxDistance;
	my $temporalDistance;

	my @items;

	while( defined($line = <TRAIN_FILE>) ){
		chomp($line);

		($userId, $numTimeUnits) = split(/[ \t]/, $line);
		
		for($i=0; $i<$numTimeUnits; $i++){
			if( !defined($line = <TRAIN_FILE>) ){
				print "\n\t***ERROR: Wrong file format!!!\n";
				exit;
			}
			
			# le arquivo de entrada
			($userId, $startTime, $endTime, @items) = split(/[ \t]/, $line);

			# carrega dados em hash 
			foreach $item (@items){
				($itemId, $score) = split(/:/, $item);

				$hashOfTrainItems{$itemId}{$startTime} = 1;
				$lastConsumptionPerUser{$userId}{$itemId} = $startTime;
			}
			splice(@items);
		}

		foreach $item ( keys(%hashOfTrainItems) ){
			$lastTime = -1;
			$maxDistance = 0;

			foreach $startTime ( sort {$hashOfTrainItems{$item}{$a} <=> $hashOfTrainItems{$item}{$b}} keys(%{$hashOfTrainItems{$item}}) ){
				if( $lastTime != -1 ){
					$temporalDistance = $startTime - $lastTime;
					if( $temporalDistance > $maxDistance ){
						$maxDistance = $temporalDistance;
					}
				}
				$lastTime = $startTime;
			}

			for($i=1; $i<=$maxDistance; $i++){
				if( !exists($reconsumptionPerTemporalDistance{$item}{$i}) ){
					$reconsumptionPerTemporalDistance{$item}{$i} = 0;
				}
				$reconsumptionPerTemporalDistance{$item}{$i} += 1;
			}

			if( !exists($numUsersPerItem{$item}) ){
				$numUsersPerItem{$item} = 0;
			}
			$numUsersPerItem{$item} += 1;
		}


		%hashOfTrainItems = ();
	}
	close(TRAIN_FILE);

}

sub usage{
        print "\nIn order to run this script you should give 3 input parameters:\n";
	print "\tTraining file name\n";
	print "\tRecommendation file name\n";
        print "\tOutput file name \n\n";
}
