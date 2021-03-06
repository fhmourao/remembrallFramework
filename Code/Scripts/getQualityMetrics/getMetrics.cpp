#include "getMetrics.h"

float MAX_RATING = 0.0;
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

int main(int argc, char **argv) {
	char *trainFileName;
	char *predFileName;
	char *testFileName;
	char *outFile;
	int numThreads;

	std::ifstream file;

	HashOfHashes hashPred;
	HashOfHashes trainData;
	HashOfHashes testData;
	HashOfHashes itemRatings;
	HashOfHashes hashSimilarity;

	// checa a validade dos parâmetros de entrada passados pela linha de comando
	if(!getArgs(argc, argv, &trainFileName, &predFileName, &testFileName, &outFile, &numThreads)) {
		return 1;
	}

	std::cout << "loading predictions...\n" << flush;
	loadPred(predFileName, hashPred);
	
	std::cout << "loading test data...\n" << flush;
	loadTestData(testFileName, testData);
	
	std::cout << "loading training data...\n" << flush;
	loadTrainData(trainFileName, itemRatings, trainData);

	std::cout << "Starting calculus...\n" << flush;
	/* Inicio threads */
	pthread_t *threads;
	pthread_param *params;

	threads = (pthread_t *) malloc(sizeof(pthread_t)*numThreads);
	params = (pthread_param *) malloc(sizeof(pthread_param)*numThreads);

	/* inicializa as threads */
	for (int i = 0; i < numThreads; i++) {
		params[i].threadId = i;
		params[i].numThreads = numThreads;
		params[i].hashPred = &hashPred;
		params[i].testData = &testData;
		params[i].trainData = &trainData;
		params[i].itemRatings = &itemRatings;
		params[i].hashSimilarity = &hashSimilarity;
		params[i].outFile = outFile;

		pthread_create(&threads[i], NULL, &getMetrics, params+i);
	}

	/* sincroniza finalizacao// das threads */
	for (int i = 0; i < numThreads; i++) {
		pthread_join(threads[i], NULL);
	}

	free(threads);

	return 0;
}

void *getMetrics(void *arg) {
	unsigned int numUsers;

	double D_EPC_rank, D_EPC;
	double EILD, ILD;

	pthread_param *param = (pthread_param *) arg;

	HashOfHashes::iterator it_hoh;
	HashOfHashes::iterator auxilary_itr;

	unsigned int counter = param->threadId;
	it_hoh = (*param->hashPred).begin();

	numUsers = (unsigned int) (*param->hashPred).size();
	if ( (counter + 1) > numUsers) {
		return NULL;
	}

	/* abre o arquivo de saída da thread*/
	std::ofstream file;
	std::stringstream File;
	File << param->outFile << "." << param->threadId;

	file.open(File.str().c_str());
	if(!file.is_open()) {
		cout << "Erro ao abrir o arquivo de saída da thread " << param->threadId << "!" << endl;
		exit(-1);
	}

	for (advance(it_hoh, param->threadId); it_hoh != (*param->hashPred).end(); advance(it_hoh, param->numThreads)) {
		
		noveltyDiscoveryEPC(it_hoh->first, numUsers, (*param->testData), (*param->hashPred), (*param->itemRatings), D_EPC_rank, D_EPC);
		file << it_hoh->first << " " << D_EPC_rank << " " << D_EPC << " ";

		diversityEILD(it_hoh->first, (*param->testData), (*param->hashPred), (*param->hashSimilarity), (*param->itemRatings), EILD, ILD);
		file << EILD << " " << ILD << endl;

		file.flush();

		counter += param->numThreads;

		if ((counter + 1) > (*param->hashPred).size()) {
			break;
		}
	}

	file.close();

	return NULL;
}

inline double probabilityOfRelevance(double rating) {
     double difference;
     double indifference = 0.0;
     int g;
     double gMax;
     double probability;

     difference = rating - indifference;

     if(difference > 0)
	  g = difference;
     else
	  g = 0.0;

     gMax = ((double) MAX_RATING) - indifference;

     probability = ((double) pow(2, g)/((double) pow(2, gMax)));

     return probability;
}

double normalizedConstant(int listSize) {
     double constant = 0.0;
     double sum = 0.0;

     for(int rank=1; rank<=listSize; rank++) {
	    sum += pow(0.85, (rank - 1));
     }

     constant = 1.0/sum;

     return constant;
}

inline double conditionalRankDiscount(int rank1, int rank2) {
     double discount;
     int difference;

     difference = rank1 - rank2;

     if(difference > 1){
	  discount = pow(0.85, (difference - 1));
     }
     else{
	  discount = 1;
     }

     return discount;
}

double conditionalNormalization(int selectedRank, int user, HashOfHashes &testData, HashOfHashes &hashPred, double C) {
     double C_k;
     double denominator = 0.0;
     int item;
     double rating;

     Hash::iterator itr;

     int rank=1;
     for(itr = hashPred[user].begin(); itr != hashPred[user].end(); itr++) {
	  if(rank != selectedRank){
	       item = itr->first;
          	if(testData[user].count(item) > 0) {
		    rating = testData[user][item];
	  	} else {
		    rating = 0;
	  	} 

	       denominator += conditionalRankDiscount(rank,selectedRank)*probabilityOfRelevance(rating);
          }

	  rank++;
     }

     C_k = C/denominator;

     return C_k;
}


float calculatePearsonSimilarity(int firstItem, int secondItem, HashOfHashes &itemRatings){
	float meanX;
	float meanY;
	float pearson = 0.0;
	float squaredDifferencesX;
	float squaredDifferencesY;
	float sumOfProduct = 0.0;
	
	
	HashOfHashes::iterator itr1;
	HashOfHashes::iterator itr2;

	Hash::iterator itr3;
	Hash::iterator itr4;
	
	//verify whether both item exist in the training set
	itr1 = itemRatings.find(firstItem);
	itr2 = itemRatings.find(secondItem);
	
	if( itr1 == itemRatings.end() || itr2 == itemRatings.end() )
		return pearson;
	
	meanX = 0.0;
	for( itr3=itemRatings[firstItem].begin(); itr3!=itemRatings[firstItem].end(); itr3++ )
		meanX += itr3->second;
	
	meanY = 0.0;
	for( itr4=itemRatings[secondItem].begin(); itr4!=itemRatings[secondItem].end(); itr4++ )
		meanY += itr4->second;
	
	sumOfProduct = 0.0;
	squaredDifferencesX = 0.0;
	for( itr3=itemRatings[firstItem].begin(); itr3!=itemRatings[firstItem].end(); itr3++ ){
		squaredDifferencesX += (itr3->second - meanX)*(itr3->second - meanX);
		
		itr4 = itemRatings[secondItem].find(itr3->first);
		if( itr4 != itemRatings[secondItem].end() ){
			sumOfProduct += (itr3->second - meanX)*(itr4->second - meanY);
		}		
	}
	
	
	squaredDifferencesY = 0.0;
	for( itr4=itemRatings[secondItem].begin(); itr4!=itemRatings[secondItem].end(); itr4++ ){
		squaredDifferencesY += (itr4->second - meanY)*(itr4->second - meanY);
	}
	
	if( (squaredDifferencesX > 0.0) && (squaredDifferencesY > 0.0) ){
		pearson = sumOfProduct/(sqrt(squaredDifferencesX)*sqrt(squaredDifferencesY));
	}
	
	return pearson;
}

float retrieveItemsSimilarity(int item1, int item2, HashOfHashes &hashSimilarity, HashOfHashes &itemRatings){
	int firstItem = item1;
	int numOccItem1 = 0;
	int numOccItem2 = 0;
	int secondItem = item2;
	float similarity;
	
	HashOfHashes::iterator itr1;
	Hash::iterator itr2;
	HashOfHashes::iterator itr3;
	
	if(item1 > item2){
		firstItem = item2;
		secondItem = item1;
	}
	
	itr1= hashSimilarity.find(firstItem);
	if( itr1 != hashSimilarity.end() ){
		
		itr2 = hashSimilarity[firstItem].find(secondItem);
		if( itr2 != hashSimilarity[firstItem].end() )
			return hashSimilarity[firstItem][secondItem];
		
	}
	
	//calcula nova similaridade
	similarity = calculatePearsonSimilarity(firstItem, secondItem, itemRatings);
	
	//verify whether both item exist in the training set
	itr1 = itemRatings.find(firstItem);
	itr3 = itemRatings.find(secondItem);
	if( itr1 != itemRatings.end() )
		numOccItem1 = itemRatings[firstItem].size();
	if( itr3 == itemRatings.end() )
		numOccItem2 = itemRatings[secondItem].size();
	
	//atualiza similaridade em estrutura compartilhada
	if( (hashSimilarity.size() < MAX_HASH_ENTRIES) && (numOccItem1 > MIN_FREQ) && (numOccItem2 > MIN_FREQ) ){
		pthread_mutex_lock( &mutex );
			hashSimilarity[firstItem][secondItem] = similarity;
		pthread_mutex_unlock( &mutex );
	}

	return similarity;
}

/****************************************************************************************
                             Diversity Metrics
*****************************************************************************************/

void diversityEILD(int user, HashOfHashes &testData, HashOfHashes &hashPred, HashOfHashes &hashSimilarity, HashOfHashes &itemRatings, double &EILD, double &ILD) {
	int l;
	int itemL;
	int itemK;
	double C;
	double C_k;
	double rating;
	double probRel_k;
	double probRel_l;
	double discount_k;
	double discount_lk;
	double distance_lk;
	double pearson;
	double sum = 0.0;
	int numRecommendations;
	EILD = 0.0;
	ILD = 0.0;

	Hash::iterator it_hashPredExt;
	Hash::iterator it_hashPredInt;

	numRecommendations = (int) hashPred[user].size();
	
	C = normalizedConstant(numRecommendations);

	int k=1;
	for(it_hashPredExt = hashPred[user].begin(); it_hashPredExt != hashPred[user].end(); it_hashPredExt++) {
		itemK = it_hashPredExt->first;
		C_k = conditionalNormalization(k, user, testData, hashPred, C);

		if(testData[user].count(itemK) > 0) {
			rating = testData[user][itemK];
		} else {
			rating = 0;
		}

		probRel_k = probabilityOfRelevance(rating);

		discount_k =  pow(0.85, (k - 1));
		l = 1;

		for(it_hashPredInt = hashPred[user].begin(); it_hashPredInt != it_hashPredExt; it_hashPredInt++) {
			if( k != l ){
				itemL = it_hashPredInt->first;

				if(testData[user].count(itemL) > 0) {
					rating = testData[user][itemL];
				} else {
					rating = 0;
				}

				probRel_l = probabilityOfRelevance(rating);

				discount_lk = conditionalRankDiscount(l, k);
				
				pearson = (retrieveItemsSimilarity(itemL, itemK, hashSimilarity, itemRatings) + 1)/2;
				distance_lk = 1 - pearson;

				EILD += (C_k * discount_k * discount_lk * probRel_k * probRel_l * distance_lk);

			}

			if( l < k){
				pearson = (retrieveItemsSimilarity(itemL, itemK, hashSimilarity, itemRatings) + 1)/2;
				distance_lk = 1 - pearson; 
				sum += distance_lk;
			}

			l++;

		}

		k++;
	}

	if( sum > 0.0 )
		ILD = 2.0/((double) (numRecommendations * (numRecommendations - 1)))  * sum; 

}

/****************************************************************************************
                             Novelty Metrics
*****************************************************************************************/

void noveltyDiscoveryEPC(int user, unsigned int numUsers, HashOfHashes &testData, HashOfHashes &hashPred, HashOfHashes &itemRatings, double &EPC_r, double &EPC) {
	int itemK;
	int numOccurrences;
	double sum = 0.0;
	double sum_2 = 0.0;
	double C;
	double C_2;
	double discount_k;
	double rating;
	double probRel_k;
	double probSeen_k;

	Hash::iterator it_hashPredExt;
	Hash::iterator it_hashPredInt;

	int numRecommendations = (int) hashPred[user].size();

	C = normalizedConstant(numRecommendations);
	C_2 = 1.0/((double) numRecommendations);

	int k=1;
	for(it_hashPredExt = hashPred[user].begin(); it_hashPredExt != hashPred[user].end(); it_hashPredExt++) {
		itemK = it_hashPredExt->first;

		discount_k =  pow(0.85, (k - 1));

		if(testData[user].count(itemK) > 0) {
			rating = testData[user][itemK];
		} else {
			rating = 0;
		}

		probRel_k = probabilityOfRelevance(rating);

		numOccurrences = (int) itemRatings.count(itemK);
		probSeen_k =  ((double) numOccurrences)/(double) numUsers;

		sum += (discount_k * probRel_k * (1.0 - probSeen_k) );

		sum_2 += (1.0 - probSeen_k);

		k++;
	}

	EPC_r = C * sum;
	EPC = C_2 * sum_2;
}

/****************************************************************************************
                             Load Functions
*****************************************************************************************/

void loadPred(char *predFile, HashOfHashes &hashPred) {
	std::ifstream file;
	std::string line;
	std::string itemId;
	std::string rating;
	std::vector<std::string> vetor;
	int userId;
	int vectorSize;

	file.open(predFile);

	if(!file.is_open()) {
		std::cout << "\nError opening file!" << endl;
		std::exit(-1);
	}

	while(!file.eof()) {
		getline(file, line);

		// separa a linha através do delimitador " " e salva o resultado em um vetor
		vetor.clear();
		string_tokenize(line, vetor, " \t");
		userId = atoi(vetor[0].c_str());
		vectorSize = (int) vetor.size();
		
		for(int i=2; i<vectorSize; i++){
			std::stringstream ssBuffer(vetor[i]);
			getline(ssBuffer, itemId, ':');
			getline(ssBuffer, rating, ':');
			
			hashPred[userId][atoi(itemId.c_str())] = atof(rating.c_str());
		}
		
	}

	file.close();
}

void loadTrainData(char *trainFile, HashOfHashes &itemRatings, HashOfHashes &trainData) {
	std::ifstream file;
	std::string line;
	std::string itemId;
	std::string rating;
	std::vector<std::string> vetor;
	int userId;
	int numTimeUnits;
	int vectorSize;

	file.open(trainFile);

	if(!file.is_open()) {
		std::cout << "\nError opening file!" << endl;
		std::exit(-1);
	}

	while(!file.eof()) {
		getline(file, line);

		// separa a linha através do delimitador " " e salva o resultado em um vetor
		vetor.clear();
		string_tokenize(line, vetor, " \t");
		userId = atoi(vetor[0].c_str());
		numTimeUnits = atoi(vetor[1].c_str());
		
		for(int k=0; k<numTimeUnits; k++){
			getline(file, line);
			string_tokenize(line, vetor, " \t");
			vectorSize = (int) vetor.size();
			
			for(int i=3; i<vectorSize; i++){
				std::stringstream ssBuffer(vetor[i]);
				getline(ssBuffer, itemId, ':');
				getline(ssBuffer, rating, ':');
				
				itemRatings[atoi(itemId.c_str())][userId] = atof(rating.c_str());
				trainData[userId][atoi(itemId.c_str())] = atof(rating.c_str());
				
				if( atof(rating.c_str()) > MAX_RATING)
					MAX_RATING = atof(rating.c_str());
			}
		}

	}

	file.close();
}

void loadTestData(char *testFile, HashOfHashes &testData) {
	std::ifstream file;
	std::string line;
	std::string itemId;
	std::string rating;
	std::vector<std::string> vetor;
	int userId;
	int vectorSize;

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
		userId = atoi(vetor[0].c_str());
		vectorSize = (int) vetor.size();			
			
		for(int i=3; i<vectorSize; i++){
			std::stringstream ssBuffer(vetor[i]);
			getline(ssBuffer, itemId, ':');
			getline(ssBuffer, rating, ':');
		
			testData[userId][atoi(itemId.c_str())] = atof(rating.c_str());
		}

	}

	file.close();
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

int getArgs(int argc, char **argv, char **baseFile, char **predFile, char **testFile, char **outFile, int *numThreads) {
	int opt;
	*baseFile = NULL;
	*predFile = NULL;
	*outFile = NULL;
	*testFile = NULL;
	*numThreads = 1;

	while( (opt = getopt(argc, argv, "h:b:p:l:o:t:")) != -1 ) {
		switch(opt) {
			case 'h':
				printUsage();
				return 0;
				break;
			case 'b':
				*baseFile = optarg;
				break;
			case 'p':
				*predFile = optarg;
				break;
			case 'l':
				*testFile = optarg;
				break;
			case 'o':
				*outFile = optarg;
				break;
			case 't':
				*numThreads = atoi(optarg);
				break;
			default: {
				printUsage();
				return 0;
			}
		}
	}

	if(*baseFile == NULL || 
	   *predFile == NULL || 
	   *testFile == NULL || 
	   *outFile == NULL || 
	   *numThreads <= 0 || 
	   *numThreads > 200 ) {
		printUsage();
		return 0;
	}

	return 1;
}

void printUsage() {
	std::string args = "";
	args += "    -b <baseFile> ";
	args += "\n    -p <predFile> ";
	args += "\n    -o <outFile> ";
	args += "\n    -l <testFile> ";
	args += "\n    -t <numThreads> ";
	args += "\n    [-h]\n\n";
	std::cout << "\n  Argumentos corretos:\n" << args;
}
