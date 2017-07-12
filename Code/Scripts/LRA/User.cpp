/************************************************************************
                            User.cpp
************************************************************************/

#include "User.h"

/* construtor */
User::User() {

	this->userId = INVALID_ID;
	this->historySize = 0;
}

User::User(unsigned int userId) {

	this->userId = userId;
	this->historySize = 0;
}


/* destrutor */
User::~User() {
	
	this->userId = -1;
	this->consumptionHistory.clear();
}


/* Get functions */
unsigned int User::getUserId(){
	return this->userId;
}

int User::getHistorySize(){
	return this->historySize;
}

std::vector<snapshot> User::getUserHistory(){
	return this->consumptionHistory;
}

void User::setUserHistory(int trainingUser, std::ifstream &inputFile){
	std::string line, buffer, itemId, rating;
	std::vector<int> itemSet;
	std::vector<float> scoreSet;
	unsigned long int startMoment, endMoment;
	std::vector<std::string> vetor;
	int userId;
	int numTimeUnits;
	int vectorSize;
	
	this->consumptionHistory.clear();
	if(!inputFile.eof()) {
		getline(inputFile, line);

		// split the line based on the ' ' and '\t' delimiter
		vetor.clear();
		string_tokenize(line, vetor, " \t");
		
		userId = atoi(vetor[0].c_str());
		if(userId != trainingUser){
			std::cout << "\n\t***ERROR: Not syncronized files!!!\n\n" << std::endl;
			exit(1);
		}
			
		numTimeUnits = atoi(vetor[1].c_str());
		
		for(int k=0; k<numTimeUnits; k++){
			getline(inputFile, line);
			
			vetor.clear();
			string_tokenize(line, vetor, " \t");		
			vectorSize = (int) vetor.size();
		
			startMoment = atol(vetor[1].c_str());
			endMoment = atol(vetor[2].c_str());
			snapshot currentSnapshot(startMoment, endMoment);
			
			itemSet.clear();
			scoreSet.clear();
			for(int i=3; i<vectorSize; i++){
				std::stringstream ssBuffer(vetor[i]);
				getline(ssBuffer, itemId, ':');
				getline(ssBuffer, rating, ':');
			
				itemSet.push_back( atoi(itemId.c_str()) );
				scoreSet.push_back( atof(rating.c_str()) );
				this->historySize++;
			}
			currentSnapshot.setConsumedItems(itemSet, scoreSet);
			this->consumptionHistory.push_back(currentSnapshot);
		}
	}
}

void string_tokenize(const std::string &str, std::vector<std::string> &tokens, const std::string &delimiters) {
	std::string::size_type lastPos = str.find_first_not_of(delimiters, 0);
	std::string::size_type pos = str.find_first_of(delimiters, lastPos);
	while (std::string::npos != pos || std::string::npos != lastPos) {
		tokens.push_back(str.substr(lastPos, pos - lastPos));
		lastPos = str.find_first_not_of(delimiters, pos);
		pos = str.find_first_of(delimiters, lastPos);
	}
}
