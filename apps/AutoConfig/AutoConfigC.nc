#include <Timer.h>
#include "AutoConfig.h"

module AutoConfigC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timeout;

}
implementation {

	event void Boot.booted() {
		
	}
}