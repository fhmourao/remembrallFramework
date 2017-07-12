#!/usr/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my %distinctTimeUnits;
my %firstItemOccurrence;
my %hashOfTrainItems;
my %numUsersPerItem;
my %reconsumptionPerTemporalDistance;
my %probabilityOfReconsumption;
my %reconsumptionRate;

### Recupera parametros de entrada
die usage() if $#ARGV != 3;

open TRAIN_FILE, "<".$ARGV[0] or die "Can't open the training file $ARGV[0]!";
open FOUT, ">".$ARGV[1] or die "Can't open the output file $ARGV[2]!";

my $TOP_N = $ARGV[2];

my $TEMPORAL_DISTANCE = $ARGV[3];

loadTrainSet();

defineReconsumptionProbabilities();

determineItemsFirstTimeOccurrence();

getReconsumableItems();

sub defineReconsumptionProbabilities{
	my $numItems;
	my $item;
	my $temporalDistance;
	my $percentageOfReconsumption;

	my %numItemsPerTemporalDistance;
	my %meanReconsumptionPerTemporalDistance;

	foreach $item ( keys(%reconsumptionPerTemporalDistance) ){
		foreach $temporalDistance ( keys(%{$reconsumptionPerTemporalDistance{$item}}) ){
			if( $reconsumptionPerTemporalDistance{$item}{$temporalDistance} > 0 ){
				if( !exists($numItemsPerTemporalDistance{$temporalDistance}) ){
					$numItemsPerTemporalDistance{$temporalDistance} = 0;
				}
				$numItemsPerTemporalDistance{$temporalDistance} += 1;

				$percentageOfReconsumption = $reconsumptionPerTemporalDistance{$item}{$temporalDistance}/$numUsersPerItem{$item};

				if( !exists($meanReconsumptionPerTemporalDistance{$temporalDistance}) ){
					$meanReconsumptionPerTemporalDistance{$temporalDistance} = 0;
				}
				$meanReconsumptionPerTemporalDistance{$temporalDistance} += $percentageOfReconsumption;
			}
		}
	}
	
	$numItems = scalar keys(%hashOfTrainItems);

	foreach $temporalDistance ( sort {$a <=> $b} keys(%numItemsPerTemporalDistance) ){
		$probabilityOfReconsumption{$temporalDistance} = $numItemsPerTemporalDistance{$temporalDistance}/$numItems;
		$reconsumptionRate{$temporalDistance} = $meanReconsumptionPerTemporalDistance{$temporalDistance}/$numItemsPerTemporalDistance{$temporalDistance};
	}
}

sub determineItemsFirstTimeOccurrence{
	my $startTime;
	my $itemId;

	foreach $itemId ( keys(%hashOfTrainItems) ){
		foreach $startTime ( sort {$a <=> $b} keys(%{$hashOfTrainItems{$itemId}}) ){
			$firstItemOccurrence{$itemId} = $startTime;
			last;
		}
	}
}

sub getReconsumableItems{
	my $numItems;
	my $startTime;
	my $itemId;
	my $lastConsumption;
	my $temporalDistance;
	my $percentageOfReconsumption;
	my $medianPosition;
	my $medianValue;
	
	my @oldItems;
	my @percentages;
	my @sortedPercentages;
	

	$numItems = 0;
	foreach $startTime ( keys(%distinctTimeUnits) ){

		(@oldItems) = getOldItems($startTime);

		foreach $itemId ( @oldItems ) {

			$lastConsumption = getLastConsumption($itemId, $startTime);

			if( $lastConsumption > 0 ){
				$temporalDistance = $startTime - $lastConsumption;

				$percentageOfReconsumption = 0.0;
				if( exists($probabilityOfReconsumption{$temporalDistance}) ){
					$percentageOfReconsumption = $probabilityOfReconsumption{$temporalDistance}*$reconsumptionRate{$temporalDistance};
				}
				
				$percentages[$numItems] = $percentageOfReconsumption;
				$numItems++;
			}
		}

		splice(@oldItems);
	}

	@sortedPercentages = sort { $a <=> $b} @percentages;
	$medianPosition = int($numItems/2);
	$medianValue = $sortedPercentages[$medianPosition];

	print FOUT $medianValue,"\n";
	close(FOUT);
}

sub getLastConsumption{
	my $timeUnit;
	my $selectedItem;
	my $currentTime;
	my $lastConsumption;
	
	($selectedItem, $currentTime) = @_;

	$lastConsumption = -1;
	foreach $timeUnit ( sort {$a <=> $b} keys(%{$hashOfTrainItems{$selectedItem}}) ){
		
		if( $timeUnit >= $currentTime ){
			last;
		}

		$lastConsumption = $timeUnit;
	}
		
	return ($lastConsumption);
}

sub getOldItems{
	my $cutPoint;
	my $currentTime;
	my $numItems;
	my $item;

	my @oldItems;
	
	($currentTime) = @_;

	$cutPoint = $currentTime - $TEMPORAL_DISTANCE;

	$numItems = 0;
	foreach $item ( keys(%firstItemOccurrence) ){
		if( $firstItemOccurrence{$item} < $cutPoint){
			$oldItems[$numItems] = $item;
			$numItems++;
		}
	}

	return (@oldItems);
	
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
	
	my %itemsperUser;

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
			if( !exists($distinctTimeUnits{$startTime}) ){
				$distinctTimeUnits{$startTime} = 1;
			}

			# carrega dados em hash 
			foreach $item (@items){
				($itemId, $score) = split(/:/, $item);

				$hashOfTrainItems{$itemId}{$startTime} = 1;
				$itemsperUser{$itemId}{$startTime} = 1;
			}
			splice(@items);
		}

		foreach $item ( keys(%itemsperUser) ){
			$lastTime = -1;
			$maxDistance = 0;

			foreach $startTime ( sort {$a <=> $b} keys(%{$itemsperUser{$item}}) ){
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


		%itemsperUser = ();
	}
	close(TRAIN_FILE);

}

sub usage{
        print "\nIn order to run this script you should give 4 input parameters:\n";
	print "\tTraining file name\n";
        print "\tOutput file name \n";
	print "\tSize of the recommendation list \n";
	print "\tTemporal distance that distinguish old items \n\n";
}
