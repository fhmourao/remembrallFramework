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

#define INVALID_VALUE -999
#define USER_REGULARIZATION 15
#define ITEM_REGULARIZATION 10
#define NUM_ITERACTIONS 10
#define MIN_INTERSECTION 5

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
	int TOP_N;
	float globalAverage;
	Hash* itemBias;
	Hash* userBias;
	std::set<int>* testUsers;
	HashOfHashes* itemRatings;
	HashOfHashes* userRatings;
	HashOfHashes* itemSimilarities;
	char *outFileName;
};

int MIN_SCORE = 1;
int MAX_SCORE = 5;

int main(int argc, char **argv);

void *performRecommendation(void *arg);

float calculateCosineSimilarity(int firstItem, int secondItem, HashOfHashes &itemRatings);

void calculateItemBiases(HashOfHashes &itemRatings, Hash &itemBias, Hash &userBias, float globalAverage);

void calculateUserBiases(HashOfHashes &userRatings, Hash &userBias, Hash &itemBias, float globalAverage);

void defineIndividualBias(HashOfHashes &userRatings, Hash &userBias, HashOfHashes &itemRatings, Hash &itemBias, float globalAverage);

void getKNNItems(int itemId, int K, HashOfHashes &itemRatings, HashOfHashes &itemSimilarities, multiset<myPair,eq> &candidateSet);

inline float getValidScore(float score);

void recommendItems(int userId, HashOfHashes &userRatings, HashOfHashes &itemRatings, HashOfHashes &itemSimilarities, Hash &userBias, Hash &itemBias, int K, int TOP_N, float globalAverage, std::ofstream &outputFile);

void loadTestData(char *testFile, std::set<int> &testUsers);

void loadTrainData(char *trainFile, HashOfHashes &itemRatings, HashOfHashes &userRatings, float &globalAverage);

int getArgs(int argc, char **argv, char **trainFileName, char **testFileName, char **outFileName, int *numThreads, int *K, int *TOP_N);

void string_tokenize(const std::string &str, std::vector<std::string> &tokens, const std::string &delimiters);

void printUsage();

#endif

