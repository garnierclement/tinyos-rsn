#include <Timer.h>
#include "AutoConfig.h"

configuration AutoConfigAppC {
}
implementation {
	components MainC;
	components AutoConfigC as App;
	components LedsC;
	components new TimerMilliC() as Timeout;
	components ActiveMessageC;
	components RF230ActiveMessageC as RF230ActiveMessageCRSSI;
	components RF230ActiveMessageC as RF230ActiveMessageCPower;


	App.PacketRSSI -> RF230ActiveMessageCRSSI.PacketRSSI;
	App.PacketTransmitPower -> RF230ActiveMessageCPower.PacketTransmitPower;

	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timeout -> Timeout;
	App.AMControl -> ActiveMessageC;


}