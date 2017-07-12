#!/usr/bin/perl
use strict;
use warnings;


### Declaracao de variaveis
my $firstTime;
my $index;
my $lastIndex;
my $line;
my $metric;
my $numUsers;
my $userId;

my @metrics;
my @sumOfHits;

### Verifica parametros de entrada
die usage() if $#ARGV != 1;

### Abre arquivo de entrada
open FIN, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

### Abre arquivo de saida
open FOUT, ">".$ARGV[1] or die "Can't open the ouput file $ARGV[1]!";

$firstTime = 1;
$numUsers = 0;
while( defined($line = <FIN>) ){
	chomp($line);

	($userId, @metrics) = split(/[ \t]/, $line);

	if( $firstTime == 1){

		$index = 0;
		foreach $metric (@metrics){
			$sumOfHits[$index++] = $metric;
		}

		$firstTime = 0;
	}
	else{
		$index = 0;
		foreach $metric (@metrics){
			$sumOfHits[$index++] += $metric;
		}
	}

	splice(@metrics);
	$numUsers++;
}
close(FIN);

$firstTime = 1;
$lastIndex = $#sumOfHits;
foreach $metric (@sumOfHits){
	if( $firstTime == 1){
		
		print FOUT $metric/$numUsers;
		$firstTime = 0;
	}
	else{
		print FOUT "\t",$metric/$numUsers;
	}
}
print FOUT "\n";
close(FOUT);

sub usage{
        print "\nIn order to run this script you should give 2 input parameters:\n";
        print "\tInput file name \n";
        print "\tOutput file name \n\n";
}

