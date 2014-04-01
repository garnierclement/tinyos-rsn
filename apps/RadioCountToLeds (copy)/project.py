from TOSSIM import *
t=Tossim([])
r = t.radio()
f = open("topo.txt", "r")
n1 = t.getNode(1)
n2 = t.getNode(2)
n3 = t.getNode(3)
n4 = t.getNode(4)

import sys
t.addChannel("Boot", sys.stdout);
t.addChannel("RadioCountToLedsC", sys.stdout);
t.addChannel("WSN_Project", sys.stdout);

n1.bootAtTime(100001)
n2.bootAtTime(800008)
n3.bootAtTime(200)
n4.bootAtTime(20000)

for line in f:
  s = line.split()
  if s:
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))
    
noise = open("meyer-heavy.txt", "r")
for line in noise:
  str1 = line.strip()
  if str1:
    val = int(str1)
    for i in range(1, 5):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(1, 5):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()
    
for i in range(0, 1000):
  t.runNextEvent()
  
#t.runNextEvent();
#time = t.time()
#while time + 50000000000 > t.time():
#  t.runNextEvent()
