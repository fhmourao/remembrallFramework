#ifndef ITEMKNN_H
#define ITEMKNN_H

#include <istream>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdio.h>
#include <string>
#include <sstream>
#include <map>
#include <algorithm>
#include <math.h>
#include <set>
#include <vector>
#include <unordered_map> 
#include <pthread.h>
#include <getopt.h>

#define INVALID_VALUE -999
#define MIN_INTERSECTION 5
#define MAX_SIZE 100

using namespace std;

typedef std::unordered_map<int, float> Hash;
typedef std::unordered_map<int, Hash> HashOfHashes;

typedef struct{
        double score;
        unsigned int item;
} myPair;

/* estrutura que define os parametros para funcao da thread */
struct pthread_param {
	int threadId;
	int numThreads;
	HashOfHashes* itemRatings;
	HashOfHashes* userRatings;
	char *outFileName;
};

int main(int argc, char **argv);

void *performRecommendation(void *arg);

float calculateCosineSimilarity(int firstItem, int secondItem, HashOfHashes &itemRatings);

bool comparisonFunctionAsc(const myPair &a,const myPair &b);

bool comparisonFunctionDesc(const myPair &a,const myPair &b);

void recommendItems(int userId, HashOfHashes &userRatings, HashOfHashes &itemRatings, std::ofstream &outputFile);

void loadTrainData(char *trainFile, HashOfHashes &itemRatings, HashOfHashes &userRatings);

int getArgs(int argc, char **argv, char **trainFileName, char **outFileName, int *numThreads);

void string_tokenize(const std::string &str, std::vector<std::string> &tokens, const std::string &delimiters);

void printUsage();

#endif

