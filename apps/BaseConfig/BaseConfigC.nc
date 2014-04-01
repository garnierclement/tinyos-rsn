#include <Timer.h>
#include "BaseConfig.h"

module BaseConfigC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timeout;
	uses interface Timer<TMilli> as WaitAck;
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
  	uint8_t myRank = 0;
  	bool receivedAck = FALSE;
  	bool sentAutoConfig = FALSE;
  	uint8_t neighborsRank[2]; // 0 left 1 right
  	uint8_t attempt = 0;

  	/* Functions */
  	void createAutoConfigMsg(uint8_t pwr);
  	void handleAck(AutoConfigMsg* ackpkt);
	void sendAutoConfigMsg(uint8_t pwr);
	AutoConfigMsg* getAutoConfigPayload(message_t* msg);


	event void Boot.booted() {
		call AMControl.start();
		call Leds.led0On();	
	
										// Wakes up radio
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS)
		{
			sendAutoConfigMsg(ONE_HOP_POWER);
		}
		else {
			call AMControl.start();										// Restart the radio if it doesn't work
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(AutoConfigMsg))
    	{
      		AutoConfigMsg* acpkt = (AutoConfigMsg*)payload;
      		/* Check if the received message is an Ack and handle it */
      		handleAck(acpkt);
     

	    }
    	return msg;
	}

	void handleAck(AutoConfigMsg* ackpkt) {
		if (myRank != NOT_DEFINED && ackpkt->srcRank > myRank){
      		if (sentAutoConfig && !receivedAck) 
      		{
      			receivedAck = TRUE;
      			neighborsRank[1] = ackpkt->srcRank;
      			call Leds.led2On();
      		}
      	}

	}


	AutoConfigMsg* getAutoConfigPayload(message_t* msg) {
		return (AutoConfigMsg*)(call Packet.getPayload(msg, sizeof(AutoConfigMsg)));
	}

	void createAutoConfigMsg(uint8_t pwr) {
		AutoConfigMsg* acpkt = (AutoConfigMsg*)(call Packet.getPayload(&pkt, sizeof(AutoConfigMsg)));
		acpkt->ack = NOT_AUTOCONFIGACK;
		acpkt->srcRank = myRank;
		acpkt->txPower = pwr;
		acpkt->dstRank = (pwr == ONE_HOP_POWER) ? (myRank + ONE_HOP) : (myRank + TWO_HOP);
	}

	void sendAutoConfigMsg(uint8_t pwr) {
		if (!radioBusy)
		{
			createAutoConfigMsg(pwr);
			call  PacketTransmitPower.set(&pkt,pwr);
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(AutoConfigMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
				call Leds.led1On();

			}
		}
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
			call Leds.led2Toggle();

		}
		else {
			call WaitAck.stop();
			neighborsRank[1] = NOT_DEFINED;
			call Leds.led1Toggle();
		}

	}

	event void Timeout.fired() {
		call AMControl.stop();
	}

	event void AMControl.stopDone(error_t err) {

	}	
}