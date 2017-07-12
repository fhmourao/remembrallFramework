#!/usr/bin/perl
use strict;
use warnings;

my $accValue;
my $line;
my $numRows;
my $similarity;

my @meanSimilarities;

my %hashSimilarity;

die usage() if $#ARGV != 2;

open FIN, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

open FOUT, ">".$ARGV[1] or die "Can't open the output file $ARGV[1]!";

my $SELECTED_INDEX = $ARGV[2];

$numRows = 0;
while( defined($line = <FIN>) ){
	chomp($line);

	(@meanSimilarities) = split(/\t/, $line);

	if($SELECTED_INDEX > $#meanSimilarities){
		print "\n\t*** ERROR: Seleted index higher than the input vector's size!\n";
		exit;
	}

	$meanSimilarities[$SELECTED_INDEX] = sprintf("%.2f", $meanSimilarities[$SELECTED_INDEX]);

	if( exists($hashSimilarity{$meanSimilarities[$SELECTED_INDEX]} ) ){
		$hashSimilarity{$meanSimilarities[$SELECTED_INDEX]} += 1;
	}
	else{
		$hashSimilarity{$meanSimilarities[$SELECTED_INDEX]} = 1;
	}

	splice(@meanSimilarities);
	$numRows++;
}
close(FIN);

$accValue = 0;
foreach $similarity ( sort {$a <=> $b} keys(%hashSimilarity) ){
	$accValue += ($hashSimilarity{$similarity}/$numRows);
	print FOUT "$similarity", "\t", $accValue, "\n";
}
close(FOUT);

sub usage{
	print "\nIn order to run this script you should give 3 input parameters:\n";
	print " \tInput data file name\n";
	print " \tOutput data file name \n";
	print " \tSelected index in the input vector of values\n\n";
};
