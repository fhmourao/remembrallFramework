#include "userKNN.h"

pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

int main(int argc, char **argv) {
	char *trainFileName;
	char *outFileName;
	int K;
	int numThreads;
	float globalAverage;
	
	std::set<int> testUsers;
	Hash userBias;
	Hash itemBias;
	HashOfHashes itemRatings;
	HashOfHashes userRatings;

	// checa a validade dos parâmetros de entrada passados pela linha de comando
	if(!getArgs(argc, argv, &trainFileName, &outFileName, &numThreads, &K)) {
		return 1;
	}

	std::cout << "loading training data...\n" << flush;
	loadTrainData(trainFileName, itemRatings, userRatings, globalAverage, testUsers);
	
	defineIndividualBias(userRatings, userBias, itemBias, globalAverage);
		
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
		params[i].globalAverage = globalAverage;
		params[i].itemBias = &itemBias;
		params[i].userBias = &userBias;
		params[i].testUsers = &testUsers;
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
	std::set<int>::iterator itr;
	
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
	for ( itr = (*param->testUsers).begin(); itr != (*param->testUsers).end(); itr++) {
		modulus = (currentPosition - (param->threadId + 1)) % param->numThreads;
		if( modulus == 0 )
			extendProfile(*itr, (*param->userRatings), (*param->itemRatings), (*param->userBias), (*param->itemBias), param->K, param->globalAverage, outputFile);

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

void calculateItemBiases(HashOfHashes &userRatings, Hash &itemBias, Hash &userBias, float globalAverage){
	int itemId;
	int userId;
	float rating;
	
	Hash numRatingsPerItem;
	HashOfHashes::iterator itr1;
	Hash::iterator itr2;
	Hash::iterator itr3;
	
	for(itr1 = userRatings.begin(); itr1 != userRatings.end(); itr1++){
		userId = itr1->first;
		
		userBias[userId] = 0.0;
		for(itr2 = userRatings[userId].begin(); itr2 != userRatings[userId].end(); itr2++ ){
			itemId = itr2->first;
			rating = itr2->second;
			itemBias[itemId] += rating - globalAverage - userBias[userId];
			
			itr3 = numRatingsPerItem.find(itemId);
			if(itr3 == numRatingsPerItem.end() )
				numRatingsPerItem[itemId] = 0;
			numRatingsPerItem[itemId] += 1;
		}
	}
	
	for(itr2=itemBias.begin(); itr2!= itemBias.end(); itr2++)
		itemBias[itr2->first] = itr2->second / ((float) (ITEM_REGULARIZATION + numRatingsPerItem[itr2->first]));

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

void defineIndividualBias(HashOfHashes &userRatings, Hash &userBias, Hash &itemBias, float globalAverage){
	
	for(int i=0; i< NUM_ITERACTIONS; i++){
		calculateUserBiases(userRatings, userBias, itemBias, globalAverage);
		calculateItemBiases(userRatings, userBias, itemBias, globalAverage);
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

void extendProfile(int userId, HashOfHashes &userRatings, HashOfHashes &itemRatings, Hash &userBias, Hash &itemBias, int K, float globalAverage, std::ofstream &outputFile) {
	myPair auxilary;
	
	float baseline;
	int counter1;
	float finalScore;
	int itemId;
	int neighborId;
	float rating;
	float similarity;
	
	multiset<myPair,eq> candidateSet;
	
	Hash::iterator itr;
	multiset<myPair,eq>::iterator itr1;
	Hash::iterator itr2;
	
	for(itr= userRatings[userId].begin(); itr!= userRatings[userId].end(); itr++)
		outputFile << userId << "\t" << itr->first << "\t" << itr->second << "\t" << itemRatings[userId][itr->first] << std::endl;
	
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

			baseline = getValidScore(globalAverage + userBias[neighborId] + itemBias[itemId]);
			finalScore = similarity * (rating - baseline);
			rating = getValidScore(finalScore + globalAverage + userBias[userId] + itemBias[itemId]);
			
			outputFile << userId << "\t" << itemId << "\t" << rating << "\t" << itemRatings[neighborId][itemId] << std::endl;
		}
		
		counter1++;
	}
	
	candidateSet.clear();
	
}


/****************************************************************************************
                             Load Functions
*****************************************************************************************/

void loadTrainData(char *trainFile, HashOfHashes &itemRatings, HashOfHashes &userRatings, float &globalAverage, std::set<int> &testUsers) {
	std::ifstream file;
	std::string line;
	int itemId;
	float rating;
	std::vector<std::string> vector;
	int userId;
	int numRatings = 0;
	int timestamp;

	file.open(trainFile);

	if(!file.is_open()) {
		std::cout << "\nError opening file!" << endl;
		std::exit(-1);
	}

	globalAverage = 0.0;
	while(!file.eof()) {
		getline(file, line);

		if( line.length() > 0 ){
			// separa a linha através do delimitador " " e salva o resultado em um vetor
			vector.clear();
			string_tokenize(line, vector, " \t");
			userId = atoi(vector[0].c_str());
			itemId = atoi(vector[1].c_str());
			rating = atof(vector[2].c_str());
			timestamp = atol(vector[3].c_str());
			
			if(rating > MAX_SCORE)
				MAX_SCORE = rating;
			
			if(MIN_SCORE > rating)
				MIN_SCORE = rating;
			
			itemRatings[userId][itemId] = timestamp;
			userRatings[userId][itemId] = rating;
			
			globalAverage += rating;
			numRatings++;
			
			testUsers.insert(userId);
		}
	}
	
	globalAverage = globalAverage/((float) numRatings);

	file.close();
}

/****************************************************************************************
                             Get Functions
*****************************************************************************************/

int getArgs(int argc, char **argv, char **trainFileName, char **outFileName, int *numThreads, int *K) {
	int opt;
	*trainFileName = NULL;
	*outFileName = NULL;
	*numThreads = 1;
	*K = 80;

	while( (opt = getopt(argc, argv, "ht:o:k:p:")) != -1 ) {
		switch(opt) {
			case 'h':
				printUsage();
				return 0;
				break;
			case 't':
				*trainFileName = optarg;
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
			default: {
				printUsage();
				return 0;
			}
		}
	}

	if( *trainFileName == NULL ||  *outFileName == NULL || *numThreads <= 0 || *numThreads > 100 || *K < 0 ) {
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
	args += "\n    -p <numThreads> ";
	args += "\n    [-k] <number of neighbors -- default: 80> ";
	args += "\n    [-h]\n\n";
	std::cout << "\n  Argumentos corretos:\n" << args;
}
