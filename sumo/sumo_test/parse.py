from xml.dom import minidom
doc = minidom.parse('output.xml')
node = doc.documentElement
timesteps = doc.getElementsByTagName("timestep")
#timesteps = xmldoc.getElementsByTagName('timestep')
#print len(vehicles)
#print timesteps[0].attributes['time'].value
#print vehicles[0].attributes['pos'].value

for timestep in timesteps :
	edges = timestep.getElementsByTagName("edge")
	print "TIMESTEP",timestep.attributes['time'].value
	for edge in edges : 
		lanes = edge.getElementsByTagName("lane")
		for lane in lanes :
			vehicles = lane.getElementsByTagName("vehicle")
			for vehicle in vehicles : 
				print vehicle.attributes['pos'].value




#[0].childNodes[0].data
