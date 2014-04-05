#include <Timer.h>
#include "AutoConfig.h"
#include "Rsn.h"



configuration AutoConfigC {
	provides {
		interface SplitControl as AutoConfig;
		interface Get<NodeInfo> as GetNodeInfo;
	}
}
implementation {
	components LedsC;
	components AutoConfigM as Module;
	components new TimerMilliC() as WaitAck;
	components new TimerMilliC() as WaitForRadio;
	components new TimerMilliC() as BackoffForAck;
	components RandomC;
	components new AMSenderC(AM_AUTOCONFIGMSG) as AMSenderC;
	components new AMReceiverC(AM_AUTOCONFIGMSG) as AMReceiverC;

	components RF230ActiveMessageC as RF230ActiveMessageCRSSI;
	components RF230ActiveMessageC as RF230ActiveMessageCPower;


	Module.PacketRSSI -> RF230ActiveMessageCRSSI.PacketRSSI;
	Module.PacketTransmitPower -> RF230ActiveMessageCPower.PacketTransmitPower;

	Module.Leds -> LedsC;
	Module.WaitAck -> WaitAck;
	Module.WaitForRadio -> WaitForRadio;
	Module.BackoffForAck -> BackoffForAck;
	Module.Packet -> AMSenderC.Packet;
	Module.AMPacket -> AMSenderC.AMPacket;
	Module.AMSend -> AMSenderC.AMSend;
	Module.Receive -> AMReceiverC.Receive;
	Module.Random -> RandomC;

	Module = AutoConfig;
	Module = GetNodeInfo;
}