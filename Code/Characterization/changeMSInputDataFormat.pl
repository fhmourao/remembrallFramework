#!/bin/perl
use strict;
use warnings;

### Declaracao de variaveis
my $continuousItemId;
my $continuousUserId;
my $counter;
my $itemId;
my $lastUser;
my $line;
my $numItems;
my $numTrain;
my $playCount;
my $rating;
my $song;
my $user;
my $userId;

my %mapSongId;
my %mapUserId;
my %userItems;

#verifica parametros de entrada
die usage() if $#ARGV != 2;

# abre arquivo de entrada
open FIN, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]!";

#abre arquivo de saida
open FOUT, ">".$ARGV[1] or die "Can't open the output file $ARGV[1]!";

$numItems = 0;
my $TRAIN_RATE = $ARGV[2];
if( ($TRAIN_RATE < 0.0) || ($TRAIN_RATE > 1.0) ){
	die usage();
}

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

			print FOUT "$userId\t2\t$numItems\n";

			$numTrain = int( ($numItems * $TRAIN_RATE) + 0.5);
			$counter = 0;
			foreach $itemId ( keys(%{$userItems{$userId}}) ){
				$rating = $userItems{$userId}{$itemId};
				if( $counter < $numTrain ){
					if($counter == 0){
						print FOUT "0 1";
					}
					
					print FOUT " $itemId:$rating";
				}
				else{
					if( $counter == $numTrain ){
						print FOUT "\n1 2";
					}
					
					print FOUT " $itemId:$rating";
				}
				$counter++;
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
print FOUT "$userId\t2\t$numItems\n";

$numTrain = int( ($numItems * $TRAIN_RATE) + 0.5);
$counter = 0;
foreach $itemId ( keys(%{$userItems{$userId}}) ){
	$rating = $userItems{$userId}{$itemId};
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
