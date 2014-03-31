#include <Timer.h>
#include "AutoConfig.h"

module AutoConfigC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timeout;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;

	uses interface PacketField<uint8_t> as PacketRSSI;
	uses interface PacketField<uint8_t> as PacketTransmitPower;

}
implementation {

	/* Variables */
	bool radioBusy = FALSE;
  	message_t pkt;
  	uint8_t myRank = NOT_DEFINED;
  	bool receivedAck = FALSE;
  	bool sentAutoConfig = FALSE;
  	int neighborsRank[2]; // 0 left 1 right

  	/* Functions */
  	AutoConfigMsg* createAutoConfigMsg(uint8_t pwr);
  	void createAutoConfigAck(AutoConfigMsg* srcpkt);
  	void handleAck(AutoConfigMsg* ackpkt);
	void handleAutoConfig(AutoConfigMsg* acpkt); 	
	void sendAck(AutoConfigMsg* srcpkt);


	event void Boot.booted() {
		call AMControl.start();										// Wakes up radio
	}

	event void Timeout.fired() {

	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS)
		{
			call Timeout.startPeriodic(TIMEOUT_PERIOD_MILLI);		// Wait for AutoConfigMsg
		}
		else {
			call AMControl.start();										// Restart the radio if it doesn't work
		}
	}

	event void AMControl.stopDone(error_t err) {

	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg)
		{
			radioBusy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(AutoConfigMsg))
    	{
      		AutoConfigMsg* acpkt = (AutoConfigMsg*)payload;
      		handleAck(acpkt);
      		handleAutoConfig(acpkt);

	    }
    	return msg;
	}

	AutoConfigMsg* createAutoConfigMsg(uint8_t pwr) {
		AutoConfigMsg* acpkt = (AutoConfigMsg*)(call Packet.getPayload(&pkt, sizeof(AutoConfigMsg)));
		acpkt->ack = NOT_AUTOCONFIGACK;
		acpkt->srcRank = myRank;
		acpkt->txPower = pwr;
		acpkt->dstRank = (pwr == ONE_HOP_POWER) ? (myRank + ONE_HOP) : (myRank + TWO_HOP);

		return acpkt;
	}

	void createAutoConfigAck(AutoConfigMsg* srcpkt) {
		AutoConfigMsg* ackpkt = (AutoConfigMsg*)(call Packet.getPayload(&pkt, sizeof(AutoConfigMsg)));
		ackpkt->ack = IS_AUTOCONFIGACK;
		ackpkt->srcRank = myRank;
		ackpkt->dstRank = srcpkt->srcRank;
		ackpkt->txPower = srcpkt->txPower;
	}

	void handleAck(AutoConfigMsg* ackpkt) {
		if (myRank != NOT_DEFINED && ackpkt->srcRank > myRank)
      		if (sentAutoConfig && !receivedAck)
      			if (ackpkt->srcRank == neighborsRank[1])
      					receivedAck = TRUE;
	}

	void handleAutoConfig(AutoConfigMsg* acpkt) {
		if (myRank == NOT_DEFINED)
		{
			myRank = acpkt->dstRank;
			neighborsRank[0] = acpkt->srcRank;
			sendAck(acpkt);
		}
	}

	void sendAck(AutoConfigMsg* srcpkt) {
		if (!radioBusy)
		{
			createAutoConfigAck(srcpkt);
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(AutoConfigMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
			}
		}
	}
}