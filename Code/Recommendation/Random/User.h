#ifndef USER_H
#define USER_H

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

#include "snapshot.h"

#define INVALID_ID -1

using namespace std;
using namespace __gnu_cxx;

typedef std::unordered_map<int, float> Hash;
typedef std::unordered_map<int, Hash> HashOfHashes;

class User {
	//global and unique user ID
	unsigned int userId;
	int historySize;
	
	//basic structures related to each user
	std::vector<snapshot> consumptionHistory;
	
	//Public functions
public:
	//constructor
	User();
	User(unsigned int userId);
	
	//desctructor
	~User();

	//Get functions
	std::vector<snapshot> getUserHistory();
	unsigned int getUserId();
	int getHistorySize();
	
	//functions for handling basic structures
	void setUserHistory(int trainingUser, std::ifstream &inputFile);
// 	void setConsumptionFunction(consumptionFunction &consumptions);
		
};

void string_tokenize(const std::string &str, std::vector<std::string> &tokens, const std::string &delimiters);

#endif
