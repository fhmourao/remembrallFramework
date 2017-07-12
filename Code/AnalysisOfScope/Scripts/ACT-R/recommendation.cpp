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

void generateActivationScores(int temporalDistance, HashOfHashes &trainingData, User &currentUser, HashOfHashes &itemsSimilarity, HashOfHashes &contextPerUser, HashOfHashes &activationScore){
	float associativeMemory;
	float associativeStrenght;
	float maxContextScore = 0.0;
	int historySize;
	int numItems;
	int numOldItems;
	int testMoment;
	int userId;
	
	vector<myPair> consumedItems;
	Hash baseLevelLearning;
	vector<snapshot> history;
	Hash::iterator itr;
	Hash::iterator itr1;
	
	myPair auxilary;
	snapshot currentSnapshot = snapshot();
	
	userId = currentUser.getUserId();
	history = currentUser.getUserHistory();
	historySize = (int) history.size();
	
	//define context
	currentSnapshot = history[historySize-1];
	testMoment = currentSnapshot.getStartMoment();
	numItems = (int) currentSnapshot.getNumItems();
	consumedItems = currentSnapshot.getConsumedItems();
	for(int j=0; j<numItems; j++){
		contextPerUser[userId][consumedItems[j].item] = consumedItems[j].score;
		if(consumedItems[j].score > maxContextScore)
			maxContextScore = consumedItems[j].score;
	}

	// for each past moment
	for(int i=0; i<historySize-temporalDistance; i++){
		currentSnapshot = history[i];
		numItems = (int) currentSnapshot.getNumItems();
		consumedItems = currentSnapshot.getConsumedItems();

		// for each item consumed at that moment
		for(int j=0; j<numItems; j++){
			auxilary = consumedItems[j];

			itr = baseLevelLearning.find(auxilary.item);
			if( itr != baseLevelLearning.end() )
				baseLevelLearning[auxilary.item] += pow(testMoment-currentSnapshot.getStartMoment(), -DECAY_FACTOR);
			else
				baseLevelLearning[auxilary.item] = pow(testMoment-currentSnapshot.getStartMoment(), -DECAY_FACTOR);
		}
		
		consumedItems.clear();
	}

	for(int i=historySize-temporalDistance; (i>=0) && (i<(historySize-1)); i++){
		currentSnapshot = history[i];
		numItems = (int) currentSnapshot.getNumItems();
		consumedItems = currentSnapshot.getConsumedItems();

		// for each item consumed at that moment
		for(int j=0; j<numItems; j++){
			auxilary = consumedItems[j];

			itr = baseLevelLearning.find(auxilary.item);
			if( itr != baseLevelLearning.end() )
				baseLevelLearning[auxilary.item] += pow(testMoment-currentSnapshot.getStartMoment(), -DECAY_FACTOR);
		}
		
		consumedItems.clear();
	}
	
	// for each consumed item
	numOldItems = (int) baseLevelLearning.size();
	for(itr=baseLevelLearning.begin(); itr!=baseLevelLearning.end(); itr++){
		associativeMemory = 0.0;
		
		for(itr1= contextPerUser[userId].begin(); itr1!= contextPerUser[userId].end(); itr1++){
			associativeStrenght = deriveSimilarity(itr->first, itr1->first, trainingData, itemsSimilarity);
			associativeMemory = associativeStrenght * itr1->second/maxContextScore * 1/numOldItems;
		}
				
		activationScore[currentUser.getUserId()][itr->first] = log(baseLevelLearning[itr->first]) + associativeMemory;
	}
}

float getRetrievalProbabilities(HashOfHashes &contextPerUser, HashOfHashes &activationScore, vector<float> &retrievalProbability){
	int numHits;
	int numRetrieval;
	int totalNumItems;
	
	float F1;
	float maximumF1;
	float precision;
	float recall;
	float threshold = MIN_TAL;
	
	HashOfHashes::iterator itr;
	Hash::iterator itr1;
	Hash::iterator itr2;

	//for each threshold
	maximumF1 = 0;
	
	do{
		F1 = 0;
		numHits = 0;
		numRetrieval = 0;
		totalNumItems = 0;
		
		//for each user 
		for(itr=activationScore.begin(); itr!=activationScore.end(); itr++){
			// for each old item
			for(itr1=activationScore[itr->first].begin(); itr1!=activationScore[itr->first].end(); itr1++ ){
				if( itr1->second >= threshold ){
					numRetrieval++;
				
					itr2 = contextPerUser[itr->first].find(itr1->first);
					if( itr2 != contextPerUser[itr->first].end() )
						numHits++;
				
				}
			}
			
			totalNumItems += (int) activationScore[itr->first].size();
		}
		
		precision = ((float) numHits/ (float) numRetrieval);
		recall = ((float) numHits)/((float) totalNumItems );
		if( (precision  > 0.0) | (recall > 0.0) )
			F1 = 2 * (precision * recall)/(precision + recall);
		
		if( F1 < maximumF1 ){
			break;
		}
		
		maximumF1 = F1;
		threshold+=0.5;
		
	}while(threshold <= MAX_TAL);
	threshold-=0.5;
	
	//for each user 
	for(itr=activationScore.begin(); itr!=activationScore.end(); itr++)
		// for each old item
		for(itr1=activationScore[itr->first].begin(); itr1!=activationScore[itr->first].end(); itr1++ )
			// calcula retrieval Probability
			retrievalProbability.push_back(1.0/(1.0 + exp(-(itr1->second - threshold)/NOISE) ));
		
	return threshold;
}