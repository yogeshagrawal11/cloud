import threading
import time

# function to get square of no
def get_square(n):    
    print ("square of {} : {}".format(n,n*n) )

#function to get cube of no
def get_cube(n):
    print ("Cube of {} : {}".format(n,n*n*n))
    time.sleep(15)

### to store threadid 
threads = []

for i in range(10):
    # creates and start threads to get sqate of no 
    X=threading.Thread(target=get_square, args=(i,))
    X.start()
    threads.append(X)
    # creates and start threads to get sqate of no 
    Y=threading.Thread(target=get_cube, args=(i,))
    Y.start()
    threads.append(Y)

### waiting for all threads to finish before quiting program
for index,thread in enumerate(threads):
    thread.join()

'''
This is output of script

square of 0 : 0
Cube of 0 : 0
square of 1 : 1
Cube of 1 : 1
square of 2 : 4
Cube of 2 : 8
square of 3 : 9
Cube of 3 : 27
square of 4 : 16
Cube of 4 : 64
square of 5 : 25
Cube of 5 : 125
square of 6 : 36
square of 7 : 49
Cube of 6 : 216
Cube of 7 : 343
Cube of 8 : 512
square of 9 : 81
Cube of 9 : 729
square of 8 : 64

'''
