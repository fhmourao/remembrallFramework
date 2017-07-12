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
my $rating;
my $numRatins;
my $stdDev;

my @items;

my %hashUserTest;
my %meanRatingPerScore;
my %ratingPerScore;

#verifica o número de parametros informados
die usage() if $#ARGV != 2;

# open input file
open FORGOTTEN_ITEMS, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

# open output file
open FOUT, ">".$ARGV[1] or die "Can't open the output file $ARGV[1]!";

# open test file
open TEST_FILE, "<".$ARGV[2] or die "Can't open the test file $ARGV[2]!";

### Carrega conjunto de teste em memoria
loadTestSet();

### Realiza mapeamento de scores- > ratings
while( defined($line = <FORGOTTEN_ITEMS>) ){
	chomp($line);

	($userId, $time, @items) = split(/[ \t]/, $line);

	foreach $item (@items){
		($itemId, $score) = split(/:/, $item);
		$score = sprintf("%.2f",$score);

		if( exists($hashUserTest{$userId}{$itemId}) ){
			$rating = $hashUserTest{$userId}{$itemId};

			if( !exists($ratingPerScore{$score}) ){
				$meanRatingPerScore{$score} = 0;
				$ratingPerScore{$score}[0] = 0;
			}

			$ratingPerScore{$score}[0] = $ratingPerScore{$score}[0] + 1;
			$ratingPerScore{$score}[$ratingPerScore{$score}[0]] = $rating;
			$meanRatingPerScore{$score} += $rating;
		}
	}

	splice(@items);
}
close(FORGOTTEN_ITEMS);

### Imprime em arquivo de saida 
foreach $score ( sort {$b <=> $a} (keys(%ratingPerScore)) ){
	$numRatins = $ratingPerScore{$score}[0];
	$meanRatingPerScore{$score} = $meanRatingPerScore{$score}/$numRatins;

	$stdDev = 0.0;
	foreach $rating (@{$ratingPerScore{$score}}){
		$stdDev += ($rating-$meanRatingPerScore{$score}) * ($rating-$meanRatingPerScore{$score});
	}
	$stdDev = sqrt($stdDev/$numRatins);

	print FOUT $score, "\t", $meanRatingPerScore{$score}, "\t", $stdDev, "\n";
}
close(FOUT);

sub loadTestSet{
    my $line;
    my $userId;
    my $item;
    my $itemId;
    my $rating;
    my $startTime;

    while( defined($line = <TEST_FILE>) ){
	chomp($line);

	($userId, $itemId, $rating, $startTime) = split(/[ \t]/, $line);
	
	$hashUserTest{$userId}{$itemId} = $rating;
	
    }
    close(TEST_FILE);
}

sub usage{
        print "\nIn order to run this script you should give 3 input parameters:\n";
        print "\tForgotten Itens file name \n";
        print "\tOutput file name \n";
        print "\tTest file name \n\n";
}
