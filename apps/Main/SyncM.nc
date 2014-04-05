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
	void createSyncMsg(uint16_t originalSender, uint16_t dst);
	void handleSyncMsg(SyncMsg* syncpkt);

	/* Starting synchronization algorithm */
	command error_t Sync.start() {
		intiateSyncMsg();
		return SUCCESS;
	}

	/* Initiate a synchronization message */
	void intiateSyncMsg(){
		if (!radioBusy) 
		{
			if (info.lastNode)
			{
				createSyncMsg(info.myRank, info.neighborsRank[0]);
			} else if (info.myRank == IS_BASESTATION){
				createSyncMsg(info.myRank, info.neighborsRank[1]);
			}
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SyncMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
			}
		}
	}

	/* Forge synchronization message */
	void createSyncMsg(uint16_t originalSender, uint16_t dst) {
		SyncMsg* syncpkt = (SyncMsg*)(call Packet.getPayload(&pkt, sizeof(SyncMsg)));
		syncpkt->srcRank = info.myRank;
		syncpkt->dstRank = dst;
		syncpkt->sender = originalSender;
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
		if (!radioBusy && syncpkt->srcRank != info.myRank) {
			if (syncpkt->srcRank > info.myRank)
			{
				// Sync coming from the last node, forwarding
				createSyncMsg(syncpkt->sender, info.neighborsRank[0]);
			}
			else {
				// Sync coming from the base station
				// record SyncTime
				syncTime = call LocalTime.get();
				// forward packet
				createSyncMsg(syncpkt->sender, info.neighborsRank[1]);
			}
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SyncMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
			}
			signal Sync.startDone(SUCCESS);
		}
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

	/* When Sync message has been sent */
	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg)
		{
			radioBusy = FALSE;
		}
	}

	command error_t Sync.stop(){
		signal Sync.stopDone(SUCCESS);
	}

}