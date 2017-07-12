#!/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my $continuousItemId;
my $continuousUserId;
my $itemId;
my $lastUser;
my $line;
my $numItems;
my $playCount;
my $rating;
my $song;
my $user;
my $userId;

my %mapSongId;
my %mapUserId;
my %userItems;

#verifica parametros de entrada
die usage() if $#ARGV != 1;

# abre arquivo de entrada
open FIN, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

#abre arquivo de saida
open FOUT, ">".$ARGV[1] or die "Can't open the output file $ARGV[1]!";

$numItems = 0;
$continuousItemId = 1;
$continuousUserId = 1;
$lastUser = "invalid";
while( defined($line = <FIN>) ){
	chomp($line);
	
	($user, $song, $playCount) = split(/\t/, $line);

	if( $user ne $lastUser ){
		if( $lastUser ne "invalid" ){
			$userId = $mapUserId{$lastUser};
			$numItems = scalar keys(%{$userItems{$userId}});

			print FOUT "$userId\t1\t$numItems\n0 1";

			foreach $itemId ( keys(%{$userItems{$userId}}) ){
				$rating = $userItems{$userId}{$itemId};
				
				print FOUT " $itemId:$rating";
			}
			
			print FOUT "\n";
		}

		$lastUser = $user;
		%userItems = ();
		$numItems = 0;
	}

	if( !exists($mapSongId{$song}) ){
		$mapSongId{$song} = $continuousItemId++;
	}

	if( !exists($mapUserId{$user}) ){
		$mapUserId{$user} = $continuousUserId++;
	}

	$itemId = $mapSongId{$song};
	$userId = $mapUserId{$user};
	if( (exists($userItems{$userId})) && (exists($userItems{$userId}{$itemId})) ){
		$userItems{$userId}{$itemId} += $playCount;
	}
	else{
		$userItems{$userId}{$itemId} = $playCount;
		$numItems++;
	}	
}
close(FIN);

$userId = $mapUserId{$lastUser};
$numItems = scalar keys(%{$userItems{$userId}});
print FOUT "$userId\t1\t$numItems\n0 1";

foreach $itemId ( keys(%{$userItems{$userId}}) ){
	$rating = $userItems{$userId}{$itemId};
	
	print FOUT " $itemId:$rating";
}
print FOUT "\n";
close(FOUT);

sub usage{
        print "\nIn order to run this script you should give 2 input parameters:\n";
        print "\tInput file name \n";
        print "\tOutput file name \n\n";
}
