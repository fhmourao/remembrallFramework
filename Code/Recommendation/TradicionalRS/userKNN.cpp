#include "userKNN.h"

pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

int main(int argc, char **argv) {
	char *trainFileName;
	char *testFileName;
	char *outFileName;
	int K;
	int numThreads;
	float globalAverage;
	float recommendationPercentage;
	
	Hash userBias;
	Hash itemBias;
	HashOfHashes itemRatings;
	HashOfHashes testingItems;
	HashOfHashes userRatings;

	// checa a validade dos parâmetros de entrada passados pela linha de comando
	if(!getArgs(argc, argv, &trainFileName, &testFileName, &outFileName, &numThreads, &K, &recommendationPercentage)) {
		return 1;
	}

	std::cout << "loading training data...\n" << flush;
	loadTrainData(trainFileName, itemRatings, userRatings, globalAverage);
	
	std::cout << "loading test data...\n" << flush;
	loadTestData(testFileName, testingItems);
	
	defineIndividualBias(userRatings, userBias, itemRatings, itemBias, globalAverage);
		
	std::cout << "Starting recommendation process...\n" << flush;
	/* start threads */
	pthread_t *threads;
	pthread_param *params;

	threads = (pthread_t *) malloc(sizeof(pthread_t)*numThreads);
	params = (pthread_param *) malloc(sizeof(pthread_param)*numThreads);

	/* inicializa as threads */
	for (int i = 0; i < numThreads; i++) {
		params[i].threadId = i;
		params[i].numThreads = numThreads;
		params[i].K = K;
		params[i].recommendationPercentage = recommendationPercentage;
		params[i].globalAverage = globalAverage;
		params[i].itemBias = &itemBias;
		params[i].userBias = &userBias;
		params[i].testingItems = &testingItems;
		params[i].itemRatings = &itemRatings;
		params[i].userRatings = &userRatings;
		params[i].outFileName = outFileName;

		pthread_create(&threads[i], NULL, &performRecommendation, params+i);
	}

	/* sincroniza finalizacao// das threads */
	for (int i = 0; i < numThreads; i++) {
		pthread_join(threads[i], NULL);
	}

	free(threads);

	return 0;
}

/****************************************************************************************
                             Main Thread Function
*****************************************************************************************/

void *performRecommendation(void *arg){
	int currentPosition;
	int modulus;
	HashOfHashes::iterator itr;
	
	// get thread parameters
	pthread_param *param = (pthread_param *) arg;
	
	//open output file name
	std::ofstream outputFile;
        std::stringstream outputFileName;
        outputFileName << param->outFileName << "." << param->threadId;

        outputFile.open(outputFileName.str().c_str());
        if(!outputFile.is_open()) {
                cout << "Erro ao abrir o arquivo de saída da thread " << param->threadId << "!" << endl;
                exit(-1);
        }

        // for each test user
	currentPosition = 0;
	for ( itr = (*param->testingItems).begin(); itr != (*param->testingItems).end(); itr++) {
		modulus = (currentPosition - (param->threadId + 1)) % param->numThreads;
		if( modulus == 0 ){
			recommendItems(itr->first, itr->second, (*param->userRatings), (*param->itemRatings),  (*param->userBias), (*param->itemBias), param->K, param->globalAverage, param->recommendationPercentage, outputFile);
		}
		currentPosition++;
		
	}
	
	// close thread output file
        outputFile.close();
	
	return NULL;
}

/****************************************************************************************
                             Recommendation Functions
*****************************************************************************************/
float calculateCosineSimilarity(int firstUser, int secondUser, HashOfHashes &userRatings){
	float cosine = 0.0;
	float dotProduct = 0.0;
	float norm1 = 0.0;
	float norm2 = 0.0;
	
	HashOfHashes::iterator itr1;
	HashOfHashes::iterator itr2;

	Hash::iterator itr3;
	Hash::iterator itr4;
	
	//verify whether both user exist in the training set
	itr1 = userRatings.find(firstUser);
	itr2 = userRatings.find(secondUser);
	
	if( itr1 == userRatings.end() || itr2 == userRatings.end() )
		return cosine;
	
	for( itr3=userRatings[firstUser].begin(); itr3!=userRatings[firstUser].end(); itr3++ ){
		itr4 = userRatings[secondUser].find(itr3->first);
		if( itr4 != userRatings[secondUser].end() ){
			dotProduct += itr3->second * itr4->second;
		}
		
		norm1 += (itr3->second*itr3->second);
	}
	norm1 = sqrt(norm1);
	
	for( itr4=userRatings[secondUser].begin(); itr4!=userRatings[secondUser].end(); itr4++ )
		norm2 += itr4->second*itr4->second;
	norm2 = sqrt(norm2);
	
	if( (norm1 > 0.0) && (norm2 > 0.0) )
		cosine = dotProduct/(norm1*norm2);
	
	return cosine;
}

void calculateItemBiases(HashOfHashes &itemRatings, Hash &itemBias, Hash &userBias, float globalAverage){
	int itemId;
	int userId;
	float rating;
	int numRatings;
	
	HashOfHashes::iterator itr1;
	Hash::iterator itr2;
	
	for(itr1 = itemRatings.begin(); itr1 != itemRatings.end(); itr1++){
		itemId = itr1->first;
		
		numRatings = 0;
		itemBias[itemId] = 0.0;
		for(itr2 = itemRatings[itemId].begin(); itr2 != itemRatings[itemId].end(); itr2++ ){
			userId = itr2->first;
			rating = itr2->second;
			itemBias[itemId] += rating - globalAverage - userBias[userId];
			numRatings++;
		}
		
		itemBias[itemId] = itemBias[itemId] / ((float) (ITEM_REGULARIZATION + numRatings));
	}
}

void calculateUserBiases(HashOfHashes &userRatings, Hash &userBias, Hash &itemBias, float globalAverage){
	int itemId;
	int userId;
	float rating;
	int numRatings;
	
	HashOfHashes::iterator itr1;
	Hash::iterator itr2;
	
	for(itr1 = userRatings.begin(); itr1 != userRatings.end(); itr1++){
		userId = itr1->first;
		
		numRatings = 0;
		userBias[userId] = 0.0;
		for(itr2 = userRatings[userId].begin(); itr2 != userRatings[userId].end(); itr2++ ){
			itemId = itr2->first;
			rating = itr2->second;
			userBias[userId] += rating - globalAverage - itemBias[itemId];
			numRatings++;
		}
		
		userBias[userId] = userBias[userId] / ((float) (USER_REGULARIZATION + numRatings));
	}
}

void defineIndividualBias(HashOfHashes &userRatings, Hash &userBias, HashOfHashes &itemRatings, Hash &itemBias, float globalAverage){
	
	for(int i=0; i< NUM_ITERACTIONS; i++){
		calculateUserBiases(userRatings, userBias, itemBias, globalAverage);
		calculateItemBiases(itemRatings, itemBias, userBias, globalAverage);
	}
	
}

void getKNNUsers(int userId, HashOfHashes &userRatings, multiset<myPair,eq> &candidateSet){
	myPair auxilary;
	
	float similarity;
	Hash userSimilarities;
	
	HashOfHashes::iterator itr1;
	Hash::iterator itr2;
	
	// for each distinct user
	for(itr1= userRatings.begin(); itr1!= userRatings.end(); itr1++){
		if( itr1->first != userId){
			similarity = calculateCosineSimilarity(userId, itr1->first, userRatings);
			
			userSimilarities[itr1->first] = similarity;
		}
	}
	
	// retrieve neighbors
	for(itr2 = userSimilarities.begin(); itr2 != userSimilarities.end(); itr2++){
		auxilary.item = itr2->first;
		auxilary.score = itr2->second;
				
		candidateSet.insert(auxilary);
	}
	userSimilarities.clear();
	
}

inline float getValidScore(float score){
	if( score < MIN_SCORE )
		score = MIN_SCORE;
	if( score > MAX_SCORE )
		score = MAX_SCORE;
	
	return score;
}

void recommendItems(int userId, Hash &testingItems, HashOfHashes &userRatings, HashOfHashes &itemRatings, Hash &userBias, Hash &itemBias, int K, float globalAverage, float recommendationPercentage, std::ofstream &outputFile) {
	myPair auxilary;
	
	float baseline;
	int counter1;
	int counter2;
	float finalScore;
	int itemId;
	int neighborId;
	float rating;
	float similarity;
	int recommendationSize;
	
	multiset<myPair,eq> candidateSet;
	Hash itemScore;
	Hash itemWeight;
	multiset<myPair,eq> resultSet;
	
	Hash::iterator itr;
	multiset<myPair,eq>::iterator itr1;
	Hash::iterator itr2;
	
	recommendationSize = int(recommendationPercentage * (float) userRatings[userId].size() + 0.5);
	
	// retrieve neighbor users
	getKNNUsers(userId, userRatings, candidateSet);

	//for each neighbor
	counter1 = 0;
	for(itr1= candidateSet.begin(); itr1 != candidateSet.end(); itr1++){
		auxilary = *itr1;
		neighborId = auxilary.item;
		similarity = auxilary.score;
		
		// take into account only the K most similar neighbors positively correlated to userId
		if( !(similarity > 0.0) || (counter1 == K) )
			break;

		//for each item consumed by neighborId
		for(itr= userRatings[neighborId].begin(); itr!= userRatings[neighborId].end(); itr++){
			itemId = itr->first;
			rating = itr->second;
			
			// verify whether item is a testing item
			itr2 = testingItems.find(itemId);
			if( itr2 == testingItems.end() )
				continue;
						
			baseline = getValidScore(globalAverage + userBias[neighborId] + itemBias[itemId]);
			itr2 = itemScore.find(itemId);
			if( itr2 != itemScore.end() ){
				itemScore[itemId] += similarity * (rating - baseline);
				itemWeight[itemId] += similarity;
			}
			else{
				itemScore[itemId] = similarity * (rating - baseline);
				itemWeight[itemId] = similarity;
			}

		}
		
		counter1++;
	}
	candidateSet.clear();

	// copy item from hash to ordered multiset structure
	for(itr2 = itemScore.begin(); itr2 != itemScore.end(); itr2++){
		finalScore = itr2->second/itemWeight[itr2->first];
		auxilary.item = itr2->first;
		auxilary.score = getValidScore(finalScore + globalAverage + userBias[userId] + itemBias[auxilary.item]);

		resultSet.insert(auxilary);
	}
	itemScore.clear();
	itemWeight.clear();
		
	// print the user recommendations
	itr = testingItems.begin();
	counter2 = 0;
	outputFile << userId << "\t" << itr->second;
	for(itr1= resultSet.begin(); (itr1 != resultSet.end() && counter2 < recommendationSize) ; itr1++){
		auxilary = *itr1;
		outputFile << "\t" << auxilary.item << ":" << auxilary.score;
		counter2++;
	}
	outputFile << std::endl;	
	
	resultSet.clear();
}


/****************************************************************************************
                             Load Functions
*****************************************************************************************/

void loadTestData(char *testFile, HashOfHashes &testingItems) {
	std::ifstream file;
	std::string line, itemId, rating;
	std::vector<std::string> vetor;
	int userId;
	int vectorSize;
	int testMoment;

	file.open(testFile);

	if(!file.is_open()) {
		std::cout << "\nError opening file!" << endl;
		std::exit(-1);
	}

	while(!file.eof()) {
		getline(file, line);

		// separa a linha através do delimitador " " e salva o resultado em um vetor
		vetor.clear();
		string_tokenize(line, vetor, " \t");
		vectorSize = (int) vetor.size();
		
		userId = atoi(vetor[0].c_str());
		testMoment = atoi(vetor[1].c_str());
		for(int i=2; i<vectorSize; i++){
			std::stringstream ssBuffer(vetor[i]);
			getline(ssBuffer, itemId, ':');
			getline(ssBuffer, rating, ':');
		
			testingItems[userId][atoi(itemId.c_str())] = testMoment;
		}	
		
		if(vectorSize == 2)
			testingItems[userId][-1] = testMoment;
	}

	file.close();
}

void loadTrainData(char *trainFile, HashOfHashes &itemRatings, HashOfHashes &userRatings, float &globalAverage) {
	std::ifstream inputFile;
	std::string line, buffer, itemId, rating;
	std::vector<int> itemSet;
	std::vector<float> scoreSet;
	std::vector<std::string> vetor;
	int numRatings = 0;
	int userId;
	int numTimeUnits;
	int vectorSize;
	
	inputFile.open(trainFile);
	if( !(inputFile.is_open()) ) {
		std::cout << "\n\t***Error opening input file: " << trainFile << "\n\n";
		exit(-1);
	}

	globalAverage = 0.0;
	while(!inputFile.eof()) {
		getline(inputFile, line);

		// split the line based on the ' ' and '\t' delimiter
		vetor.clear();
		string_tokenize(line, vetor, " \t");
		
		userId = atoi(vetor[0].c_str());
		numTimeUnits = atoi(vetor[1].c_str());

		for(int k=0; k<numTimeUnits; k++){
			getline(inputFile, line);
			
			vetor.clear();
			string_tokenize(line, vetor, " \t");
			vectorSize = (int) vetor.size();
		
			itemSet.clear();
			scoreSet.clear();
			for(int i=3; i<vectorSize; i++){
				std::stringstream ssBuffer(vetor[i]);
				getline(ssBuffer, itemId, ':');
				getline(ssBuffer, rating, ':');

				itemRatings[atoi(itemId.c_str())][userId] = atof(rating.c_str());
				userRatings[userId][atoi(itemId.c_str())] = atof(rating.c_str());

				globalAverage += atof(rating.c_str());
				numRatings++;
			}
		}
	}

	globalAverage = globalAverage/((float) numRatings);
		
	inputFile.close();
}

/****************************************************************************************
                             Get Functions
*****************************************************************************************/

int getArgs(int argc, char **argv, char **trainFileName, char **testFileName, char **outFileName, int *numThreads, int *K, float *recommendationPercentage) {
	int opt;
	*trainFileName = NULL;
	*outFileName = NULL;
	*testFileName = NULL;
	*numThreads = 1;
	*K = 80;
	*recommendationPercentage = -1.0;

	while( (opt = getopt(argc, argv, "ht:e:o:k:p:r:")) != -1 ) {
		switch(opt) {
			case 'h':
				printUsage();
				return 0;
				break;
			case 't':
				*trainFileName = optarg;
				break;
			case 'e':
				*testFileName = optarg;
				break;
			case 'o':
				*outFileName = optarg;
				break;
			case 'p':
				*numThreads = atoi(optarg);
				break;
			case 'k':
				*K = atoi(optarg);
				break;
			case 'r':
				*recommendationPercentage = atof(optarg);
				break;
			default: {
				printUsage();
				return 0;
			}
		}
	}

	if( *trainFileName == NULL || *testFileName == NULL || *outFileName == NULL || *numThreads <= 0 
		|| *numThreads > 100 || *K < 0 || *recommendationPercentage < 0.0 || *recommendationPercentage > 1.0 ) {
		printUsage();
		return 0;
	}

	return 1;
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

/****************************************************************************************
                             Usage Function
*****************************************************************************************/

void printUsage() {
	std::string args = "";
	args += "\n    -t <trainFilename> ";
	args += "\n    -o <outFile> ";
	args += "\n    -e <testFile> ";
	args += "\n    -p <numThreads> ";
	args += "\n    -r <recommendation size> ";
	args += "\n    [-k] <number of neighbors -- default: 80> ";
	args += "\n    [-h]\n\n";
	std::cout << "\n  Argumentos corretos:\n" << args;
}
