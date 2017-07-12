#!/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my $itemId;
my $lastUser;
my $line;
my $numTimeUnits;
my $rating;
my $timestamp;
my $timeUnit;
my $userId;
my $numItems;
my $numTrain;
my $counter;
my $numItems;

my %userTuples;

my $INVALID_USER = -999;

#verifica o número de parametros informados
die usage() if $#ARGV != 2;

open FIN,"<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

open FOUT,">".$ARGV[1] or die "Can't open the input file $ARGV[1]!";

my $TRAIN_RATE = $ARGV[2];
if( ($TRAIN_RATE < 0.0) || ($TRAIN_RATE > 1.0) ){
	die usage();
}

$numItems = 0;
$lastUser = $INVALID_USER;
while( defined($line = <FIN>) ){
	chomp($line);

	($userId, $itemId, $rating, $timestamp) = split(/[ \t]/, $line);

	# se eh um novo usuario
	if($userId != $lastUser){
		# se usuario anterior eh valido
		if( $lastUser != $INVALID_USER){
			print FOUT "$userId\t2\t$numItems\n";

			$numItems = scalar keys(%userTuples);
			$numTrain = int( ($numItems * $TRAIN_RATE) + 0.5);
			$counter = 0;
			foreach $itemId ( keys(%userTuples) ){
				$rating = $userTuples{$itemId};
				if( $counter < $numTrain ){
					if($counter == 0){
						print FOUT "0 1";
					}
					else{
						print FOUT " $itemId:$rating";
					}
				}
				else{
					if( $counter == $numTrain ){
						print FOUT "\n1 2";
					}
					else{
						print FOUT " $itemId:$rating";
					}
				}
				$counter++;
			}
			
			print FOUT "\n";

			%userTuples = ();
		}

		$lastUser = $userId;
		$numItems = 0;
	}

	if( !exists($userTuples{$itemId}) ){
		$numItems++;
	}
	$userTuples{$itemId} = $rating;

}
close(FIN);

print FOUT "$userId\t2\t$numItems\n";
$numItems = scalar keys(%userTuples);
$numTrain = int( ($numItems * $TRAIN_RATE) + 0.5);
$counter = 0;
foreach $itemId ( keys(%userTuples) ){
	$rating = $userTuples{$itemId};
	if( $counter < $numTrain ){
		if($counter == 0){
			print FOUT "0 1";
		}
		else{
			print FOUT " $itemId:$rating";
		}
	}
	else{
		if( $counter == $numTrain ){
			print FOUT "\n1 2";
		}
		else{
			print FOUT " $itemId:$rating";
		}
	}
	$counter++;
}

print FOUT "\n";
close(FOUT);

sub usage{
        print "\nIn order to run this script you should give 3 input parameters:\n";
        print "\tInput file name \n";
        print "\tOutput file name \n";
        print "\tPercentage of training data (floating number between 0 and 1) \n\n";
}
