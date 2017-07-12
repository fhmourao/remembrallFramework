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
	
	if( (numOccItem1 > MIN_FREQ) || (numOccItem2 > MIN_FREQ) ){
		if( item1 < item2 )
			itemsSimilarity[item1][item2] = similarity;
		else
			itemsSimilarity[item2][item1] = similarity;
	}

	return similarity;
}

void generateActivationScores(int temporalDistance, float tal, HashOfHashes &trainingData, User &currentUser, HashOfHashes &itemsSimilarity, Hash &recommendations, vector<float> &retrievalProbability){
	float associativeMemory;
	float activationScore;
	float associativeStrenght;
	float maxContextScore = 0.0;
	int historySize;
	int numItems;
	int numOldItems;
	int testMoment;
	int numForgottenItems = 0;
	
	vector<myPair> consumedItems;
	Hash baseLevelLearning;
	vector<snapshot> history;
	Hash::iterator itr;
	Hash::iterator itr1;
	Hash contextPerUser;
	
	myPair auxilary;
	snapshot currentSnapshot = snapshot();
	
	history = currentUser.getUserHistory();
	historySize = (int) history.size();
	
	//define context
	currentSnapshot = history[historySize-1];
	testMoment = currentSnapshot.getStartMoment();
	numItems = (int) currentSnapshot.getNumItems();
	consumedItems = currentSnapshot.getConsumedItems();
	for(int j=0; j<numItems; j++){
		contextPerUser[consumedItems[j].item] = consumedItems[j].score;
		if(consumedItems[j].score > maxContextScore)
			maxContextScore = consumedItems[j].score;
	}

	// for each moment
	for(int i=0; i<historySize; i++){
		currentSnapshot = history[i];
		numItems = (int) currentSnapshot.getNumItems();
		consumedItems = currentSnapshot.getConsumedItems();

		// for each item consumed at that moment
		for(int j=0; j<numItems; j++){
			auxilary = consumedItems[j];
			
			//if it is a recommended one
			itr = recommendations.find(auxilary.item);
			if(itr != recommendations.end()){
				
				itr = baseLevelLearning.find(auxilary.item);
				if( itr != baseLevelLearning.end() )
					baseLevelLearning[auxilary.item] += pow(testMoment-currentSnapshot.getStartMoment()+1, -DECAY_FACTOR);
				else
					baseLevelLearning[auxilary.item] = pow(testMoment-currentSnapshot.getStartMoment()+1, -DECAY_FACTOR);
			}
		}
		
		consumedItems.clear();
	}
	
	// for each consumed item
	numOldItems = (int) baseLevelLearning.size();
	for(itr=baseLevelLearning.begin(); itr!=baseLevelLearning.end(); itr++){
		associativeMemory = 0.0;
		
		for(itr1= contextPerUser.begin(); itr1!= contextPerUser.end(); itr1++){
			associativeStrenght = deriveSimilarity(itr->first, itr1->first, trainingData, itemsSimilarity);
			associativeMemory = associativeStrenght * itr1->second/maxContextScore * 1/numOldItems;
		}
			
		activationScore = log(baseLevelLearning[itr->first]) + associativeMemory;
		if(activationScore <= tal)
			numForgottenItems++;
	}
	
	float percentageOfForgottenItems = ((float) numForgottenItems)/((float) recommendations.size());

	retrievalProbability.push_back(percentageOfForgottenItems);
}
