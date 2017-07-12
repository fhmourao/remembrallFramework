#!/bin/user/perl
use strict;
use warnings;

my $dataFile;
my $line;
my $lineCounter;
my $title;

### Verify input parameters
die usage() if $#ARGV != 5;

### Get input parameters
open FIN, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]|";

# Open output file
my $GNUPLOT_FILE = $ARGV[1];
open FOUT, ">".$GNUPLOT_FILE or die "Can't open the file $GNUPLOT_FILE!";

my $GRAPHIC_FILE = $ARGV[2];

my $X_TITLE = $ARGV[3];
my $Y_TITLE = $ARGV[4];
my $Z_TITLE = $ARGV[5];

### print the gnuplot commands in the outpt file
print FOUT "reset\n";
print FOUT "set term postscript eps 30 enhanced color\n";
print FOUT "set encoding iso_8859_1\n";
print FOUT "unset key\n";
print FOUT "set tic scale 0\n";

print FOUT "set xlabel \"$X_TITLE\"\n";
print FOUT "set ylabel \"$Y_TITLE\"\n";
print FOUT "set cblabel \"$Z_TITLE\"\n";
print FOUT "set xrange [:]\n";
print FOUT "set yrange [:]\n";
print FOUT "set cbrange [:]\n";
print FOUT "unset cbtics\n";

print FOUT "set view map\n";
print FOUT "set output \"$GRAPHIC_FILE\"\n";

$lineCounter = 1;
while( defined($line = <FIN>) ) {
	chomp($line);

	($title,$dataFile) = split(/\t/,$line);
	
	if($lineCounter == 1){
		if( $title eq "notitle" ){
			print FOUT "plot [][] \"$dataFile\" using 1:2:3 notitle with image";
		}
		else{
			print FOUT "plot [][] \"$dataFile\" using 1:2:3 title \"$title\" with image";
		}
	}
	else{
		if( $title eq "notitle" ){
			print FOUT ",\\\n       \"$dataFile\" using 1:2:3 notitle with image";
		}
		else{
			print FOUT ",\\\n       \"$dataFile\" using 1:2:3 title \"$title\" with image";
		}
	}
	$lineCounter++;
}

close(FOUT);

### run gnuplot
system("gnuplot $GNUPLOT_FILE;");

sub usage{
        print "\nIn order to run this script you should give 5 input parameters:\n";
        print "\tGnuplot data input file <format: value \\t probability>\n";
        print "\tGnuplot script output file name \n";
	print "\tGraphic output file name \n";
	print "\tX axis title \n";
	print "\tY axis title \n";
	print "\tZ axis title \n\n";
}