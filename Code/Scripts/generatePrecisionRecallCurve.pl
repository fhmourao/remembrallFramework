#!/usr/bin/perl
use strict;
use warnings;

### Global variable declaration
my $line;
my $userId;
my $time;
my $item;
my $itemId;
my $score;
my $numHits;
my $numTrials;
my $testSize;
my $precision;
my $recall;
my $meanPrecision;

my @items;

my $INVALID_USER = -1;

my %hashUserTest;
my %meanPrecisionPerRecall;
my %recallOccurrence;

#verifica o número de parametros informados
die usage() if $#ARGV != 2;

# open input file
open RECOMMENDED_ITEMS, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

# open test file
open TEST_FILE, "<".$ARGV[1] or die "Can't open the test file $ARGV[1]!";

# open output file
open FOUT, ">".$ARGV[2] or die "Can't open the output file $ARGV[2]!";

### Carrega conjunto de teste em memoria
loadTestSet();

### Calcula precision por porcentagem de recall
while( defined($line = <RECOMMENDED_ITEMS>) ){
	chomp($line);

	($userId, $time, @items) = split(/[ \t]/, $line);

	$numHits = 0;
	$numTrials = 0;
	$testSize = getNumReconsumedItems($userId,@items);
	foreach $item (@items){
		($itemId, $score) = split(/:/, $item);
		$numTrials++;

		if( exists($hashUserTest{$userId}{$itemId}) ){
			$numHits++;
			
			$precision = $numHits/$numTrials;
			$recall = sprintf("%.2f", $numHits/$testSize);
			
			if( !exists($recallOccurrence{$recall})){
				$recallOccurrence{$recall} = 0;
				$meanPrecisionPerRecall{$recall} = 0.0;
			}
			
			$recallOccurrence{$recall} += 1;
			$meanPrecisionPerRecall{$recall} += $precision;
		}
	}

	splice(@items);
}
close(RECOMMENDED_ITEMS);

foreach $recall (sort {$a <=> $b} keys(%meanPrecisionPerRecall)){
	$meanPrecision = sprintf("%.2f", $meanPrecisionPerRecall{$recall}/$recallOccurrence{$recall});
	print FOUT $recall,"\t", $meanPrecision,"\n";
}
close(FOUT);

sub getNumReconsumedItems{
	my $numItems;
	my $item;
	my $itemId;
	my $score;
	my $userId;

	my @items;
	
	($userId,@items) = @_;
	
	$numItems = 0;
	
	foreach $item (@items){
		($itemId, $score) = split(/:/, $item);

		if( exists($hashUserTest{$userId}{$itemId}) ){
			$numItems++;
		}
	}
	
	return $numItems;
}

sub loadTestSet{
    my $line;
    my $userId;
    my $item;
    my $itemId;
    my $score;
    my $time;

    while( defined($line = <TEST_FILE>) ){
	chomp($line);

	($userId, $time, @items) = split(/[ \t]/, $line);
	
	foreach $item (@items){
		($itemId, $score) = split(/:/, $item);

		$hashUserTest{$userId}{$itemId} = 1;
	}

	splice(@items);
    }
    close(TEST_FILE);
}

sub usage{
        print "\nIn order to run this script you should give 3 input parameters:\n";
        print "\tForgotten Itens file name \n";
        print "\tTest file name \n";
        print "\tOutput file name \n\n";
}
