#!/usr/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my $line;
my $line1;
my $userId;
my $userId1;
my $startTime;
my $endTime;
my $item;
my $itemId;
my $score;
my $distance;
my $recommendationTime;
my $recommendation;

my @items;
my @recommendations;

my %hashOfTrainItems;
my %numHitsPerDistance;
my %numItemsPerDistance;
my %testItemsPerDistance;

### Recupera parametros de entrada
die usage() if $#ARGV != 3;

open TEST_FILE, "<".$ARGV[0] or die "Can't open the test file $ARGV[0]!";
open TRAIN_FILE, "<".$ARGV[1] or die "Can't open the training file $ARGV[1]!";
open RECOMMENDATION_FILE, "<".$ARGV[2] or die "Can't open the recommendation file $ARGV[2]!";
open FOUT, ">".$ARGV[3] or die "Can't open the output file $ARGV[3]!";

loadTrainSet();

while( defined($line = <TEST_FILE>) ){
	chomp($line);

	($userId, $startTime, @items) = split(/[ \t]/, $line);

	foreach $item (@items){
		($itemId, $score) = split(/:/, $item);

		if( exists($hashOfTrainItems{$userId}{$itemId}) ){
			$distance = $startTime - $hashOfTrainItems{$userId}{$itemId};
			$testItemsPerDistance{$itemId} = $distance;

			if( exists($numItemsPerDistance{$distance}) ){
				$numItemsPerDistance{$distance} += 1;
			}
			else{
				$numItemsPerDistance{$distance} = 1;
			}
		}
	}
	splice(@items);

	if( !defined($line1 = <RECOMMENDATION_FILE> ) ){
		print "\n\t***ERROR: Not syncronized files!\n";
		exit;
	}

	($userId1, $recommendationTime, @recommendations) = split(/[ \t]/, $line1);
	if( ($userId != $userId1) || ($recommendationTime != $startTime) ){
		print "\n\t***ERROR1: Not syncronized files!\n";
		exit;
	}

	foreach $recommendation (@recommendations){
		($itemId, $score) = split(/:/, $recommendation);

		if(exists($testItemsPerDistance{$itemId})){
			$distance = $testItemsPerDistance{$itemId};
			if( exists($numHitsPerDistance{$distance} ) ){
				$numHitsPerDistance{$distance} += 1;
			}
			else{
				$numHitsPerDistance{$distance} = 1;
			}
		}
	}
	splice(@recommendations);

	%testItemsPerDistance = ();
}

foreach $distance ( sort {$a <=> $b} keys(%numItemsPerDistance)){
	if( exists($numHitsPerDistance{$distance}) ){
		print FOUT $distance,"\t", $numHitsPerDistance{$distance}/$numItemsPerDistance{$distance}, "\t", $numItemsPerDistance{$distance}, "\n";
	}
	else{
		print FOUT $distance,"\t", 0, "\t", $numItemsPerDistance{$distance}, "\n";
	}
}
close(FOUT);

sub loadTrainSet{
	my $line;
	my $userId;
	my $startTime;
	my $endTime;
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

				$hashOfTrainItems{$userId}{$itemId} = $startTime;
			}
			splice(@items);
		}
	}
	close(TRAIN_FILE);

}

sub usage{
        print "\nIn order to run this script you should give 4 input parameters:\n";
        print "\tTest file name\n";
	print "\tTraining file name\n";
	print "\tRecommendation file name\n";
        print "\tOutput file name \n\n";
}
