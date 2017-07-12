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

using namespace std;
using namespace __gnu_cxx;

void recommendForgottenItems(long int testMoment, vector<myPair> &forgottenItems, int contextSize, HashOfHashes &trainingData, User &currentUser, int getAllItems);
void reorderForgottenItems(Hash &associativeMemory, set<int> &context, vector<myPair> &forgottenItems, int getAllItems);

#endif