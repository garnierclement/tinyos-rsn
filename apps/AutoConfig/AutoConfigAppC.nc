#include <Timer.h>
#include "AutoConfig.h"

configuration AutoConfigAppC {
}
implementation {
	components MainC;
	components AutoConfigC as App;
	components LedsC;

	App.Boot -> MainC;
	App.Leds -> LedsC;

}