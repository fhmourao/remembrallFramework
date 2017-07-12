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

my %userTuples;

my $INVALID_USER = -999;

#verifica o número de parametros informados
die usage() if $#ARGV != 3;

open FIN,"<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

open FOUT,">".$ARGV[1] or die "Can't open the input file $ARGV[1]!";

my $FIRST_TIMESTAMP = $ARGV[2];

my $TIME_INTERVAL = $ARGV[3];

$numItems = 0;
$lastUser = $INVALID_USER;
while( defined($line = <FIN>) ){
	chomp($line);

	($userId, $itemId, $rating, $timestamp) = split(/[ \t]/, $line);

	# se eh um novo usuario
	if($userId != $lastUser){
		# se usuario anterior eh valido
		if( $lastUser != $INVALID_USER){

			$numTimeUnits = scalar keys(%userTuples);
			print FOUT "$lastUser\t$numTimeUnits\t$numItems\n";

			# imprime tuplas temporalmente ordenadas crescentemente
			foreach $timeUnit ( sort{$a <=> $b} keys(%userTuples) ){
				print FOUT $timeUnit," ",$timeUnit+1;

				foreach $itemId ( keys(%{$userTuples{$timeUnit}})){
					print FOUT " ", $itemId,":",$userTuples{$timeUnit}{$itemId};
				}
				print FOUT "\n";

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
	$userTuples{$timeUnit}{$itemId} = $rating;

	

}
close(FIN);

$numTimeUnits = scalar keys(%userTuples);
print FOUT "$lastUser\t$numTimeUnits\t$numItems\n";

# imprime tuplas temporalmente ordenadas crescentemente
foreach $timeUnit ( sort{$a <=> $b} keys(%userTuples) ){
	print FOUT $timeUnit," ",$timeUnit+1;

	foreach $itemId ( keys(%{$userTuples{$timeUnit}})){
		print FOUT " ", $itemId,":",$userTuples{$timeUnit}{$itemId};
	}
	print FOUT "\n";

	%{$userTuples{$timeUnit}} = ();
}

%userTuples = ();
close(FOUT);

sub usage{
        print "\nIn order to run this script you should give 4 input parameters:\n";
        print "\tInput file name \n";
        print "\tOutput file name \n";
        print "\tFirst timestamp\n";
        print "\tTime interval \n\n";
}
