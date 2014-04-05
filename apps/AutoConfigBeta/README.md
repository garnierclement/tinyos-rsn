# AutoConfig Application

Basic auto configuration algorithm for wireless motes.

## Concept

In this algorithm, the sink node will trigger the autoconfig procedure, during which it will send an autoconfig message containing its rank (=0) to its one hop neighbor. Upon receiving this message, the neighbor will answer with an ack message and update its rank (received rank + 1). If after a timeout period the autoconfig message emitting node does not receive an ack message, it retries sending the autoconfig message several times. If it still has not received an ack message, it will send an autoconfig message with a higher transmission power in order to reach its second hop neighbor. 

This algorithm takes into account that there can be overhearing of an autoconfig message by a node which has already configured its rank (and thus this algorithm can apply to a configuration which is not necessarily the network’s initialization, e.g. the entry of a new node). Also each node stores both its own rank and its neighbor’s rank (neighbor closest to the sink) in order to determine the required transmission power.

This algorithm can be executed whenever the sink needs to reconfigure network topology

## Usage

To compile the application for the IRIS platform

	$ make iris

To compile and load the application on the IRIS motes

	$ make iris install mib520,/dev/ttyUSB0
