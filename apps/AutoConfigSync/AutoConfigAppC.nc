#include <Timer.h>
#include "AutoConfig.h"

configuration AutoConfigAppC {
}
implementation {
	components MainC;
	components LedsC;
	components AutoConfigC as App;
	components new TimerMilliC() as Timeout;
	components new TimerMilliC() as WaitAck;
	components new TimerMilliC() as WaitForRadio;
	components new TimerMilliC() as BackoffForAck;
	components ActiveMessageC;
	components RandomC;


	components new AMSenderC(AM_AUTOCONFIGMSG);
	components new AMReceiverC(AM_AUTOCONFIGMSG);

	components RF230ActiveMessageC as RF230ActiveMessageCRSSI;
	components RF230ActiveMessageC as RF230ActiveMessageCPower;


	App.PacketRSSI -> RF230ActiveMessageCRSSI.PacketRSSI;
	App.PacketTransmitPower -> RF230ActiveMessageCPower.PacketTransmitPower;

	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timeout -> Timeout;
	App.WaitAck -> WaitAck;
	App.WaitForRadio -> WaitForRadio;
	App.BackoffForAck -> BackoffForAck;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.Receive -> AMReceiverC;
	App.AMControl -> ActiveMessageC;
	App.Random -> RandomC;


}