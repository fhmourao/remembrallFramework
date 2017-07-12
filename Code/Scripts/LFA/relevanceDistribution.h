#ifndef RELEVANCEDISTRIBUTION_H
#define RELEVANCEDISTRIBUTION_H

#include <iostream>
#include <string>
#include <vector>
#include <set>
#include <cmath>
#include <stdio.h>

#include "snapshot.h"

#define MIN_PRECISION 0.001

struct eq {
	bool operator()(const float &p1, const float &p2) const{
		if(p1 < p2)
			return 0;
		else
			return 1;
	}
};

class relevanceDistribution{

	//rank distribution
	std::multiset<float, eq> distribution;
	
	//critical points for the distribution
	float fallPoint;
	float lapsePoint;

	//Public functions
public:
	//constructor
	relevanceDistribution();
	
	//destructor
	~relevanceDistribution();
	
	//Get functions
	float getFallPoint();
	float getLapsePoint();

	//Set functions
	void setDistribution(std::vector<snapshot> &history);
	
	void printDistribution();

private:
	void setCriticalPoints();
	float dividedDifferencesMethod();
	float finiteDifferencesMethod();
};

#endif
