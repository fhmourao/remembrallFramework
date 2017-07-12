#!/usr/bin/perl
use strict;
use warnings;
use Statistics::Regression;

### Declaracao de variaveis
my $age;

my %hashOfTrainItems;
my %firstOccurrencePerItem;

### Recupera parametros de entrada
die usage() if $#ARGV != 1;

open TRAIN_FILE, "<".$ARGV[0] or die "Can't open the training file $ARGV[0]!";
open FOUT, ">".$ARGV[1] or die "Can't open the output file $ARGV[1]!";

loadTrainSet();

$age = getAge();

print FOUT $age;


sub getCutPoint{
	my $i;
	my $mean = 0.0;
	my $numDimensions;
	my $rank = 0;
	my $regression = Statistics::Regression->new( "sample regression", [ "intercept", "slope"] );
	my @theta;

	my @inputData;

	(@inputData) = @_;

	$numDimensions = $#inputData + 1;

	if($numDimensions > 1 ){
		for($i=0; $i<$numDimensions; $i++){
			$mean+=$inputData[$i];
		}
		$mean = $mean/$numDimensions;
		
		for($i=0; $i<$numDimensions; $i++){
			$regression->include(log($inputData[$i]), [1.0, log($i+1)]);
		}
		
		@theta  = $regression->theta();
		
		if( abs($theta[1]) > 0.0 ){
			$mean = $mean/abs($theta[1]);
		}
		
		for($rank=0; $rank<$numDimensions; $rank++){
			if( $inputData[$rank] < $mean ){
				last;
			}
		}
		$rank = $rank -1;
	}

	return $rank;

}

sub getAge{
	my $startTime;
	my $index;
	my $itemId;
	my $rank;
	my $temporalDistance;
	my $numItems;
	my $medianPosition;
	my $timeUnit;
	my $lastTimeUnit;
	
	my @arrayOfFrequency;
	my @arrayOfItems;
	my @sortedDistances;
	my @sortedTimes;
	my @temporalDistances;
	my @timeToBecomePopular;

	my %popularItems;
	my %distinctPopularItems;
	my %firstOccurrencePopularItems;

	$lastTimeUnit = 0;
	foreach $startTime ( sort {$a <=> $b} keys(%hashOfTrainItems) ){

		$index = 0;
		foreach $itemId ( sort{ $hashOfTrainItems{$startTime}{$b} <=> $hashOfTrainItems{$startTime}{$a}} keys(%{$hashOfTrainItems{$startTime}}) ){
			$arrayOfFrequency[$index] = $hashOfTrainItems{$startTime}{$itemId};
			$arrayOfItems[$index] = $itemId;
			$index += 1;
		}

		$rank = getCutPoint(@arrayOfFrequency);
		for($index=0; $index<=$rank; $index++){
			if( !exists($distinctPopularItems{$arrayOfItems[$index]}) ){
				$distinctPopularItems{$arrayOfItems[$index]} = 1;
				$firstOccurrencePopularItems{$startTime}{$arrayOfItems[$index]} = 1;
			}
			$popularItems{$startTime}{$arrayOfItems[$index]} = 1;
		}

		splice(@arrayOfFrequency);
		splice(@arrayOfItems);
		
		$lastTimeUnit = $startTime;
	}

	$index = 0;
	foreach $startTime ( keys(%firstOccurrencePopularItems) ){
		foreach $itemId ( keys(%{$firstOccurrencePopularItems{$startTime}}) ){
			$temporalDistance = 0;
			foreach $timeUnit( sort{ $a <=> $b} keys(%hashOfTrainItems) ){
				if($timeUnit > $startTime){
					if( !exists($popularItems{$timeUnit}{$itemId}) ){
						last;
					}
					
					if($timeUnit == $lastTimeUnit){
						$temporalDistance = 0;
					
					}
					else{
						$temporalDistance = $timeUnit - $startTime;
					}
				}
			}

			if( $temporalDistance > 0){
				$timeToBecomePopular[$index] = $startTime - $firstOccurrencePerItem{$itemId};
				
				$temporalDistances[$index] = $temporalDistance;
				$index += 1;
			}
		}
	}

	@sortedDistances = sort {$a <=> $b} @temporalDistances;
	@sortedTimes = sort {$a <=> $b} @timeToBecomePopular;
	
	$numItems = scalar @sortedDistances;
	$medianPosition = int($numItems/2);

	return ($sortedTimes[$medianPosition] + $sortedDistances[$medianPosition] + 1);

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
				
				if( exists($firstOccurrencePerItem{$itemId}) ){
					if($firstOccurrencePerItem{$itemId} > $startTime){
						$firstOccurrencePerItem{$itemId} = $startTime;
					}
				}
				else{
					$firstOccurrencePerItem{$itemId} = $startTime;
				}
			}
			splice(@items);

		}
	}
	close(TRAIN_FILE);

}

sub usage{
        print "\nIn order to run this script you should give 2 input parameters:\n";
	print "\tTraining file name\n";
        print "\tOutput file name \n\n";
}
