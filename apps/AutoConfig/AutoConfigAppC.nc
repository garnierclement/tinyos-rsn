#include <Timer.h>
#include "AutoConfig.h"

configuration AutoConfigAppC {
}
implementation {
	components MainC;
	components AutoConfigC as App;
	components LedsC;
	components new TimerMilliC() as Timeout;

	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timeout -> Timeout;

}