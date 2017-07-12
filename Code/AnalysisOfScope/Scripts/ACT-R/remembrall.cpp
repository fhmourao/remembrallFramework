/************************************************************************
                        remembrall.cpp
************************************************************************/

#include "remembrall.h"

int main(int argc, char **argv){
	char *outputFileName;
	std::ofstream outputFile;
	char *outputFileName1;
	std::ofstream outputFile1;
	char *trainFileName;
	std::ifstream trainFile;
	int temporalDistance;
	float tal;

	HashOfHashes activationScore;
	HashOfHashes contextPerUser;
	HashOfHashes trainingData;
	User currentUser = User();
	HashOfHashes itemsSimilarity;
	vector<int> domainUsers;
	vector<int>::iterator itr;
	vector<float> retrievalProbability;

	if( !(getArguments(&trainFileName, &outputFileName, &outputFileName1, temporalDistance, argc, argv)) ){
		return 1;
	}
	
	//load training data
	loadTraingData(trainFileName, domainUsers, trainingData);

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

	//open output file
	outputFile1.open(outputFileName1);
	if( !(outputFile1.is_open()) ) {
		std::cout << "\n\t***Error opening output file: " << outputFileName1 << "\n\n";
		exit(-1);
	}
	
	//for each user i the training set
	for(itr=domainUsers.begin(); itr!=domainUsers.end(); itr++){
		
		//build internal data struct
		currentUser = User(*itr);
		
		// load user historic
		currentUser.setUserHistory(*itr, trainFile);
		
		// generate Activation score for each old item 
		generateActivationScores(temporalDistance, trainingData, currentUser, itemsSimilarity, contextPerUser, activationScore);
	}
	
	//generate the median retrieval probability 
	tal = getRetrievalProbabilities(contextPerUser, activationScore, retrievalProbability);
	outputFile1 << tal;
	
	// print the median value in output file
	printMedianProbability(retrievalProbability, outputFile);
	
	trainFile.close();
	outputFile.close();
	outputFile1.close();
	
	return 0;
}

