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
my $rank;
my $numRatings;
my $stdDev;
my $trainingSize;
my $numMatches;
my $rankShift;
my $rankDifference;

my @items;

my %hashUserTest;
my %meanRankingPerScore;
my %rankingPerScore;
my %matches;
my %itemRank;
my %trueRank;
my %matchItemsRating;

my $INVALID_USER = -1;

#verifica o número de parametros informados
die usage() if $#ARGV != 2;

# open input file
open FORGOTTEN_ITEMS, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

# open test file
open TEST_FILE, "<".$ARGV[1] or die "Can't open the test file $ARGV[1]!";

# open output file
open FOUT, ">".$ARGV[2] or die "Can't open the output file $ARGV[2]!";

### Carrega conjunto de teste em memoria
loadTestSet();

### Realiza mapeamento de scores- > ratings
while( defined($line = <FORGOTTEN_ITEMS>) ){
	chomp($line);

	($userId, $time, @items) = split(/[ \t]/, $line);
	$trainingSize = scalar(@items);

	$rank = 1;
	foreach $item (@items){
		($itemId, $score) = split(/:/, $item);
		$score = sprintf("%.2f",$score);

		if( exists($hashUserTest{$userId}{$itemId}) ){
			$matches{$itemId} = $score;
			$itemRank{$itemId} = $rank;
			$matchItemsRating{$itemId} = $hashUserTest{$userId}{$itemId};
		}
		
		$rank++;
	}
	splice(@items);

	$numMatches = scalar keys(%matches);
	$rankShift = $trainingSize - $numMatches;

	$rank = 1;
	foreach $item ( sort{$matchItemsRating{$a} <=> $matchItemsRating{$b}} keys(%matchItemsRating) ){
		$trueRank{$item} = $rankShift +  $rank;
		$rank++;
	}
	
	foreach $item ( sort {$itemRank{$a} <=> $itemRank{$b}} keys(%itemRank) ){
		$score = sprintf("%.1f",$matches{$item});

		$rankDifference = ($itemRank{$item} - $trueRank{$item})/$trainingSize;

		if( !exists($rankingPerScore{$score}) ){
			$meanRankingPerScore{$score} = 0;
			$rankingPerScore{$score}[0] = 0;
		}

		$rankingPerScore{$score}[0] = $rankingPerScore{$score}[0] + 1;
		$rankingPerScore{$score}[$rankingPerScore{$score}[0]] = $rankDifference;
		$meanRankingPerScore{$score} += $rankDifference;

	}
	%matches = ();
	%itemRank = ();
	%trueRank = ();
	%matchItemsRating = ();
}
close(FORGOTTEN_ITEMS);

### Imprime em arquivo de saida 
foreach $score ( sort {$b <=> $a} (keys(%rankingPerScore)) ){
	$numRatings = $rankingPerScore{$score}[0];
	$meanRankingPerScore{$score} = $meanRankingPerScore{$score}/$numRatings;

	$stdDev = 0.0;
	foreach $rank (@{$rankingPerScore{$score}}){
		$stdDev += ($rank-$meanRankingPerScore{$score}) * ($rank-$meanRankingPerScore{$score});
	}
	$stdDev = sqrt($stdDev/$numRatings);

	print FOUT $score, "\t", $meanRankingPerScore{$score}, "\t", $stdDev, "\n";
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
        print "\tTest file name \n";
        print "\tOutput file name \n\n";
}
