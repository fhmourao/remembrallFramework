#ifndef CONFIG_H
#define CONFIG_H

#include <istream>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdio.h>
#include <string>
#include <unordered_map> 
#include <vector>
#include <map>
#include <string.h>

#define PRECISION 0.9
#define DECAY_FACTOR 0.5
#define TAL -2.5
#define NOISE 0.4
#define MIN_FREQ 30
#define INVALID_ID -1

using namespace std;
using namespace __gnu_cxx;

typedef unordered_map<int, float> Hash;
typedef unordered_map<int, Hash> HashOfHashes;

#endif