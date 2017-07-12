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
my $stdDev;
my $rank2;
my $rankSize;

my @items;

my $INVALID_USER = -1;

my %hashUserTest;

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

	$rank2 = 1;
	$rankSize = scalar keys(%{$hashUserTest{$userId}});
	foreach $item (@items){
		($itemId, $score) = split(/:/, $item);

		if( exists($hashUserTest{$userId}{$itemId}) ){
			$rank = $rankSize - $hashUserTest{$userId}{$itemId} + 1;

			print FOUT "$rank\t$rank2\n";
			$rank2++;
		}
	}

	splice(@items);
}
close(FORGOTTEN_ITEMS);
close(FOUT);


sub loadTestSet{
    my $line;
    my $userId;
    my $item;
    my $itemId;
    my $rating;
    my $startTime;
    my $lastUser = $INVALID_USER;
    my $rank = 1;

    while( defined($line = <TEST_FILE>) ){
	chomp($line);

	($userId, $itemId, $rating, $startTime) = split(/[ \t]/, $line);
	
	if( $userId != $lastUser ){
		$rank = 1;
		$lastUser = $userId;

	}

	$hashUserTest{$userId}{$itemId} = $rank;
	$rank++;
	
    }
    close(TEST_FILE);
}

sub usage{
        print "\nIn order to run this script you should give 3 input parameters:\n";
        print "\tForgotten Itens file name \n";
        print "\tTest file name \n";
        print "\tOutput file name \n\n";
}
