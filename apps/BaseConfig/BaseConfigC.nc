#include <Timer.h>
#include "BaseConfig.h"

module BaseConfigC {
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
	uses interface Random;


	uses interface PacketField<uint8_t> as PacketRSSI;
	uses interface PacketField<uint8_t> as PacketTransmitPower;

}
implementation {

	/* Variables */
	bool radioBusy = FALSE;
  	message_t pkt;
  	uint16_t myRank = IS_BASESTATION;		// Rank of the node
  	uint8_t receivedAck = 0;				// Count the number of Ack received
  	bool sentAutoConfig = FALSE;
  	uint16_t neighborsRank[2]; 				// 0 left (closer to the sink)  1 right
  	uint8_t attempt = 0;					// AutoConfigMsg retransmission attempts
  	uint16_t rssi = 0x0;
  	AutoConfigMsg* acpkt = NULL;			// Reference to received AutoConfig packet
  	uint16_t neighborsTemp[MAX_NEIGHBORS];
  	uint16_t neighborsRssi[MAX_NEIGHBORS];
  	bool isConfigurated = FALSE;

  	/* Functions */
  	void sendAutoConfigMsg(uint8_t pwr);
  	void createAutoConfigMsg(uint8_t pwr);
	AutoConfigMsg* getAutoConfigPayload(message_t* msg);
	uint16_t electWinner();
	void handleAck();
	void sendAutoConfigWin(uint16_t winner);
	void createAutoConfigWin(uint16_t winner);
	void reInit();

	void ledRadioOn();
	void ledWaitAck();
	void ledMaxPower();
	void ledDone();

	/* At boot time, wake up the radio */
	event void Boot.booted() {
		call AMControl.start();	
	}

	/* When the radio has started */
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS){
			ledRadioOn();
			sendAutoConfigMsg(ONE_HOP_POWER);		
			call Timeout.startPeriodic(TIMEOUT_PERIOD_MILLI);
		}
		else {
			// Restart the radio if it doesn't work
			call AMControl.start();										
		}
	}

	/* Send AutoConfigMsg */
	void sendAutoConfigMsg(uint8_t pwr) {
		if (!radioBusy)
		{
			createAutoConfigMsg(pwr);
			call  PacketTransmitPower.set(&pkt,pwr);
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(AutoConfigMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
			}
		} else {
			call WaitForRadio.startPeriodic(WAITFORRADIO_PERIOD_MILLI);
		}
	}

	/* Retransmission if the radio was busy */
	event void WaitForRadio.fired(){
		sendAutoConfigMsg(ONE_HOP_POWER);
	}

	/* Forge an AntoConfigMsg */
	void createAutoConfigMsg(uint8_t pwr) {
		AutoConfigMsg* new_acpkt = (AutoConfigMsg*)(call Packet.getPayload(&pkt, sizeof(AutoConfigMsg)));
		new_acpkt->type = AUTOCONFIGMSG;
		new_acpkt->srcRank = myRank;
		new_acpkt->txPower = pwr;
		new_acpkt->dstRank = (pwr == ONE_HOP_POWER) ? (myRank + ONE_HOP) : (myRank + TWO_HOP);
		new_acpkt->rssi = 0xFFFF; // undefined
	}

	/* When a message was sent*/
	event void AMSend.sendDone(message_t* msg, error_t err) {
		AutoConfigMsg* sentpkt = getAutoConfigPayload(msg);

		if (&pkt == msg)
		{
			radioBusy = FALSE;
			if (err == SUCCESS)
			{
				if (sentpkt->type == AUTOCONFIGMSG)
				{
					call WaitAck.startPeriodic(WAITACK_PERIOD_MILLI);
					ledWaitAck();
					sentAutoConfig = TRUE;
				}	
			}
		}

		/* Retransmission if send failed  */
		if (err == FAIL || err == ECANCEL) {
			if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(AutoConfigMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
			}
		}
	}

	/* Retrieve payload from AutoCOonfigMsg */
	AutoConfigMsg* getAutoConfigPayload(message_t* msg) {
		return (AutoConfigMsg*)(call Packet.getPayload(msg, sizeof(AutoConfigMsg)));
	}

	/* Upon receiving a message */
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(AutoConfigMsg))
    	{
    		// Extract payload
      		if (acpkt != NULL) {
      			free(acpkt);
      			acpkt = NULL;
      		}
    		acpkt = (AutoConfigMsg*)malloc(sizeof(AutoConfigMsg));
    		memcpy(acpkt,payload,sizeof(AutoConfigMsg));

      		// Handle messages
      		switch(acpkt->type){
      			case AUTOCONFIGACK : handleAck();
      				break;
      		}
	    }
    	return msg;
	}

	/* Upon receiving an Ack for a previous sent AutoConfigMsg */
	void handleAck() {
		if (myRank != NOT_DEFINED){
      		if (sentAutoConfig) 
      		{
      			receivedAck+=1;
      			neighborsTemp[receivedAck-1] = acpkt->srcRank;
      			neighborsRssi[receivedAck-1] = acpkt->rssi;
      		}
      	}
      	// ELSE if the node rank not defined, we can overhear broadcasted Ack
      	// No processing from this function is necessary
	}

	/* Retransmission if Ack not received */
	event void WaitAck.fired() {
		attempt +=1;
		if (receivedAck > 0)
		{
			call WaitAck.stop();
			sendAutoConfigWin(electWinner());
			reInit();
			ledDone();
			isConfigurated = TRUE;

			// Here is finished
		}
		else if (attempt <= MAX_ATTEMPT) {
			sendAutoConfigMsg(ONE_HOP_POWER);
		}
		else if (attempt > MAX_ATTEMPT && attempt <= 2*MAX_ATTEMPT)
		{
			sendAutoConfigMsg(TWO_HOP_POWER);
			ledMaxPower();

		}
		else {
			call WaitAck.stop();
			neighborsRank[1] = NOT_DEFINED;
			ledDone();
			isConfigurated = TRUE;

		}
	}

    /* Elect winner and returns its rank */
    uint16_t electWinner() {
    	uint8_t index;
    	uint8_t maxIndex = 0;
    	uint8_t max = 0;
    	for (index = 0; index < receivedAck; index++)
    	{
    		if (neighborsRssi[index] > max)
    		{
    			max = neighborsRssi[index];
    			maxIndex = index;
    		}
    	}
    	return neighborsTemp[maxIndex];
    }

    /* Notify the winner */
    void sendAutoConfigWin(uint16_t winner){
    	neighborsRank[1] = winner;
    	createAutoConfigWin(winner);
    	call  PacketTransmitPower.set(&pkt,acpkt->txPower);
		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(AutoConfigMsg)) == SUCCESS)
		{
			radioBusy = TRUE;
		}
    }

    /* Forge Win message */
	void createAutoConfigWin(uint16_t winner) {
		AutoConfigMsg* winpkt = (AutoConfigMsg*)(call Packet.getPayload(&pkt, sizeof(AutoConfigMsg)));
		winpkt->type = AUTOCONFIGWIN;
		winpkt->srcRank = myRank;
		winpkt->dstRank = winner;	
		winpkt->txPower = acpkt->txPower;
		winpkt->rssi = 0xFFFF;	// Undefined
	}

	/* Reinit values */
	void reInit() {
		uint8_t i = 0;
		for (i = 0; i < receivedAck; ++i)
		{
			neighborsRssi[i] = 0;
			neighborsTemp[i] = 0;
		}
		receivedAck = 0;
		attempt = 0;
		acpkt = NULL;
	}

	/* Shutdown the radio if inactivity*/
	event void Timeout.fired() {
		call AMControl.stop();
	}

	/* When the radio has shutdown */
	event void AMControl.stopDone(error_t err) {

	}

	void ledRadioOn(){ call Leds.set(4); }
	void ledWaitAck(){ call Leds.set(1); }
	void ledMaxPower(){ call Leds.set(7); }
	void ledDone(){ call Leds.set(2); }

}