#include "Sync.h"
#include "Rsn.h"

module SyncM {
	provides {
		interface SplitControl as Sync;
		interface Set<NodeInfo> as SetNodeInfo;
		interface Get<NodeInfo> as GetNodeInfo;

	}
	uses {
		interface Leds;
		interface Packet as Packet;
		interface AMPacket as AMPacket;
		interface AMSend as AMSend;
		interface Receive as Receive;	
		interface LocalTime<TMilli> as LocalTime;
		interface PacketField<uint8_t> as PacketTransmitPower;
	}
}
implementation {

		/* Variables */
	uint32_t syncTime;
	bool radioBusy = FALSE;
	message_t pkt;
	NodeInfo info;

	/* Functions */
	void intiateSyncMsg();
	void createSyncMsg();
	void handleSyncMsg(SyncMsg* syncpkt);
	uint8_t getPowerNextHop();
	void ledUpLink();
	void ledDownLink();

	/* Starting synchronization algorithm */
	command error_t Sync.start() {
		intiateSyncMsg();
		return SUCCESS;
	}

	/* Initiate a synchronization message */
	void intiateSyncMsg(){
		if (!radioBusy) 
		{
			createSyncMsg();
			call  PacketTransmitPower.set(&pkt,getPowerNextHop());
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SyncMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
				ledDownLink();
			}
		}
	}

	/* Forge synchronization message */
	void createSyncMsg() {
		SyncMsg* syncpkt = (SyncMsg*)(call Packet.getPayload(&pkt, sizeof(SyncMsg)));
		syncpkt->srcRank = info.myRank;
		syncpkt->dstRank = info.neighborsRank[1];
		syncpkt->data = info.myRank;  // Original sender 
	}

	/* Upon receiving a SyncMsg */
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(SyncMsg))
		{
			handleSyncMsg((SyncMsg*)payload);
		}
		return msg;
	}

	/* Forward the SyncMsg in the right direction */
	void handleSyncMsg(SyncMsg* syncpkt) {
		if (syncpkt->dstRank == info.myRank) {
			// Sync OK 
			ledUpLink();
			signal Sync.startDone(SUCCESS);
		}
	}

	/* When Sync message has been sent */
	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg)
		{				
			syncTime = call LocalTime.get();
			radioBusy = FALSE;
		}
	}

	command error_t Sync.stop(){
		signal Sync.stopDone(SUCCESS);
	}

	uint8_t getPowerNextHop() {
		return  ((info.neighborsRank[1] - info.myRank) > 1) ? TWO_HOP_POWER : ONE_HOP_POWER;
	}


	/* Providing interfaces Set and Get */
	command void SetNodeInfo.set(NodeInfo data) {
		info = data;
	}

	void ledUpLink(){ call Leds.set(3); }
	void ledDownLink(){ call Leds.set(1); }

	command NodeInfo GetNodeInfo.get() {
		info.localTime = syncTime;
		return info;
	}

}