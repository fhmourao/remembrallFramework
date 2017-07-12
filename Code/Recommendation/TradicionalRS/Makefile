CC = g++
LIBS = -lm -pthread
CFLAGS = -Wall -c -fPIC -O3 -fomit-frame-pointer -ffast-math -DREENTRANT -std=c++0x
#CFLAGS = -Wall -c -fPIC -g -DREENTRANT -DDEBUG -std=c++0x
PROGFLAGS = $(LIBS) -fPIC -O3 -fomit-frame-pointer -ffast-math -DREENTRANT
#PROGFLAGS = $(LIBS) -fPIC -g -DREENTRANT

EXE = userKNN
OBJ = userKNN.o

all: clean $(OBJ)
	$(CC) $(PROGFLAGS) $(OBJ) -o $(EXE)

userKNN.o: userKNN.h userKNN.cpp
	$(CC) $(CFLAGS) userKNN.cpp -o userKNN.o

clean:
	rm -f .*.swp *~ $(OBJ) $(EXE)

backup:
	tar -cvzf backups/`date +%Y-%m-%d-%H.%M`.tar.gz *.h *.cpp Makefile 
