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
#define MAX_TAL -2.0
#define MIN_TAL -5.0
#define NOISE 0.25
#define MIN_FREQ 30

using namespace std;
using namespace __gnu_cxx;

float deriveSimilarity(int item1, int item2, HashOfHashes &trainingData, HashOfHashes &itemsSimilarity);
void generateActivationScores(int temporalDistance, float tal, HashOfHashes &trainingData, User &currentUser, HashOfHashes &itemsSimilarity, Hash &recommendations, vector<float> &retrievalProbability);

#endif
