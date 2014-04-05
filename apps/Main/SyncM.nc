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
	void createSyncMsg(uint16_t dst, uint16_t originalSender);
	void handleSyncMsg(SyncMsg* syncpkt);
	void forwardSyncMsg(uint8_t txPower);
	uint8_t getPowerNextHop();
	uint8_t getPowerPreviousHop();
	void ledUpLink();
	void ledDownLink();


	/* Starting synchronization algorithm */
	command error_t Sync.start() {
	//	call Leds.set(info.neighborsRank[0]);
		return SUCCESS;
	}

	/* Forge synchronization message */
	void createSyncMsg(uint16_t originalSender, uint16_t dst) {
		SyncMsg* syncpkt = (SyncMsg*)(call Packet.getPayload(&pkt, sizeof(SyncMsg)));
		syncpkt->srcRank = info.myRank;
		syncpkt->dstRank = dst;
		syncpkt->data = originalSender;
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
			if (syncpkt->srcRank < info.myRank)
			{
				syncTime = call LocalTime.get();
				if (!info.lastNode)
				{
					ledDownLink();
					createSyncMsg(info.neighborsRank[1],syncpkt->data);
					forwardSyncMsg(getPowerNextHop());
				}
				else {
					ledUpLink();
					createSyncMsg(info.neighborsRank[0],info.myRank);
					forwardSyncMsg(getPowerPreviousHop());
				}
				
			}
			else {
				ledUpLink();
				createSyncMsg(info.neighborsRank[0],syncpkt->data);
				forwardSyncMsg(getPowerPreviousHop());

			}	
			signal Sync.startDone(SUCCESS);
		}
	}

	/* Forward */
	void forwardSyncMsg(uint8_t txPower) {
		call  PacketTransmitPower.set(&pkt,txPower);
		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SyncMsg)) == SUCCESS)
		{
			radioBusy = TRUE;
		}
	}


	/* When Sync message has been sent */
	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg)
		{
			radioBusy = FALSE;
		}
	}

	uint8_t getPowerNextHop() {
		return  ((info.neighborsRank[1] - info.myRank) > 1) ? TWO_HOP_POWER : ONE_HOP_POWER;
	}

	uint8_t getPowerPreviousHop() {
		return  ((info.myRank - info.neighborsRank[0]) > 1) ? TWO_HOP_POWER : ONE_HOP_POWER;
	}

	/*  Used to initiate data before starting the algorithm */
	command void SetNodeInfo.set(NodeInfo data) {
		info = data;
	}

	/* Used to provide the modified data */
	command NodeInfo GetNodeInfo.get() {
		info.localTime = syncTime;
		return info;
	}

	void ledUpLink(){ call Leds.set(3); }
	void ledDownLink(){ call Leds.set(1); }

	command error_t Sync.stop(){
		signal Sync.stopDone(SUCCESS);
	}

}