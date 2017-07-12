/************************************************************************
                            snapshot.cpp
************************************************************************/

#include "snapshot.h"

/* construtor */
snapshot::snapshot() {
	this->startMoment = -1;
	this->endMoment = -1;
}

snapshot::snapshot(unsigned long int startMoment, unsigned long int endMoment) {
	this->startMoment = startMoment;
	this->endMoment = endMoment;
}

/* destrutor */
snapshot::~snapshot() {
	this->startMoment = -1;
	this->endMoment = -1;
	this->sumOfScores = 0;
}


/**** Get functions ****/
unsigned long int snapshot::getStartMoment(){
	return this->startMoment;
}

unsigned long int snapshot::getEndMoment(){
	return this->endMoment;
}

int snapshot::getNumItems(){
	return this->numItems;
}

float snapshot::getSumOfScores(){
	return this->sumOfScores;
}

std::vector<myPair> snapshot::getConsumedItems(){
	return this->consumedItems;
}

/**** Set functions ****/
void snapshot::setConsumedItems(std::vector<int> &items, std::vector<float> &scores){
	float sum = 0.0;
	
	std::vector<int>::iterator itr;
	std::vector<int>::iterator itr1;
	
	myPair auxilary;
	
	//verify whether both input vectors have the same size
	int numItems = (int) items.size();
	int numFrequencies = (int) scores.size();
	
	if( numItems != numFrequencies ){
		std::cout << "\n\t*** ERROR: consumption vector with not aligned dimensions with the frequency vector" << "\n\n";
		exit(-1);
	}

	for(int i=0; i<numItems; i++){
		auxilary.item = items[i];
		auxilary.score = scores[i];
		this->consumedItems.push_back(auxilary);
		sum += (float) scores[i];
	}
	
	//atualize sum of frequencies
	setSumOfScores(sum);
	
	//atualize numItems
	this->numItems = numItems;
}


/****** Private Functions *******/
inline void snapshot::setSumOfScores(float sum){
	if( sum > 0){
		this->sumOfScores = sum;
	}
}