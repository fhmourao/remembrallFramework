/************************************************************************
                            recommendation.cpp
************************************************************************/

#include "recommendation.h"

float deriveSimilarity(int item1, int item2, HashOfHashes &trainingData, HashOfHashes &itemsSimilarity){
	float prob1;
	float prob2;
	float similarity = 0.0;
	
	int totalNumItems = 0;
	int numOccItem1 = 0;
	int numOccItem2 = 0;
	int intersectionSize = 0;
	
	Hash::iterator itr1;
	Hash::iterator itr2;
	HashOfHashes::iterator itr3;
	
	totalNumItems = trainingData.size();
	numOccItem1 = trainingData[item1].size();
	numOccItem2 = trainingData[item2].size();
	
	if( (numOccItem1 > MIN_FREQ) || (numOccItem2 > MIN_FREQ) ){
		if( item1 < item2 ){
			itr3 = itemsSimilarity.find(item1);
			if(itr3 != itemsSimilarity.end()){
				itr1 = itemsSimilarity[item1].find(item2);
				if(itr1 != itemsSimilarity[item1].end())
					return itemsSimilarity[item1][item2];
			}
		}
		else{
			itr3 = itemsSimilarity.find(item2);
			if(itr3 != itemsSimilarity.end()){
				itr1 = itemsSimilarity[item2].find(item1);
				if(itr1 != itemsSimilarity[item2].end())
					return itemsSimilarity[item2][item1];
			}
		}
	}
	
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
	
	if(itemsSimilarity.size() < MAX_HASH_ENTRIES){
		if( (numOccItem1 > MIN_FREQ) && (numOccItem2 > MIN_FREQ) ){
			if( item1 < item2 )
				itemsSimilarity[item1][item2] = similarity;
			else
				itemsSimilarity[item2][item1] = similarity;
		}
	}

	return similarity;
}

void recommendForgottenItems(long int testMoment, vector<myPair> &forgottenItems, int contextSize, HashOfHashes &trainingData, User &currentUser, HashOfHashes &itemsSimilarity, int getAllItems){
	float associativeStrenght;
	float maxContextScore;
	unsigned long int firstMoment;
	int historySize;
	int numItems;
	
	vector<myPair> consumedItems;
	Hash associativeMemory;
	Hash baseLevelLearning;
	vector<snapshot> history;
	Hash inverseBaseLevelLearning;
	Hash forgottenScore;
	Hash practiceFunction;
	Hash contextWeight;
	set<int> context;
	set<int> candidateItems;
	
	set<int>::iterator itr1;
	set<int>::iterator itr2;
	Hash::iterator itr;
	
	myPair auxilary;
	snapshot currentSnapshot = snapshot();
	
	history = currentUser.getUserHistory();
	candidateItems = currentUser.getCandidateItems();
	historySize = (int) history.size();
	firstMoment = history[0].getStartMoment();

	//define context
	maxContextScore = 0.0;
	for(int i=historySize-contextSize; i<historySize; i++){
		currentSnapshot = history[i];
		numItems = (int) currentSnapshot.getNumItems();
		consumedItems = currentSnapshot.getConsumedItems();
		
		for(int j=0; j<numItems; j++){
			context.insert(consumedItems[j].item);
			contextWeight[consumedItems[j].item] = consumedItems[j].score;
			if(consumedItems[j].score > maxContextScore)
				maxContextScore = consumedItems[j].score;
		}
		
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
			if( itr != baseLevelLearning.end() ){
				baseLevelLearning[auxilary.item] += pow(testMoment-currentSnapshot.getStartMoment(), -DECAY_FACTOR);
				inverseBaseLevelLearning[auxilary.item] += pow(currentSnapshot.getStartMoment()-firstMoment+1, -DECAY_FACTOR);
				practiceFunction[auxilary.item] += (auxilary.score/(float) (currentSnapshot.getStartMoment()-firstMoment+1));
			}
			else{
				baseLevelLearning[auxilary.item] = pow(testMoment-currentSnapshot.getStartMoment(), -DECAY_FACTOR);
				inverseBaseLevelLearning[auxilary.item] = pow(currentSnapshot.getStartMoment()-firstMoment+1, -DECAY_FACTOR);
				practiceFunction[auxilary.item] = (auxilary.score/(float) (currentSnapshot.getStartMoment()-firstMoment+1));
			}
		}
		
		consumedItems.clear();
	}

	// for each consumed item
	for(itr1=candidateItems.begin(); itr1!=candidateItems.end(); itr1++){
		associativeMemory[*itr1] = 0;
		inverseBaseLevelLearning[*itr1] = log(inverseBaseLevelLearning[*itr1]+1);
		practiceFunction[*itr1] = log(practiceFunction[*itr1]+1);
		
		for(itr2= context.begin(); itr2!= context.end(); itr2++){
			associativeStrenght = deriveSimilarity(*itr1, *itr2, trainingData, itemsSimilarity);
			associativeStrenght = associativeStrenght * contextWeight[*itr2]/maxContextScore;
			associativeMemory[*itr1] += log(baseLevelLearning[*itr2]+1)*associativeStrenght;
		}
				
		forgottenScore[*itr1] = inverseBaseLevelLearning[*itr1] + associativeMemory[*itr1] + practiceFunction[*itr1];
	}

	reorderForgottenItems(forgottenScore, context, forgottenItems, getAllItems);
}

void reorderForgottenItems(Hash &associativeMemory, set<int> &context, vector<myPair> &forgottenItems, int getAllItems){
	myPair auxilary;
	Hash::iterator itr;
	vector<myPair> temporaryVector;
	set<int>::iterator itr1;
	
	for( itr=associativeMemory.begin(); itr!=associativeMemory.end(); itr++ ){
		itr1= context.find(itr->first);	
		
		if( (getAllItems == 1) || (itr1 == context.end()) ){
			auxilary.item = itr->first;
			auxilary.score = itr->second;
			
			forgottenItems.push_back(auxilary);
		}
	}
}
