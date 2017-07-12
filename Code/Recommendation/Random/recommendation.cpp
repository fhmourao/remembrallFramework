/************************************************************************
                            recommendation.cpp
************************************************************************/

#include "recommendation.h"

void recommendForgottenItems(vector<myPair> &forgottenItems, User &currentUser){
	int historySize;
	int numItems;
	
	vector<myPair> consumedItems;
	Hash activationScore;
	vector<snapshot> history;
	
	Hash::iterator itr;
	
	myPair auxilary;
	snapshot currentSnapshot = snapshot();
	
	history = currentUser.getUserHistory();
	historySize = (int) history.size();
	
	/* initialize random seed: */
	srand (time(NULL));

	// for each past moment
	for(int i=0; i<historySize; i++){
		currentSnapshot = history[i];
		numItems = (int) currentSnapshot.getNumItems();
		consumedItems = currentSnapshot.getConsumedItems();

		// for each item consumed at that moment
		for(int j=0; j<numItems; j++){
			auxilary = consumedItems[j];

			itr = activationScore.find(auxilary.item);
			if( itr == activationScore.end() ){
				activationScore[auxilary.item] = ((float) (rand() % 1000))/((float) 1000.0);
			}
		}
		
		consumedItems.clear();
	}

	reorderForgottenItems(-1.0, activationScore, forgottenItems);
}

inline void reorderForgottenItems(float cutOffPoint, Hash &activationScore, vector<myPair> &forgottenItems){

	myPair auxilary;	
	Hash::iterator itr;
	
	for( itr=activationScore.begin(); itr!=activationScore.end(); itr++ ){
		if(itr->second > cutOffPoint){
			auxilary.item = itr->first;
			auxilary.score = itr->second;
			
			forgottenItems.push_back(auxilary);
		}
	}
}
