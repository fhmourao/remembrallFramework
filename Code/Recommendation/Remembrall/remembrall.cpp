/************************************************************************
                        remembrall.cpp
************************************************************************/

#include "remembrall.h"

int main(int argc, char **argv){
	std::string buffer;
	std::string line;
	char *outputFileName;
	std::ofstream outputFile;
	char *testFileName;
	std::ifstream testFile;
	char *candidateFileName;
	std::ifstream candidateFile;
	char *trainFileName;
	std::ifstream trainFile;
	
	int contextSize;
	long int testMoment;
	unsigned int userId;
	float recommendationPercentage;
	int recommendationSize;

	vector<myPair> forgottenItems;
	HashOfHashes trainingData;
	User currentUser = User();
	HashOfHashes itemsSimilarity;

	if( !(getArguments(&trainFileName, &testFileName, &candidateFileName, &outputFileName, contextSize, recommendationPercentage, argc, argv)) ){
		return 1;
	}
	
	//load training data
	loadTraingData(trainFileName, trainingData);

	//open test file
	trainFile.open(trainFileName);
	if( !(trainFile.is_open()) ) {
		std::cout << "\n\t***Error opening input file: " << trainFileName << "\n\n";
		exit(-1);
	}

	//open test file
	testFile.open(testFileName);
	if( !(testFile.is_open()) ) {
		std::cout << "\n\t***Error opening input file: " << testFileName << "\n\n";
		exit(-1);
	}

	//open candidate file
	candidateFile.open(candidateFileName);
	if( !(candidateFile.is_open()) ) {
		std::cout << "\n\t***Error opening input file: " << candidateFileName << "\n\n";
		exit(-1);
	}
	
	//open output file
	outputFile.open(outputFileName);
	if( !(outputFile.is_open()) ) {
		std::cout << "\n\t***Error opening output file: " << outputFileName << "\n\n";
		exit(-1);
	}

	//read test file
	while( !testFile.eof() ){
		//retrieve next user
		getline(testFile, line);
		if(line.size() == 0)
			break;
		std::stringstream ss(line);

		//get userId
		ss >> buffer;
		userId = atoi(buffer.c_str());

		//get test moment
		ss >> buffer;
		testMoment = atol(buffer.c_str());

		//verify if is a new user 
		if(userId != currentUser.getUserId()){
			
			//build internal data struct
			currentUser = User(userId);
			
			// load user historic
			currentUser.setUserHistory(userId, trainFile);
			
			//load candidate items
			currentUser.loadCandidateSet(userId, candidateFile);
			
			recommendationSize = int(recommendationPercentage * (float) currentUser.getHistorySize() + 0.5);
			if(recommendationSize < 1)
				recommendationSize = 1;

		}
		
		// recommend forgotten items
		recommendForgottenItems(testMoment, forgottenItems, contextSize, trainingData, currentUser, itemsSimilarity, ((int) recommendationPercentage));
				
		// print recommendations in output file
		printRecommendations(currentUser, testMoment, forgottenItems, recommendationSize, outputFile);

		forgottenItems.clear();
	}
	
	testFile.close();
	trainFile.close();
	outputFile.close();
	
	return 0;
}

