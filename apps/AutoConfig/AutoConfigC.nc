#include <Timer.h>
#include "AutoConfig.h"

module AutoConfigC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timeout;
	uses interface SplitControl as AMControl;
	uses interface PacketField<uint8_t> as PacketRSSI;
	uses interface PacketField<uint8_t> as PacketTransmitPower;

}
implementation {

	event void Boot.booted() {
		
	}

	event void Timeout.fired() {

	}

	event void AMControl.startDone(error_t err) {

	}

	event void AMControl.stopDone(error_t err) {

	}
}