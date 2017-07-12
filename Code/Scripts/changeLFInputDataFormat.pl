#!/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my $counter;
my $endTime; 
my $item;
my $itemId;
my $lastUser;
my $line;
my $numTimeUnits;
my $frequency;
my $startTime;
my $timeUnit;
my $userId;
my $numItems;
my $numTrainUnits;

my @items;

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

$numItems = 0;
$lastUser = $INVALID_USER;
while( defined($line = <FIN>) ){
	chomp($line);

	($userId, $startTime, $endTime, @items) = split(/[ \t]/, $line);

	# se eh um novo usuario
	if($userId != $lastUser){
		# se usuario anterior eh valido
		if( $lastUser != $INVALID_USER){

			$numTimeUnits = scalar keys(%userTuples);
			$numTrainUnits = int($numTimeUnits*$TRAIN_PERCENTAGE + 0.5);
			if( ($numTrainUnits > 1) && ($numTrainUnits <= $numTimeUnits) ){
				print TRAIN_FILE "$lastUser\t$numTrainUnits\t$numItems\n";
				
				# imprime tuplas temporalmente ordenadas crescentemente
				$counter = 0;
				foreach $timeUnit ( sort{$a <=> $b} keys(%userTuples) ){
					if( $counter < $numTrainUnits ){
						print TRAIN_FILE "$lastUser\t$timeUnit\t",$timeUnit+1;

						foreach $itemId ( sort{ $userTuples{$timeUnit}{$b} <=> $userTuples{$timeUnit}{$a} } keys(%{$userTuples{$timeUnit}})){
							print TRAIN_FILE "\t", $itemId,":",log($userTuples{$timeUnit}{$itemId}+1)/log(2);
						}
						print TRAIN_FILE "\n";
					}
					else{
						if( $counter == $numTrainUnits ){
							print TEST_FILE "$lastUser\t$timeUnit";
						}

						foreach $itemId ( sort{$userTuples{$timeUnit}{$b} <=> $userTuples{$timeUnit}{$a} } keys(%{$userTuples{$timeUnit}})){
							print TEST_FILE "\t", $itemId,":",log($userTuples{$timeUnit}{$itemId}+1)/log(2);
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
		$numItems = 0;
	}

	$timeUnit = int(($startTime - $FIRST_TIMESTAMP)/$TIME_INTERVAL);
	foreach $item (@items){
		($itemId, $frequency) = split(/:/, $item);
		
		if( (exists($userTuples{$timeUnit})) && (exists($userTuples{$timeUnit}{$itemId})) ){
			$userTuples{$timeUnit}{$itemId} += $frequency;
		}
		else{
			$userTuples{$timeUnit}{$itemId} = $frequency;
			$numItems++;
		}
	}

	splice(@items);

}
close(FIN);

$numTimeUnits = scalar keys(%userTuples);
$numTrainUnits = int($numTimeUnits*$TRAIN_PERCENTAGE + 0.5);
if( ($numTrainUnits > 1) && ($numTrainUnits <= $numTimeUnits) ){
	print TRAIN_FILE "$lastUser\t$numTrainUnits\t$numItems\n";
	
	# imprime tuplas temporalmente ordenadas crescentemente
	$counter = 0;
	foreach $timeUnit ( sort{$a <=> $b} keys(%userTuples) ){
		if( $counter < $numTrainUnits ){
			print TRAIN_FILE "$lastUser\t$timeUnit\t",$timeUnit+1;

			foreach $itemId ( keys(%{$userTuples{$timeUnit}})){
				print TRAIN_FILE "\t", $itemId,":",log($userTuples{$timeUnit}{$itemId}+1)/log(2);
			}
			print TRAIN_FILE "\n";
		}
		else{
			if( $counter == $numTrainUnits ){
				print TEST_FILE "$lastUser\t$timeUnit";
			}

			foreach $itemId ( keys(%{$userTuples{$timeUnit}})){
				print TEST_FILE "\t", $itemId,":",log($userTuples{$timeUnit}{$itemId}+1)/log(2);
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

sub usage{
        print "\nIn order to run this script you should give 6 input parameters:\n";
        print "\tInput file name \n";
        print "\tFirst timestamp\n";
        print "\tTime interval \n";
        print "\tPercentage of training size \n";
        print "\tTraining output file \n";
        print "\tTest output file \n\n";
}
