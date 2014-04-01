#! /usr/bin/python
from TOSSIM import *
import sys

t = Tossim([])
r = t.radio()
f = open("topo.txt", "r")

lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))
#configure ouput chanel for these components
t.addChannel("RadioCountToLedsC", sys.stdout)
t.addChannel("Boot", sys.stdout)
t.addChannel("Timer0", sys.stdout)
t.addChannel("AMSend", sys.stdout)
t.addChannel("AMControl", sys.stdout)
t.addChannel("Receive", sys.stdout)

noise = open("/opt/tinyos-2.1.1/tos/lib/tossim/noise/meyer-heavy.txt", "r")
lines = noise.readlines()
for line in lines:
  str1 = line.strip()
  if (str1 != ""):
    val = int(str1)
    for i in range(1, 5):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(1, 5):
  t.getNode(i).createNoiseModel()

t.getNode(1).bootAtTime(10001);
t.getNode(2).bootAtTime(80008);
t.getNode(3).bootAtTime(800001);
t.getNode(4).bootAtTime(8000001);

for i in range(0, 100000):
  t.runNextEvent()


for i in range(0, 500):
  t.runNextEvent()
