from xml.dom import minidom
import unicodedata
doc = minidom.parse('output.xml')
node = doc.documentElement
timesteps = doc.getElementsByTagName("timestep")


for timestep in timesteps :
	edges = timestep.getElementsByTagName("edge")
	timestep1 = timestep.attributes['time'].value
	capteur1 = 0
	capteur2 = 0
	capteur3 = 0
	capteur4 = 0
	capteur5 = 0
	capteur6 = 0
	for edge in edges : 
		lanes = edge.getElementsByTagName("lane")
		edgeposition = edge.attributes['id'].value
		edgepos = 0
		if edgeposition == "1to0" :
			edgepos = 1
		if edgeposition == "2to1" :
			edgepos = 2
		if edgeposition == "3to2" :
			edgepos = 3
		if edgeposition == "4to3" :
			edgepos = 4
		if edgeposition == "5to4" :
			edgepos = 5
		for lane in lanes :
			vehicles = lane.getElementsByTagName("vehicle")
			for vehicle in vehicles :
				#We assume that the position is taken in the middle of the car
				posvehicle = float(vehicle.attributes['pos'].value) + ((edgepos-1)*4)
				if -2.00 <= posvehicle < 2.00:
					capteur1 = 1
				if 2.00 <= posvehicle < 6.00 :
					capteur2 = 1
				if 6.00 <= posvehicle < 10.00 :
					capteur3 = 1
				if 10.00 <= posvehicle < 14.00 :
					capteur4 = 1
				if 14.00 <= posvehicle < 18.00 :
					capteur5 = 1
				if 18.00 <= posvehicle < 22.00 :
					capteur6 = 1

	print capteur2,capteur3,capteur4,capteur5



