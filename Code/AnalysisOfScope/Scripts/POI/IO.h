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

bool comparisonFunction(float a,float b);
short getArguments(char **trainFile, char **recommendationFile, char **outputFile, int &temporalDistance, float &talValue, int argc, char **argv);
void loadRecommendations(char *inputFileName, HashOfHashes &recommendationsPerUser);
void loadTraingData(char *inputFileName, vector<int> &domainUsers, HashOfHashes &trainingData);
void printMedianProbability(vector<float> &retrievalProbability, std::ofstream &outputFile);
void printUsage();

#endif
