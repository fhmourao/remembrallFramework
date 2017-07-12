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
my $numHits;
my $numReconsumptions;
my $recommendationTime;
my $recommendation;

my @items;
my @recommendations;

my %hashOfTrainItems;
my %testItems;

### Recupera parametros de entrada
die usage() if $#ARGV != 3;

open TEST_FILE, "<".$ARGV[0] or die "Can't open the test file $ARGV[0]!";
open TRAIN_FILE, "<".$ARGV[1] or die "Can't open the training file $ARGV[1]!";
open RECOMMENDATION_FILE, "<".$ARGV[2] or die "Can't open the recommendation file $ARGV[2]!";
open FOUT, ">".$ARGV[3] or die "Can't open the output file $ARGV[3]!";

loadTrainSet();

$numHits = 0;
$numReconsumptions = 0;
while( defined($line = <TEST_FILE>) ){
	chomp($line);

	($userId, $startTime, $endTime, @items) = split(/[ \t]/, $line);

	foreach $item (@items){
		($itemId, $score) = split(/:/, $item);

		$testItems{$itemId} = 1;

		if( exists($hashOfTrainItems{$userId}{$itemId}) ){
			$numReconsumptions += 1;
		}
	}
	splice(@items);

	if( !defined($line1 = <RECOMMENDATION_FILE> ) ){
		print "\n\t***ERROR: Not syncronized files!\n";
		exit;
	}

	($userId1, $recommendationTime, @recommendations) = split(/[ \t]/, $line1);
	if( ($userId != $userId1) || ($recommendationTime != $startTime) ){
		print "\n\t***ERROR1: Not syncronized files $userId $userId1!\n";
		exit;
	}

	foreach $recommendation (@recommendations){
		($itemId, $score) = split(/:/, $recommendation);

		if(exists($testItems{$itemId})){
			$numHits++;
		}
	}
	splice(@recommendations);

	%testItems = ();
}

if($numReconsumptions > 0 ){
	print FOUT $numReconsumptions,"\t", $numHits/$numReconsumptions;
}
else{
	print FOUT "0\t0";
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
