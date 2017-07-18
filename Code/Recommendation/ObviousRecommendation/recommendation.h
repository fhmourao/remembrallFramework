#ifndef RECOMMENDATION_H
#define RECOMMENDATION_H

#include <set>
#include <stdio.h>
#include <string>
#include <sstream>
#include <vector>
#include <algorithm>
#include <string.h>
#include <math.h> 

#include "User.h"
#include "snapshot.h"

#define PRECISION 0.9
#define DECAY_FACTOR 0.5
#define MIN_FREQ 15
#define MAX_HASH_ENTRIES 100000

using namespace std;
using namespace __gnu_cxx;

float defineCutOffPoint(Hash &activationScore, set<int> context);
float deriveSimilarity(int item1, int item2, HashOfHashes &trainingData, HashOfHashes &itemsSimilarity);
void recommendForgottenItems(long int testMoment, vector<myPair> &forgottenItems, int contextSize, HashOfHashes &trainingData, User &currentUser, HashOfHashes &itemsSimilarity, int getAllItems);
inline void reorderForgottenItems(float cutOffPoint, Hash &activationScore, vector<myPair> &forgottenItems, int getAllItems);

#endif