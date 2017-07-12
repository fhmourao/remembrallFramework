/************************************************************************
                            recommendation.cpp
************************************************************************/

#include "recommendation.h"

bool floatComparison(const float &a,const float &b) {
    return ( a > b);
}

float deriveSimilarity(int item1, int item2, HashOfHashes &trainingData){
	float prob1;
	float prob2;
	float similarity = 0.0;
	
	int totalNumItems = 0;
	int numOccItem1 = 0;
	int numOccItem2 = 0;
	int intersectionSize = 0;
	
	Hash::iterator itr1;
	Hash::iterator itr2;
	
	totalNumItems = trainingData.size();
	numOccItem1 = trainingData[item1].size();
	numOccItem2 = trainingData[item2].size();
	
	if( numOccItem1 < numOccItem2 ){
		for( itr1=trainingData[item1].begin(); itr1!=trainingData[item1].end(); itr1++ ){
			
			itr2 = trainingData[item2].find(itr1->first);
			if( itr2 != trainingData[item2].end() )
				intersectionSize++;
			
		}		
	}
	else{
		for( itr1=trainingData[item2].begin(); itr1!=trainingData[item2].end(); itr1++ ){
			
			itr2 = trainingData[item1].find(itr1->first);
			if( itr2 != trainingData[item1].end() )
				intersectionSize++;
			
		}		
	}
	
	prob1 = (float) intersectionSize/ (float) numOccItem2;
	prob2 = (float) numOccItem1/ (float) totalNumItems;
	
	if( (prob1 > 0.0) && (prob2 > 0.0) )
		similarity = log(prob1/prob2);
	
	return similarity;
}

void recommendForgottenItems(long int testMoment, vector<myPair> &forgottenItems, int contextSize, HashOfHashes &trainingData, User &currentUser){
	int historySize;
	int numItems;
	
	vector<myPair> consumedItems;
	Hash activationScore;
	Hash baseLevelLearning;
	vector<snapshot> history;
	set<int> context;
	
	set<int>::iterator itr1;
	Hash::iterator itr;
	
	myPair auxilary;
	snapshot currentSnapshot = snapshot();
	
	history = currentUser.getUserHistory();
	historySize = (int) history.size();

	//define context
	for(int i=historySize-contextSize; i<historySize; i++){
		currentSnapshot = history[i];
		numItems = (int) currentSnapshot.getNumItems();
		consumedItems = currentSnapshot.getConsumedItems();
		
		for(int j=0; j<numItems; j++)
			context.insert(consumedItems[j].item);
		
		consumedItems.clear();
	}

	// for each past moment
	for(int i=0; i<historySize; i++){
		currentSnapshot = history[i];
		numItems = (int) currentSnapshot.getNumItems();
		consumedItems = currentSnapshot.getConsumedItems();

		// for each item consumed at that moment
		for(int j=0; j<numItems; j++){
			auxilary = consumedItems[j];

			itr = baseLevelLearning.find(auxilary.item);
			if( itr != baseLevelLearning.end() )
				baseLevelLearning[auxilary.item] += auxilary.score;
			else
				baseLevelLearning[auxilary.item] = auxilary.score;
		}
		
		consumedItems.clear();
	}

	// for each consumed item
	for(itr=baseLevelLearning.begin(); itr!=baseLevelLearning.end(); itr++)				
		activationScore[itr->first] = itr->second;
	
	reorderForgottenItems(activationScore, context, forgottenItems);
}

void reorderForgottenItems( Hash &activationScore,  set<int> &context, vector<myPair> &forgottenItems){

	myPair auxilary;	
	Hash::iterator itr;
	vector<myPair> temporaryVector;
	set<int>::iterator itr1;
	
	for( itr=activationScore.begin(); itr!=activationScore.end(); itr++ ){
//		itr1 = context.find(itr->first);
		
//		if( itr1 == context.end() ){
			auxilary.item = itr->first;
			auxilary.score = itr->second;
			
			forgottenItems.push_back(auxilary);
//		}
	}
}
