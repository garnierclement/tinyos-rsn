#include <Timer.h>
#include "AutoConfigBase.h"
#include "Sync.h"

module AutoConfigBaseM {
	provides {
		interface SplitControl as AutoConfig;
		interface Get<NodeInfo> as GetNodeInfo;
	}
	uses {
		interface Leds;
		//uses interface SplitControl as AMControl;
		interface Timer<TMilli> as WaitAck;
		interface Timer<TMilli> as WaitForRadio;
		interface Packet as Packet;
		interface AMPacket as AMPacket;
		interface AMSend as AMSend;
		interface Receive as Receive;
		interface Random;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint8_t> as PacketTransmitPower;
	}
}
implementation {

	/* Variables */
	bool radioBusy = FALSE;
  	message_t pkt;
  	uint16_t myRank = IS_BASESTATION;			// Rank of the node
  	uint8_t receivedAck = 0;				// Count the number of Ack received
  	bool sentAutoConfig = FALSE;
  	uint16_t neighborsRank[2]; 				// 0 left (closer to the sink)  1 right
  	uint8_t attempt = 0;					// AutoConfigMsg retransmission attempts
  	AutoConfigMsg* acpkt = NULL;			// Reference to the last received AutoConfig packet
  	uint16_t neighborsTemp[MAX_NEIGHBORS];
  	uint16_t neighborsRssi[MAX_NEIGHBORS];
  	bool isConfigurated = FALSE;
  	bool lastNode = FALSE;
  	uint16_t nodeCount = 0;					// Numeber of nodes in the network (including BS)

  	/* Functions */
  	void createAutoConfigMsg(uint8_t pwr);
  	void handleAck();
	void sendAutoConfigMsg(uint8_t pwr);
	AutoConfigMsg* getAutoConfigPayload(message_t* msg);
	uint16_t electWinner();
	void sendAutoConfigWin(uint16_t winner);
	void createAutoConfigWin(uint16_t winner);
	void reInit();
	void handleDone(AutoConfigMsg* donepkt);

	void ledRadioOn();
	void ledSendAck();
	void ledIsWinner();
	void ledIsLoser();
	void ledWaitAck();
	void ledMaxPower();
	void ledDone();
	void ledAutoConfigDone();
	void ledSet(uint8_t value);



	command error_t AutoConfig.start() {
		// Wait for AutoConfigMsg
		ledRadioOn();
		sendAutoConfigMsg(ONE_HOP_POWER);
		return SUCCESS;
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
		new_acpkt->data = 0xFFFF; // undefined
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

      		//acpkt = (AutoConfigMsg*)payload;
      		// Handle messages
      		switch(acpkt->type){
      			case AUTOCONFIGACK : handleAck();
      				break;
      			case AUTOCONFIGDONE : handleDone((AutoConfigMsg*)payload);
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
      			neighborsRssi[receivedAck-1] = acpkt->data;
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
			// Base station is alone
			call WaitAck.stop();
			neighborsRank[1] = NOT_DEFINED;
			ledDone();
			isConfigurated = TRUE;
			lastNode = TRUE;
			signal AutoConfig.startDone(SUCCESS);

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
    	neighborsRank[1] = (acpkt->txPower == ONE_HOP_POWER)? myRank+1 : myRank+2;
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
		winpkt->data = 0xFFFF;	// Undefined
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
		if (acpkt != NULL) {
      		free(acpkt);
      		acpkt = NULL;
      	}
	}

	/* Handle Done message */
	void handleDone(AutoConfigMsg* donepkt) {
		if (!lastNode && donepkt->dstRank == myRank)
		{
			nodeCount = donepkt->data + 1;
			ledSet(neighborsRank[1]);
			signal AutoConfig.startDone(SUCCESS);
		}
	}

	void ledRadioOn(){ call Leds.set(4); }
	void ledSendAck(){ call Leds.set(6); }
	void ledIsWinner(){ call Leds.set(0); } // former value = 3
	void ledIsLoser(){ call Leds.set(5); }
	void ledWaitAck(){ call Leds.set(1); }
	void ledMaxPower(){ call Leds.set(7); }
	void ledDone(){ call Leds.set(2); }
	void ledAutoConfigDone(){ call Leds.set(0); }
	void ledSet(uint8_t value){ call Leds.set(value);}


	command NodeInfo GetNodeInfo.get() {
		NodeInfo info;
		info.myRank = myRank;
		info.neighborsRank[0] = neighborsRank[0];
		info.neighborsRank[1] = neighborsRank[1];
		info.lastNode = lastNode;
		return info;
	}

	command error_t AutoConfig.stop(){
		signal AutoConfig.stopDone(SUCCESS);
		return SUCCESS;
	}

}