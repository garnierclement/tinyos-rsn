#include <Timer.h>
#include "AutoConfig.h"
#include "Sync.h"



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

	// AM Componenents for Autoconfiguration 
	components new AMSenderC(AM_AUTOCONFIGMSG) as AC_AMSenderC;
	components new AMReceiverC(AM_AUTOCONFIGMSG) as AC_AMReceiverC;

	// AM Componenents for synchronisation 
	components new AMSenderC(AM_SYNC) as SYNC_AMSenderC;
	components new AMReceiverC(AM_SYNC) as SYNC_AMReceiverC;
	components LocalTimeMilliC;

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

	// Wiring Autoconfig AM components to App
	App.AC_Packet -> AC_AMSenderC.Packet;
	App.AC_AMPacket -> AC_AMSenderC.AMPacket;
	App.AC_AMSend -> AC_AMSenderC.AMSend;
	App.AC_Receive -> AC_AMReceiverC.Receive;

	// Wiring Sync AM components to App
	App.SYNC_Packet -> SYNC_AMSenderC.Packet;
	App.SYNC_AMPacket -> SYNC_AMSenderC.AMPacket;
	App.SYNC_AMSend -> SYNC_AMSenderC.AMSend;
	App.SYNC_Receive -> SYNC_AMReceiverC.Receive;
	App.Clock -> LocalTimeMilliC;

	
	App.AMControl -> ActiveMessageC;
	App.Random -> RandomC;


}