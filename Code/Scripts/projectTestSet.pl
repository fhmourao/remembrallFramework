#!/usr/bin/perl
use strict;
use warnings;

### Global variable declaration
my %hashUserTest;
my %hashUserTraining;

#verifica o número de parametros informados
die usage() if $#ARGV != 2;

# open input file
open TRAINING_FILE, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

# open test file
open TEST_FILE, "<".$ARGV[1] or die "Can't open the test file $ARGV[1]!";

# open output file
open FOUT, ">".$ARGV[2] or die "Can't open the output file $ARGV[2]!";

loadTrainingSet();

selectTestSet();

sub selectTestSet{
    my $line;
    my $userId;
    my $item;
    my $itemId;
    my $rating;
    my $startTime;
    
    my @items;

    while( defined($line = <TEST_FILE>) ){
	chomp($line);

	($userId, $startTime, @items) = split(/[ \t]/, $line);
	
	foreach $item (@items){
		($itemId, $rating) = split(/:/, $item);
		
		if( exists($hashUserTraining{$userId}{$itemId}) ){
			if( !exists($hashUserTest{$userId}{$itemId}) ){
				$hashUserTest{$userId}{$itemId} = 0;
			}
			$hashUserTest{$userId}{$itemId} += $rating;
		}
	}
	splice(@items);
	
    }
    close(TEST_FILE);
    
    foreach $userId ( sort {$a <=> $b} keys(%hashUserTest) ){
		foreach $itemId ( sort {$hashUserTest{$userId}{$b} <=> $hashUserTest{$userId}{$a}} keys(%{$hashUserTest{$userId}}) ){
			$rating = $hashUserTest{$userId}{$itemId};
			print FOUT "$userId\t$itemId\t$rating\t1\n";
		}
    }
    close(FOUT);
}

sub loadTrainingSet{
    my $line;
    my $userId;
    my $item;
    my $itemId;
    my $rating;
    my $startTime;
    
    my @items;

    while( defined($line = <TRAINING_FILE>) ){
	chomp($line);

	($userId, $startTime, @items) = split(/[ \t]/, $line);
	
	foreach $item (@items){
		($itemId, $rating) = split(/:/, $item);

		$hashUserTraining{$userId}{$itemId} = 1;
	}
	splice(@items);
	
    }
    close(TRAINING_FILE);
}

sub usage{
        print "\nIn order to run this script you should give 3 input parameters:\n";
        print "\tForgotten Itens file name \n";
        print "\tTest file name \n";
        print "\tOutput file name \n\n";
}
