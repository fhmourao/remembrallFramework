#!/usr/bin/perl
use strict;
use warnings;

### Global variable declaration
my $counter;
my $itemId;
my $line;
my $rating;
my $numTestItems;
my $recommendation;
my $userId;

my @recommendations;

my %hashUserTest;

#verifica o número de parametros informados
die usage() if $#ARGV != 3;

# open input file
open FIN, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

# open output file
open FOUT, ">".$ARGV[1] or die "Can't open the output file $ARGV[1]!";

# open test file
open TEST_FILE, "<".$ARGV[2] or die "Can't open the test file $ARGV[2]!";

my $MODE = $ARGV[3];

# verifica se modo de execucao informato eh valido
if( ($MODE != 0) && ($MODE != 1) ){
	die usage();
}

### Carrega conjunto de teste em memoria
loadTestSet();

while( defined($line = <FIN>) ){
	chomp($line);

	($userId, @recommendations) = split(/[ \t]/, $line);

	$counter = 0;
	if( exists($hashUserTest{$userId}) ){
		$numTestItems = scalar keys(%{$hashUserTest{$userId}});
		
		foreach $recommendation (@recommendations){
			($itemId, $rating) = split(/:/, $recommendation);

			print FOUT "$userId\t$itemId\t$rating\t-1\n";
			
			$counter++;
			if( ($counter == $numTestItems) && ($MODE != 1) ){
				last;
			}
		}
	}
	
	splice(@recommendations);
}
close(FIN);
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
	
	$hashUserTest{$userId}{$itemId} = 1;
	
    }
    close(TEST_FILE);
}

sub usage{
        print "\nIn order to run this script you should give 4 input parameters:\n";
        print "\tInput file name \n";
        print "\tOutput file name \n";
        print "\tTest file name \n";
        print "\tExecution Mode (0- print only a subset of the recommendations equal to the test size; 1- print all recommendations) \n\n";
}