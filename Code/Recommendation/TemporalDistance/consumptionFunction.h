#ifndef CONSUMPTIONFUNCTION_H
#define CONSUMPTIONFUNCTION_H

#include <iostream>
#include <string>
#include <vector>
#include <set>

class consumptionFunction{
	//internal components
	std::vector<float> coefficients;
	std::vector<unsigned long int> criticalMoments;

	//Public functions
public:
	//constructor
	consumptionFunction();
	
	//destructor
	~consumptionFunction();
	
	//Get functions
	float getBorningMoment();
	float getLapsePoint();

	//Set functions
	void setDistribution(std::vector<snapshot> &history);

private:
	void setCriticalPoints();
	void relevanceDistribution::dividedDifferencesMethod();
	void relevanceDistribution::finiteDifferencesMethod();
}

#endif
