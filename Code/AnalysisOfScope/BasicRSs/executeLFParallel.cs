using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using MyMediaLite.Data;
using MyMediaLite.IO;
using MyMediaLite.RatingPrediction;
using System.Threading;

public class executeLF {

        public static void Main(string[] args) {                                                                                                                                                                                                                        
                                  
            var TRAIN_FILE = args[0];
                                              
            var OUT_FILE_NAME = args[1];
                                             
            int TOP_N = int.Parse(args[2]);
            int NUM_THREADS = int.Parse(args[3]);

            var user_mapping = new Mapping();
            var item_mapping = new Mapping();

            // load the data
            var training_data = RatingData.Read(TRAIN_FILE, user_mapping, item_mapping);
            
            // set up the recommender
            var recommender = new LatentFeatureLogLinearModel();
            recommender.Ratings = training_data;
            recommender.Train();

            Thread[] threadsArray = new Thread[NUM_THREADS];
            for(int index=0; index < NUM_THREADS; index++){
                 int startIndex = index;
                 threadsArray[index] = new Thread(() => RecommendItems(startIndex, NUM_THREADS, recommender, user_mapping, item_mapping, Convert.ToString(OUT_FILE_NAME), TOP_N));
                 threadsArray[index].Start();
            }

        }

        static void RecommendItems(int startIndex, int NUM_THREADS, LatentFeatureLogLinearModel recommender, Mapping user_mapping, Mapping item_mapping, string fileName, int TOP_N) {

            // create a writer and open the file
            string outFileName = Convert.ToString(fileName) + "." + startIndex;

            TextWriter outFile = new StreamWriter(outFileName);

            for (int userId=startIndex; userId <= ((RatingPredictor)recommender).Ratings.MaxUserID; userId+=NUM_THREADS){
            
		var predictions = recommender.Recommend( userId, n:TOP_N);
		
		string text =  Convert.ToString(user_mapping.ToOriginalID(userId));
		outFile.Write(text);
		for (int index=0; index < TOP_N ; index++){
			text =  " " + item_mapping.ToOriginalID(predictions[index].Item1) +  ":" + predictions[index].Item2;
			outFile.Write(text);
		}
		outFile.WriteLine();
            }

          // close outfile
          outFile.Close();

        }

}
