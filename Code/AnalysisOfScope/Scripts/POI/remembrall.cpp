/************************************************************************
                        remembrall.cpp
************************************************************************/

#include "remembrall.h"

int main(int argc, char **argv){
	char *outputFileName;
	std::ofstream outputFile;
	char *recommendationFileName;
	char *trainFileName;
	std::ifstream trainFile;
	int temporalDistance;
	float tal;

	HashOfHashes trainingData;
	User currentUser = User();
	HashOfHashes itemsSimilarity;
	HashOfHashes recommendationsPerUser;
	vector<int> domainUsers;
	vector<int>::iterator itr;
	vector<float> retrievalProbability;

	if( !(getArguments(&trainFileName, &recommendationFileName, &outputFileName, temporalDistance, tal, argc, argv)) ){
		return 1;
	}
	
	//load training data
	loadTraingData(trainFileName, domainUsers, trainingData);

	//load recommendations
	loadRecommendations(recommendationFileName, recommendationsPerUser);
	
	//open test file
	trainFile.open(trainFileName);
	if( !(trainFile.is_open()) ) {
		std::cout << "\n\t***Error opening input file: " << trainFileName << "\n\n";
		exit(-1);
	}

	//open output file
	outputFile.open(outputFileName);
	if( !(outputFile.is_open()) ) {
		std::cout << "\n\t***Error opening output file: " << outputFileName << "\n\n";
		exit(-1);
	}
	
	//for each user i the training set
	for(itr=domainUsers.begin(); itr!=domainUsers.end(); itr++){
		
		//build internal data struct
		currentUser = User(*itr);
		
		// load user historic
		currentUser.setUserHistory(*itr, trainFile);
		
		// generate Activation score for each old item 
		generateActivationScores(temporalDistance, tal, trainingData, currentUser, itemsSimilarity, recommendationsPerUser[*itr], retrievalProbability);
	}
	
	// print the median value in output file
	printMedianProbability(retrievalProbability, outputFile);
	
	trainFile.close();
	outputFile.close();
	
	return 0;
}

