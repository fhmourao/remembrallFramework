#!/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my $counter;
my $itemId;
my $lastUser;
my $line;
my $numTimeUnits;
my $rating;
my $timestamp;
my $timeUnit;
my $userId;
my $numTrainItems;
my $numTrainUnits;

my %userTuples;

my $INVALID_USER = -999;

#verifica o número de parametros informados
die usage() if $#ARGV != 5;

open FIN,"<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

my $FIRST_TIMESTAMP = $ARGV[1];

my $TIME_INTERVAL = $ARGV[2];

my $TRAIN_PERCENTAGE = $ARGV[3];

open TRAIN_FILE,">".$ARGV[4] or die "Can't open the output file $ARGV[4]!";

open TEST_FILE,">".$ARGV[5] or die "Can't open the output file $ARGV[5]!";

$lastUser = $INVALID_USER;
while( defined($line = <FIN>) ){
	chomp($line);

	($userId, $itemId, $rating, $timestamp) = split(/[ \t]/, $line);

	# se eh um novo usuario
	if($userId != $lastUser){
		# se usuario anterior eh valido
		if( $lastUser != $INVALID_USER){

			$numTimeUnits = scalar keys(%userTuples);
			$numTrainUnits = int($numTimeUnits*$TRAIN_PERCENTAGE + 0.5);
			if( ($numTrainUnits > 1) && ($numTrainUnits <= $numTimeUnits) ){
				$numTrainItems = getNumTrainItems($numTrainUnits);
				print TRAIN_FILE "$lastUser\t$numTrainUnits\t$numTrainItems\n";
				
				# imprime tuplas temporalmente ordenadas crescentemente
				$counter = 0;
				foreach $timeUnit ( sort{$a <=> $b} keys(%userTuples) ){
					if( $counter < $numTrainUnits ){
						print TRAIN_FILE "$lastUser\t$timeUnit\t",$timeUnit+1;

						foreach $itemId ( keys(%{$userTuples{$timeUnit}})){
							print TRAIN_FILE "\t", $itemId,":",sprintf("%.4f", log($userTuples{$timeUnit}{$itemId}+1)/log(2));
						}
						print TRAIN_FILE "\n";
					}
					else{
						if( $counter == $numTrainUnits ){
							print TEST_FILE "$lastUser\t$timeUnit";
						}

						foreach $itemId ( keys(%{$userTuples{$timeUnit}})){
							print TEST_FILE "\t", $itemId,":",sprintf("%.4f", log($userTuples{$timeUnit}{$itemId}+1)/log(2));
						}
					}
					
					%{$userTuples{$timeUnit}} = ();
					$counter++;
				}
				if($numTrainUnits != $numTimeUnits){
					print TEST_FILE "\n";
				}
			}

			%userTuples = ();
		}

		$lastUser = $userId;
	}

	$timeUnit = int(($timestamp - $FIRST_TIMESTAMP)/$TIME_INTERVAL);

	if( !exists($userTuples{$timeUnit}{$itemId}) ){
		$userTuples{$timeUnit}{$itemId} = 0;
	}
	$userTuples{$timeUnit}{$itemId} += $rating;
	

}
close(FIN);

$numTimeUnits = scalar keys(%userTuples);
$numTrainUnits = int($numTimeUnits*$TRAIN_PERCENTAGE + 0.5);
if( ($numTrainUnits > 1) && ($numTrainUnits <= $numTimeUnits) ){
	$numTrainItems = getNumTrainItems($numTrainUnits);
	print TRAIN_FILE "$lastUser\t$numTrainUnits\t$numTrainItems\n";
	
	# imprime tuplas temporalmente ordenadas crescentemente
	$counter = 0;
	foreach $timeUnit ( sort{$a <=> $b} keys(%userTuples) ){
		if( $counter < $numTrainUnits ){
			print TRAIN_FILE "$lastUser\t$timeUnit\t",$timeUnit+1;

			foreach $itemId ( keys(%{$userTuples{$timeUnit}})){
				print TRAIN_FILE "\t", $itemId,":",sprintf("%.4f", log($userTuples{$timeUnit}{$itemId}+1)/log(2));
			}
			print TRAIN_FILE "\n";
		}
		else{
			if( $counter == $numTrainUnits ){
				print TEST_FILE "$lastUser\t$timeUnit";
			}

			foreach $itemId ( keys(%{$userTuples{$timeUnit}})){
				print TEST_FILE "\t", $itemId,":",sprintf("%.4f", log($userTuples{$timeUnit}{$itemId}+1)/log(2));
			}
		}
		
		%{$userTuples{$timeUnit}} = ();
		$counter++;
	}
	if($numTrainUnits != $numTimeUnits){
		print TEST_FILE "\n";
	}
}

%userTuples = ();
close(TRAIN_FILE);
close(TEST_FILE);

sub getNumTrainItems{
	my $counter;
	my $numItems;
	my $numTrainUnits;

	($numTrainUnits) = @_;
	$counter = 0;
	foreach $timeUnit ( sort{$a <=> $b} keys(%userTuples) ){
		if( $counter == $numTrainUnits ){
			last;
		}
		
		$numItems += scalar (keys(%{$userTuples{$timeUnit}}));
		$counter++;
	}
	
	return $numItems;
}

sub usage{
        print "\nIn order to run this script you should give 4 input parameters:\n";
        print "\tInput file name \n";
        print "\tOutput file name \n";
        print "\tFirst timestamp\n";
        print "\tTime interval \n\n";
}
