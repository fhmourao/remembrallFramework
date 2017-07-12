#include <iostream>
#include <string>
#include <vector>
#include <set>
#include <cmath>
#include <stdio.h>

#define MAX_ATTEMPTS 5

struct eq {
	bool operator()(const float &p1, const float &p2) const{
		if(p1 < p2)
			return 0;
		else
			return 1;
	}
};


float simpsonMethod(float lowerBound, float upperBound, std::multiset<float, eq> &distribution){
	float h;
	float sum = 0.0;

	std::multiset<float, eq>::iterator itr;
	std::vector<float> sample;

	std::cout << "\tTestando intervalo: " << lowerBound << "\t" << upperBound << "\n";
	for(itr=distribution.begin(); itr != distribution.end(); itr++){
		if( (*itr <= lowerBound) && (*itr >= upperBound) )
			sample.push_back(*itr);
	}

	int numSamples = (int) sample.size();
	if(numSamples > 0){
		
		h = (lowerBound - upperBound) / (float) numSamples;
		sum = sample[0];

		//even numbers
		for(int i=2; i<(numSamples-1); i+=2){
			sum += 2*sample[i];
		}

		//odd numbers
		for(int i=1; i<(numSamples-1); i+=2){
			sum += 4*sample[i];
		}

		sum += sample[numSamples-1];

		sum = sum * h/3;
		
	}

	std::cout << "\t\tSum: " << sum << "\n";
	return sum;
}

int inline recalculateArea(float lowerBound, float &middlePoint, float upperBound, int shiftDirection, std::multiset<float, eq> &distribution){
	float area1;
	float area2;
	float hasReducedSumOfAreas;
	float newArea1;
	float newArea2;
	float repositioning;
	float stepSize;
	float sumOfArea;
	float sumOfNewArea;

	area1 = simpsonMethod(lowerBound, middlePoint, distribution);
	area2 = simpsonMethod(middlePoint, upperBound, distribution);
	sumOfArea = area1 + area2;

	hasReducedSumOfAreas = 0;
	
	if( shiftDirection < 0 )
		stepSize = lowerBound - middlePoint;
	else
		stepSize = middlePoint - upperBound;
	
	for(int numAttempts=0; numAttempts<MAX_ATTEMPTS; numAttempts++){
		stepSize = stepSize/2;
		if( shiftDirection < 0 )
			repositioning = middlePoint - stepSize;
		else
			repositioning = middlePoint + stepSize;
		
		newArea1 = simpsonMethod(lowerBound, repositioning, distribution);
		newArea2 = simpsonMethod(repositioning, upperBound, distribution);
		sumOfNewArea = newArea1 + newArea2;
		
		if(sumOfNewArea < sumOfArea){
			hasReducedSumOfAreas = 1;
			middlePoint = repositioning;
			sumOfArea = sumOfNewArea;
		}
	}

	return hasReducedSumOfAreas;
}

int main(int argc, char **argv){
	float firstPoint;
	int hasReducedSumOfAreas;
	float interval;
	float lowerBound;
	float originalFirstPoint;
	float originalSecondPoint;
	float pieceSize;
	float secondPoint;
	int shiftDirection;
	float upperBound;

	std::multiset<float, eq> distribution;
	for(int x=1; x<500; x++)
		distribution.insert(pow(x, -0.74));

	lowerBound = pow(1, -0.74);
	upperBound = pow(499, -0.74);
	
	std::cout << lowerBound << "\t" << upperBound << "\n";

	interval = lowerBound - upperBound;
	pieceSize =  interval/3;
	firstPoint = lowerBound - pieceSize;
	secondPoint = upperBound + pieceSize;

	std::cout << firstPoint << "\t" << secondPoint << "\t" << pieceSize << "\n";

	do {
		originalFirstPoint = firstPoint;
		originalSecondPoint = secondPoint;

		shiftDirection = -1;
		hasReducedSumOfAreas = recalculateArea(lowerBound, firstPoint, secondPoint, shiftDirection, distribution);
		
		if( !hasReducedSumOfAreas ){
			std::cout << "\t\tNo gains!!!" << "\n";
			shiftDirection = 1;
			hasReducedSumOfAreas = recalculateArea(lowerBound, firstPoint, secondPoint, shiftDirection, distribution);
			
		}
		
		shiftDirection = -1;
		hasReducedSumOfAreas = recalculateArea(firstPoint, secondPoint, upperBound, shiftDirection, distribution);
		
		if( !hasReducedSumOfAreas ){
			std::cout << "\t\tNo gains!!!" << "\n";
			shiftDirection = 1;
			hasReducedSumOfAreas = recalculateArea(firstPoint, secondPoint, upperBound, shiftDirection, distribution);
			
		}
		
		std::cout << firstPoint << "\t" << secondPoint << "\n";
		break;
		
	} while( (firstPoint != originalFirstPoint) || (secondPoint != originalSecondPoint) );

	std::cout << firstPoint << "\t" << secondPoint << "\n";

	return 0;
}