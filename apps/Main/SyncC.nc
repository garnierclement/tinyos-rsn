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

	/* Wiring components */
	Module.Leds -> LedsC;
	Module.Packet -> AMSenderC.Packet;
	Module.AMPacket -> AMSenderC.AMPacket;
	Module.AMSend -> AMSenderC.AMSend;
	Module.Receive -> AMReceiverC.Receive;
	Module.LocalTime -> LocalTimeMilliC;

	Module = Sync;
	Module = SetNodeInfo;
	Module = GetNodeInfo;

}