#!/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my $endTime; 
my $item;
my $itemId;
my $lastUser;
my $line;
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
die usage() if $#ARGV != 3;

open FIN,"<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

my $FIRST_TIMESTAMP = $ARGV[1];

my $TIME_INTERVAL = $ARGV[2];

open TRAIN_FILE,">".$ARGV[3] or die "Can't open the output file $ARGV[3]!";

$numItems = 0;
$lastUser = $INVALID_USER;
while( defined($line = <FIN>) ){
	chomp($line);

	($userId, $startTime, $endTime, @items) = split(/[ \t]/, $line);

	# se eh um novo usuario
	if($userId != $lastUser){
		# se usuario anterior eh valido
		if( $lastUser != $INVALID_USER){

			$numTrainUnits = scalar keys(%userTuples);
			print TRAIN_FILE "$lastUser\t$numTrainUnits\t$numItems\n";
			
			# imprime tuplas temporalmente ordenadas crescentemente
			foreach $timeUnit ( sort{$a <=> $b} keys(%userTuples) ){

				print TRAIN_FILE "$lastUser\t$timeUnit\t",$timeUnit+1;

				foreach $itemId ( sort{ $userTuples{$timeUnit}{$b} <=> $userTuples{$timeUnit}{$a} } keys(%{$userTuples{$timeUnit}})){
					print TRAIN_FILE "\t", $itemId,":",log($userTuples{$timeUnit}{$itemId}+1)/log(2);
				}
				print TRAIN_FILE "\n";

				%{$userTuples{$timeUnit}} = ();

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


	
# imprime tuplas temporalmente ordenadas crescentemente
$numTrainUnits = scalar keys(%userTuples);
print TRAIN_FILE "$lastUser\t$numTrainUnits\t$numItems\n";
foreach $timeUnit ( sort{$a <=> $b} keys(%userTuples) ){

	print TRAIN_FILE "$lastUser\t$timeUnit\t",$timeUnit+1;

	foreach $itemId ( keys(%{$userTuples{$timeUnit}})){
		print TRAIN_FILE "\t", $itemId,":",log($userTuples{$timeUnit}{$itemId}+1)/log(2);
	}
	print TRAIN_FILE "\n";


	%{$userTuples{$timeUnit}} = ();

}

%userTuples = ();
close(TRAIN_FILE);

sub usage{
        print "\nIn order to run this script you should give 4 input parameters:\n";
        print "\tInput file name \n";
        print "\tFirst timestamp\n";
        print "\tTime interval \n";
        print "\tOutput file name\n\n";
}
