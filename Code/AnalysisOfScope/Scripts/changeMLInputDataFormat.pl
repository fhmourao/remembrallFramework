#!/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my $itemId;
my $lastUser;
my $line;
my $rating;
my $timestamp;
my $timeUnit;
my $userId;
my $numItems;
my $numTrainUnits;

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

	($userId, $itemId, $rating, $timestamp) = split(/[ \t]/, $line);

	# se eh um novo usuario
	if($userId != $lastUser){
		# se usuario anterior eh valido
		if( $lastUser != $INVALID_USER){

			$numTrainUnits = scalar keys(%userTuples);
			print TRAIN_FILE "$lastUser\t$numTrainUnits\t$numItems\n";
				
				# imprime tuplas temporalmente ordenadas crescentemente
				foreach $timeUnit ( sort{$a <=> $b} keys(%userTuples) ){
					print TRAIN_FILE "$lastUser\t$timeUnit\t",$timeUnit+1;

					foreach $itemId ( keys(%{$userTuples{$timeUnit}})){
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

	$timeUnit = int(($timestamp - $FIRST_TIMESTAMP)/$TIME_INTERVAL);
	if( (!exists($userTuples{$timeUnit})) || ( !exists($userTuples{$timeUnit}{$itemId})) ){
		$numItems++;
	}
	if( !exists($userTuples{$timeUnit}{$itemId}) ){
		$userTuples{$timeUnit}{$itemId} = 0;
	}
	$userTuples{$timeUnit}{$itemId} += $rating;
	

}
close(FIN);

$numTrainUnits = scalar keys(%userTuples);
print TRAIN_FILE "$lastUser\t$numTrainUnits\t$numItems\n";

# imprime tuplas temporalmente ordenadas crescentemente
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
        print "\tOutput file name \n\n";
}
