#ifndef SNAPSHOT_H
#define SNAPSHOT_H

#include <iostream>
#include <string>
#include <vector>
#include <stdlib.h> 

using namespace std;
using namespace __gnu_cxx;

typedef struct{
        unsigned int item;
	float score;
} myPair;

class snapshot {
	//temporal information about the snapshot
	unsigned long int startMoment;
	unsigned long int endMoment;
	float sumOfScores;
	int numItems;

	//list of items consumed during the snapshot
	std::vector<myPair> consumedItems;
	
	//Public functions
public:
	//constructor
	snapshot();
	snapshot(unsigned long int startMoment, unsigned long int endMoment);
	
	//desctructor
	~snapshot();
	
	//Get functions
	unsigned long int getStartMoment();
	unsigned long int getEndMoment();
	int getNumItems();
	float getSumOfScores();
	std::vector<myPair> getConsumedItems();

	//Set functions
	void setConsumedItems(std::vector<int> &items, std::vector<float> &scores);
	
private:
	
	inline void setSumOfScores(float sum);
};

#endif
