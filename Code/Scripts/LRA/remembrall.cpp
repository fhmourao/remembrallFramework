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
	char *trainFileName;
	std::ifstream trainFile;
	float percentageOfHistory;
	
	int contextSize;
	int recommendationSize;
	long int testMoment;
	unsigned int userId;

	vector<myPair> forgottenItems;
	HashOfHashes trainingData;
	User currentUser = User();

	if( !(getArguments(&trainFileName, &testFileName, &outputFileName, percentageOfHistory, contextSize, argc, argv)) ){
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

	//open output file
	outputFile.open(outputFileName);
	if( !(outputFile.is_open()) ) {
		std::cout << "\n\t***Error opening input file: " << outputFileName << "\n\n";
		exit(-1);
	}

	//read test file
	recommendationSize = 1;
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
			
			recommendationSize = int(percentageOfHistory * (float) currentUser.getHistorySize() + 0.5);
		}
		
		// recommend forgotten items
		recommendForgottenItems(testMoment, forgottenItems, contextSize, trainingData, currentUser);
				
		// print recommendations in output file
		printRecommendations(currentUser, testMoment, forgottenItems, recommendationSize, outputFile);
		
		forgottenItems.clear();
	}
	
	testFile.close();
	trainFile.close();
	outputFile.close();
	
	return 0;
}

