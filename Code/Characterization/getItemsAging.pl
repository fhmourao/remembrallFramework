#!/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my $age;
my $endTime;
my $item;
my $itemId;
my $k;
my $line;
my $numTimeUnits;
my $rating;
my $startTime;
my $userId;
my $numItems;

my @items;

my %itemBorningTime;
my %lastUserMoment;

#verifica o número de parametros informados
die usage() if $#ARGV != 1;

open INPUT_DATA, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

open FOUT, ">".$ARGV[1] or die "Can't open the input file $ARGV[1]!";

# generate item's age information
while( defined( $line = <INPUT_DATA> ) ){
	chomp($line);
     
	($userId, $numTimeUnits, $numItems) = split(/[ \t]/, $line);
	
	#cria partição de treino
	for($k=0; $k<$numTimeUnits; $k++){
	
		#lê linha do arquivo de entrada
		$line = <INPUT_DATA>;
		chomp($line);
		
		#recupera cada campo da linha lida
		($userId, $startTime, $endTime, @items) = split(/[ \t]/,$line);
		
		foreach $item (@items){
			($itemId, $rating) = split(/:/, $item);
			
			if( exists($itemBorningTime{$itemId}) ){
				if( $startTime < $itemBorningTime{$itemId} ){
					$itemBorningTime{$itemId} = $startTime;
				}
			}
			else{
				$itemBorningTime{$itemId} = $startTime;
			}
		}
		splice(@items);
	}
	
	$lastUserMoment{$userId} = $endTime;
}
seek(INPUT_DATA, 0, 0);

# imprime informacao de idade em arquivo de saida
while( defined($line = <INPUT_DATA>) ){
	chomp($line);
     
	($userId, $numTimeUnits, $numItems) = split(/[ \t]/, $line);
	
	#cria partição de treino
	for($k=0; $k<$numTimeUnits; $k++){
	
		#lê linha do arquivo de entrada
		$line = <INPUT_DATA>;
		chomp($line);
		
		#recupera cada campo da linha lida
		($userId, $startTime, $endTime, @items) = split(/[ \t]/,$line);
		
		foreach $item (@items){
			($itemId, $rating) = split(/:/, $item);
		

			if( exists($itemBorningTime{$itemId}) ){
				# startTime eh valido
				if( $startTime != -1 ){
					$age = $startTime - $itemBorningTime{$itemId};	
				}
				else{
					$age = $lastUserMoment{$userId} - $itemBorningTime{$itemId};	
					if($age < 0){
						$age = 0;
					}
				}
			}
			else{
				$age = 0;
			}
			
			print FOUT "$userId\t$itemId\t$age\n";
		}
		
		splice(@items);
	}
}
close(INPUT_DATA);
close(FOUT);

sub usage{
	print "\nIn order to run this script you should give 2 input parameters:\n";
	print " \tInput training file name \n";
	print " \tOutput file name \n\n";
};

