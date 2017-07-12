#ifndef IO_H
#define IO_H

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <algorithm>
#include <getopt.h>

#include "User.h"

using namespace std;
using namespace __gnu_cxx;

bool comparisonFunction(const myPair &a,const myPair &b);
short getArguments(char **trainFile, char **testFile, char **candidateFile, char **outputFile, int &contextSize, float &recommendationPercentage, int argc, char **argv);
void loadTraingData(char *inputFileName, HashOfHashes &trainingData);
void printRecommendations(User currentUser, long int testMoment, vector<myPair> &forgottenItems, int recommendationSize, std::ofstream &outputFile);
void printUsage();

#endif
