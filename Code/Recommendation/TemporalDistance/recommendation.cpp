/************************************************************************
                            recommendation.cpp
************************************************************************/

#include "recommendation.h"

void recommendForgottenItems(long int testMoment, vector<myPair> &forgottenItems, int contextSize, HashOfHashes &trainingData, User &currentUser, int getAllItems){
	int historySize;
	int numItems;
	
	myPair auxilary;
	vector<myPair> consumedItems;
	Hash baseLevelLearning;
	vector<snapshot> history;
	set<int> context;
	set<int> candidateItems;
	
	Hash::iterator itr;
	set<int>::iterator itr1;
	
	snapshot currentSnapshot = snapshot();
	
	history = currentUser.getUserHistory();
	candidateItems = currentUser.getCandidateItems();
	historySize = (int) history.size();

	if(testMoment != currentUser.getTestMoment() ){
		std::cout << "\n\t***ERROR: test moment does not match candidate list !!!\n\n" << std::endl;
		exit(1);
	}
		
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

			itr1 = candidateItems.find(auxilary.item);
			if( itr1 != candidateItems.end() ){
				itr = baseLevelLearning.find(auxilary.item);
				if( itr != baseLevelLearning.end() )
					baseLevelLearning[auxilary.item] += log(testMoment-currentSnapshot.getStartMoment());
				else
					baseLevelLearning[auxilary.item] += log(testMoment-currentSnapshot.getStartMoment());
			}
		}
		
		consumedItems.clear();
	}

	reorderForgottenItems(baseLevelLearning, context, forgottenItems, getAllItems);
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
