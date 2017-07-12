#ifndef USERKNN_H
#define USERKNN_H

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
#define USER_REGULARIZATION 15
#define ITEM_REGULARIZATION 10
#define NUM_ITERACTIONS 10

using namespace std;

typedef std::unordered_map<int, float> Hash;
typedef std::unordered_map<int, Hash> HashOfHashes;

typedef struct{
        double score;
        unsigned int item;
} myPair;

struct eq {
        bool operator()(const myPair &p1, const myPair &p2) const{
                if(p1.score >= p2.score)
                        return 1;
                else
                        return 0;
        }
};

/* estrutura que define os parametros para funcao da thread */
struct pthread_param {
	int threadId;
	int numThreads;
	int K;
	float globalAverage;
	float recommendationPercentage;
	Hash* itemBias;
	Hash* userBias;
	HashOfHashes* testingItems;
	HashOfHashes* itemRatings;
	HashOfHashes* userRatings;
	char *outFileName;
};

int MIN_SCORE = 1;
int MAX_SCORE = 5;

int main(int argc, char **argv);

void *performRecommendation(void *arg);

float calculateCosineSimilarity(int firstUser, int secondUser, HashOfHashes &userRatings);

void calculateItemBiases(HashOfHashes &itemRatings, Hash &itemBias, Hash &userBias, float globalAverage);

void calculateUserBiases(HashOfHashes &userRatings, Hash &userBias, Hash &itemBias, float globalAverage);

void defineIndividualBias(HashOfHashes &userRatings, Hash &userBias, HashOfHashes &itemRatings, Hash &itemBias, float globalAverage);

void getKNNUsers(int userId, HashOfHashes &userRatings, multiset<myPair,eq> &candidateSet);

inline float getValidScore(float score);

void recommendItems(int userId, Hash &testingItems, HashOfHashes &userRatings, HashOfHashes &itemRatings, Hash &userBias, Hash &itemBias, int K, float globalAverage, float recommendationPercentage, std::ofstream &outputFile) ;

void loadTestData(char *testFile, HashOfHashes &testingItems);

void loadTrainData(char *trainFile, HashOfHashes &itemRatings, HashOfHashes &userRatings, float &globalAverage);

int getArgs(int argc, char **argv, char **trainFileName, char **testFileName, char **outFileName, int *numThreads, int *K, float *recommendationPercentage);

void string_tokenize(const std::string &str, std::vector<std::string> &tokens, const std::string &delimiters);

void printUsage();

#endif

