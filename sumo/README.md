# SUMO

Simulation of Urban MObility  

# Links

* [SUMO](http://sumo-sim.org/)
* [Wiki SUMO](http://sumo-sim.org/wiki/Main_Page)

# Install SUMO

Install SUMO on Ubuntu 13.10
	
	$ sudo add-apt-repository ppa:sumo/stable
	$ sudo apt-get update
	$ sudo apt-get install sumo sumo-tools sumo-doc

# Informations

* Networks file : `.edg.xml`, .`nod.xml`, 
* Route file : `.rou.xml` (cars and car distribution), linked in [.sumocfg]

# Usage

Generate `.net.xml`

	$ netconvert --node-files=[.nod.xml] --edge-files=[.edg.xml] --output-files=[.net.xml]

Launch simulationn

	$ sumo-gui -c [.sumocfg] -a 

