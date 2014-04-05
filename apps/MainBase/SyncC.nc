#include "Sync.h"

configuration SyncC {
	provides {
		interface SplitControl as Sync;
		interface Set<NodeInfo> as SetNodeInfo;
		interface Get<NodeInfo> as GetNodeInfo;

	}
}
implementation {

	/* Components */
	components LedsC;
	components SyncM as Module;
	components new AMSenderC(AM_SYNC) as AMSenderC;
	components new AMReceiverC(AM_SYNC) as AMReceiverC;
	components LocalTimeMilliC;
	components RF230ActiveMessageC as RF230ActiveMessageCPower;


	/* Wiring components */
	Module.Leds -> LedsC;
	Module.Packet -> AMSenderC.Packet;
	Module.AMPacket -> AMSenderC.AMPacket;
	Module.AMSend -> AMSenderC.AMSend;
	Module.Receive -> AMReceiverC.Receive;
	Module.LocalTime -> LocalTimeMilliC;

	Module.PacketTransmitPower -> RF230ActiveMessageCPower.PacketTransmitPower;


	Module = Sync;
	Module = SetNodeInfo;
	Module = GetNodeInfo;

}