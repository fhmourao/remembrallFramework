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
#include <time.h>

#include "User.h"
#include "snapshot.h"

#define PRECISION 0.9
#define DECAY_FACTOR 0.5
#define MIN_FREQ 30

using namespace std;
using namespace __gnu_cxx;

void recommendForgottenItems(vector<myPair> &forgottenItems, User &currentUser);
inline void reorderForgottenItems(float cutOffPoint, Hash &activationScore, vector<myPair> &forgottenItems);

#endif