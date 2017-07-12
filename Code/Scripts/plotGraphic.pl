#!/bin/user/perl
use strict;
use warnings;

my $dataFile;
my $line;
my $lineCounter;
my $title;

### Verify input parameters
die usage() if $#ARGV != 4;

### Get input parameters
open FIN, "<".$ARGV[0] or die "Can't open the input file $ARGV[0]|";

# Open output file
my $GNUPLOT_FILE = $ARGV[1];
open FOUT, ">".$GNUPLOT_FILE or die "Can't open the file $GNUPLOT_FILE!";

my $GRAPHIC_FILE = $ARGV[2];

my $X_TITLE = $ARGV[3];
my $Y_TITLE = $ARGV[4];

### print the gnuplot commands in the outpt file
print FOUT "reset\n";
print FOUT "set term postscript eps 30 enhanced color\n";
print FOUT "set encoding iso_8859_1\n";
print FOUT "set key right top\n";

print FOUT "set xlabel \"$X_TITLE\"\n";
print FOUT "set ylabel \"$Y_TITLE\"\n";
print FOUT "set xrange [:]\n";
print FOUT "set yrange [:]\n";

print FOUT "set pointsize 1\n";
print FOUT "set style line 1 lc 3 lt 1 pt 7\n";
print FOUT "set style line 2 lc 7 lt 1 pt 3\n";
print FOUT "set style line 3 lc 1 lt 1 pt 9\n";
print FOUT "set style line 4 lc 2 lt 1 pt 1\n";
print FOUT "set style line 5 lc 5 lt 1 pt 5\n";
print FOUT "set style line 6 lc 6 lt 2 pt 7\n";
print FOUT "set xtics nomirror rotate by -45\n";
print FOUT "set output \"$GRAPHIC_FILE\"\n";

$lineCounter = 1;
while( defined($line = <FIN>) ) {
	chomp($line);

	($title,$dataFile) = split(/\t/,$line);
	
	if($lineCounter == 1){
		if( $title eq "notitle" ){
			print FOUT "plot [][] \"$dataFile\" using 1:2 notitle with lines ls $lineCounter";
		}
		else{
			print FOUT "plot [][] \"$dataFile\" using 1:2 title \"$title\" with lines ls $lineCounter";
		}
	}
	else{
		if( $title eq "notitle" ){
			print FOUT ",\\\n       \"$dataFile\" using 1:2 notitle with linespoints ls $lineCounter";
		}
		else{
			print FOUT ",\\\n       \"$dataFile\" using 1:2 title \"$title\" with linespoints ls $lineCounter";
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
	print "\tY axis title \n\n";
}
