#include <Timer.h>
#include "AutoConfig.h"

module AutoConfigC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timeout;
	uses interface Timer<TMilli> as WaitAck;
	uses interface Timer<TMilli> as WaitForRadio;
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
  	uint8_t myRank = NOT_DEFINED;			// Rank of the node
  	bool receivedAck = FALSE;
  	bool sentAutoConfig = FALSE;
  	uint8_t neighborsRank[2]; 				// 0 left (closer to the sink)  1 right
  	uint8_t attempt = 0;					// AutoCOnfigMsg retransmission attempts

  	/* Functions */
  	void createAutoConfigMsg(uint8_t pwr);
  	void createAutoConfigAck(AutoConfigMsg* srcpkt);
  	void handleAck(AutoConfigMsg* ackpkt);
	void handleAutoConfig(AutoConfigMsg* acpkt); 	
	void sendAck(AutoConfigMsg* srcpkt);
	void sendAutoConfigMsg(uint8_t pwr);
	AutoConfigMsg* getAutoConfigPayload(message_t* msg);


	/* At boot time, wake up the radio */
	event void Boot.booted() {
		call AMControl.start();	
		call Leds.led0On();
	}

	/* When the radio has started */
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS){
			// Wait for AutoConfigMsg
			call Timeout.startPeriodic(TIMEOUT_PERIOD_MILLI);		
		}
		else {
			// Restart the radio if it doesn't work
			call AMControl.start();										
		}
	}

	/* Upon receiving a message */
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(AutoConfigMsg))
    	{
      		AutoConfigMsg* acpkt = (AutoConfigMsg*)payload;
      		// Check if the received message is an Ack and handle it 
      		handleAck(acpkt);
      		// Check if the received message is AutoCOnfig, if so set myRank (node id), send Ack and forge new AutoContigMsg
      		handleAutoConfig(acpkt);

	    }
    	return msg;
	}

	/* Upon receiving an Ack for a previous sent AutoConfigMsg */
	void handleAck(AutoConfigMsg* ackpkt) {
		if (myRank != NOT_DEFINED && ackpkt->srcRank > myRank){
      		if (sentAutoConfig && !receivedAck) 
      		{
      			receivedAck = TRUE;
      			neighborsRank[1] = ackpkt->srcRank;
      			call Leds.led1Off();
      		}
      	}
	}

	/* Upon receiving an AutoConfigMsg */
	void handleAutoConfig(AutoConfigMsg* acpkt) {
		if (myRank == NOT_DEFINED)
		{
			call Leds.led1On();
			myRank = acpkt->dstRank;
			neighborsRank[0] = acpkt->srcRank;
			sendAck(acpkt);
			sendAutoConfigMsg(ONE_HOP_POWER);
		}
	}

	void sendAck(AutoConfigMsg* srcpkt) {
		if (!radioBusy)
		{
			createAutoConfigAck(srcpkt);
			call  PacketTransmitPower.set(&pkt,srcpkt->txPower);
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(AutoConfigMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
				call Leds.led0Off();
			}
		}
	}

	void createAutoConfigMsg(uint8_t pwr) {
		AutoConfigMsg* acpkt = (AutoConfigMsg*)(call Packet.getPayload(&pkt, sizeof(AutoConfigMsg)));
		acpkt->ack = NOT_AUTOCONFIGACK;
		acpkt->srcRank = myRank;
		acpkt->txPower = pwr;
		acpkt->dstRank = (pwr == ONE_HOP_POWER) ? (myRank + ONE_HOP) : (myRank + TWO_HOP);
	}

	AutoConfigMsg* getAutoConfigPayload(message_t* msg) {
		return (AutoConfigMsg*)(call Packet.getPayload(msg, sizeof(AutoConfigMsg)));
	}

	void sendAutoConfigMsg(uint8_t pwr) {

		if (!radioBusy)
		{
			createAutoConfigMsg(pwr);
			call  PacketTransmitPower.set(&pkt,pwr);
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(AutoConfigMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
			}
		}else{
			call WaitForRadio.startPeriodic(WAITFORRADIO_PERIOD_MILLI);
			//sendAutoConfigMsg(pwr);
		}
	}

	event void WaitForRadio.fired(){
		sendAutoConfigMsg(ONE_HOP_POWER);
	}

	void createAutoConfigAck(AutoConfigMsg* srcpkt) {
		AutoConfigMsg* ackpkt = (AutoConfigMsg*)(call Packet.getPayload(&pkt, sizeof(AutoConfigMsg)));
		ackpkt->ack = IS_AUTOCONFIGACK;
		ackpkt->srcRank = myRank;
		ackpkt->dstRank = srcpkt->srcRank;
		ackpkt->txPower = srcpkt->txPower;


	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		AutoConfigMsg* acpkt = getAutoConfigPayload(msg);

		if (&pkt == msg)
		{
			radioBusy = FALSE;
			if (err == SUCCESS)
			{
				
				if (acpkt->ack == NOT_AUTOCONFIGACK)
				{
					call WaitAck.startPeriodic(WAITACK_PERIOD_MILLI);
					sentAutoConfig = TRUE;
				}
				
			}
		}

		/* Retransmission if radioBusy */
		if (err == FAIL || err == ECANCEL) {
			if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(AutoConfigMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
			}
		}
	}

	event void WaitAck.fired() {
		attempt +=1;
		if (receivedAck)
		{
			call WaitAck.stop();
			// here is finished
		}
		else if (attempt <= MAX_ATTEMPT) {
			sendAutoConfigMsg(ONE_HOP_POWER);
			call Leds.led2Toggle();
		}
		else if (attempt > MAX_ATTEMPT && attempt <= 2*MAX_ATTEMPT)
		{
			sendAutoConfigMsg(TWO_HOP_POWER);
			call Leds.led0Toggle();

		}
		else {
			call WaitAck.stop();
			neighborsRank[1] = NOT_DEFINED;
		}

	}

	event void Timeout.fired() {
		call AMControl.stop();
	}

	event void AMControl.stopDone(error_t err) {

	}	
}