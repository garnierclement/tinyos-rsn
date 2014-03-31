/*
 *
 *
 */

#include <Timer.h>
//#include <avr/wdt.h>
#include "../MotesSense.h"
module MotesSenseSendC {
    uses interface Boot;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer0;
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface Receive;
    uses interface SplitControl as AMControl;

    uses interface PacketField<uint8_t> as PacketRSSI;
    uses interface PacketField<uint8_t> as  PacketTransmitPower;

    uses interface UartStream;
    uses interface StdControl as UartControl;

    //uses interface Buffer<uint8_t>;
    uses interface UartLogger as Logger;
}
implementation {
    uint16_t counter=0;
    
	//uint16_t array_counter = 0;
	
   //int16_t valueRSSI;

    MotesSenseMsg* sendmsg;			// relay  MotesSenseMsg

    bool RSSI = FALSE;
    message_t pkt;
    
	
	message_t ppp[PACKET_BUFF_SIZE];
	uint8_t curIndex = 0;			// for new received packet
	uint8_t pastIndex = 0;			// for past received packet
	
	
	
	
    int16_t message_counter = 0;
    bool busy = FALSE;

    bool radiobusy = FALSE;
    uint8_t uartbuf [UART_BUF_SIZE];
    uint16_t uartlen = UART_BUF_SIZE;
    bool uarttask = FALSE;

 /*   uint8_t radiobuf [RADIO_BUF_SIZE];
    uint16_t radiolen = RADIO_BUF_SIZE;
    bool radiotask = FALSE;
*/
    void clearBuf(uint8_t* buf, uint16_t len);
    void copyRadioBuf();
    task void sendToRadio();
    void sendToUart();

/*      task void getRadioFromBuffer() {
        uint16_t got, aidx;
        char logs[128];
        atomic
        if (!radiotask) {
            radiotask = TRUE;
            radiolen = RADIO_BUF_SIZE;
            dbg("MotesSenseSendC", "Task radio begin[radiolen:%d]\n", radiolen);
            clearBuf(radiobuf, RADIO_BUF_SIZE);
            dbg("MotesSenseSendC", "radio buf cleared\n");
            if (call Buffer.size() >= radiolen) {
                if (call Buffer.dataAt(radiolen - 1) == '*') {
                    call Logger.log("Got good data.\n");
                    radiolen = call Buffer.get(radiobuf, 0, radiolen);
                    sendToRadio();
                } else {
                    if (call Buffer.find((uint8_t)'*', &aidx)) {
                        call Buffer.clear(aidx + 1);
                    } else {
                        call Buffer.clearAll();
                    }
                    post getRadioFromBuffer();
                }
            } else {

            }
            radiotask = FALSE;
        }
    }*/

    void putUartToBuffer() {
        uint16_t sent;
        atomic
        if (!uarttask) {
            uarttask = TRUE;
            dbg("MotesSenseSendC", "Task uart begin[uartlen:%d]\n", uartlen);
    //        sent = call Buffer.put(uartbuf, 0, uartlen);
      //      dbg("MotesSenseSendC", "Task uart sent buffer[sent:%d]\n", sent);
    //        if (sent == 0)
      //          call Buffer.clearAll();
        //    else
     //           post getRadioFromBuffer();
            clearBuf(uartbuf, UART_BUF_SIZE);
            dbg("MotesSenseSendC", "uart buf cleared\n");
            uartlen = UART_BUF_SIZE;
            if (call UartStream.receive(uartbuf, UART_BUF_SIZE) != SUCCESS) {
                putUartToBuffer();
            }
            uarttask = FALSE;
        }
    }
    task void go() {
        putUartToBuffer();
    }

    async event void UartStream.receivedByte(uint8_t byte) {
    }

    async event void UartStream.receiveDone(uint8_t* buf, uint16_t len, error_t error) {
        dbg("MotesSenseSendC", "Task uart received.\n");
        call Leds.led1Toggle();
        if (error == SUCCESS)
            uartlen = len ;
        else
            uartlen = 0;
        post sendToRadio();
        //post putUartToBuffer();
    }

    async event void UartStream.sendDone(uint8_t* buf, uint16_t len, error_t error) {
		 //call Leds.led2Toggle();
    }

    void clearBuf(uint8_t* buf, uint16_t len) {
        uint16_t i ;
        for (i = 0; i < len; ++i) {
            buf[i] = 0;
        }
    }

    void copyRadioBuf() {
        int i;
        MotesSenseMsg* mspkt;
        dbg("MotesSenseSendC", "Task radio buffer copy[uartlen:%d]\n", uartlen);
        mspkt = (MotesSenseMsg*) (call Packet.getPayload(&pkt, sizeof(MotesSenseMsg)));
		
        for (i = 0; i < uartlen-6; i++)  // because i use 6 bytes for flags and jump ...
            mspkt->msg[i] = uartbuf[i];
			
			mspkt->nodeid = TOS_NODE_ID;
			mspkt->counter = counter++;
			
			mspkt->jump = 0;
			mspkt->oldId = 0;
			mspkt->oldCounter = 0;

    }

	// 
	// read from 9DOF ,  send by radio
	//
    task void sendToRadio() {
        dbg("MotesSenseSendC", "Task radio begin[radiolen:%d]\n", radiolen);
        if (!radiobusy) {
            copyRadioBuf();
	    call  PacketTransmitPower.set(&pkt,0xff);
            if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MotesSenseMsg)) == SUCCESS) {  
                dbg("MotesSenseSendC", "Task radio send SUCCESS\n");
                radiobusy = TRUE;
            } else {
            }
        }
    }

    void sendToUart() {
    }

    event void Boot.booted() {
        call Leds.set(7);
        call AMControl.start();
    }

    event void Timer0.fired() {
    }

    event void AMControl.startDone(error_t err) {
          if (err == SUCCESS) {
            dbg("MotesSenseSendC", "AMControl started.\m");
            call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
            if (call UartControl.start() == SUCCESS) {
                dbg("MotesSenseSendC", "UartControl started.\m");
                atomic {
                    call Leds.set(0);
                    uartlen = 0;
                    post go();
                    //post putUartToBuffer();
                }
            } else {
                dbgerror("MotesSenseSendC", "UartControl start FAIL.\m");
            }
        } else {
            dbgerror("MotesSenseSendC", "AMControl start FAIL.\m");
            call AMControl.start();
        }

    }

    event void AMControl.stopDone(error_t err) {
    }





    /****RSSI*****/


    task void SendRidio()
    {
	//message_counter--;   AM_BROADCAST_ADDR
		atomic{
			if( !busy && (pastIndex != curIndex) )
			{
				if (call AMSend.send(AM_BROADCAST_ADDR, &ppp[pastIndex] , sizeof(MotesSenseMsg)) == SUCCESS) {
						busy = TRUE;
						pastIndex = (pastIndex+1) % PACKET_BUFF_SIZE;
				}
			 
			}
		}
	}

    int16_t getRssi(message_t *msg){
    if(call PacketRSSI.isSet(msg))
      return (int16_t) call PacketRSSI.get(msg);
    else
      return 0xFFFF;
    }


	//
	// when receive the Broadcasting packets
	//
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
	
		uint8_t i = 0;
	
        if (len == sizeof(MotesSenseMsg)) {
		
            MotesSenseMsg* rcvmsg = (MotesSenseMsg*)payload;
			
			if ( ( TOS_NODE_ID != rcvmsg->nodeid ) && ( TOS_NODE_ID != rcvmsg->oldId ) ) { // I ignore which i sent!!
			
				// BLINK!
				call Leds.led0Toggle();
									
					
				sendmsg =(MotesSenseMsg*)(call Packet.getPayload(&ppp[curIndex], sizeof(MotesSenseMsg)));
				
				if ( (curIndex+1)% PACKET_BUFF_SIZE != pastIndex )
					curIndex = (curIndex + 1) % PACKET_BUFF_SIZE ;	
				
				if (sendmsg == NULL) {
					return NULL;
				}
				
				if ( (rcvmsg->counter != 0xFFFF) &&  ( rcvmsg->jump == 0 ) && ( rcvmsg->oldId == 0 ) && ( rcvmsg->oldCounter == 0 ) ){ // i receive a fresh packet!!
				
					atomic {
						sendmsg->nodeid = TOS_NODE_ID;		// it is sent by me!!!
						sendmsg->counter = 0xFFFF;				// resend packet flag!!
						
						sendmsg->jump = 3;
						sendmsg->oldId = rcvmsg->nodeid;
						sendmsg->oldCounter = rcvmsg->counter;
						
						for ( i=0; i < RADIO_BUF_SIZE ; i++ ){
							sendmsg->msg[i] = rcvmsg->msg[i];
						}
					}
					
					post SendRidio();	
					
				} else if ( ( rcvmsg->counter == 0xFFFF) && ( rcvmsg->jump > 0) ) { // i got a relay packet and i need to send too
				
					atomic {
						sendmsg->nodeid = TOS_NODE_ID;		// it is sent by me!!!
						sendmsg->counter = 0xFFFF;				// resend packet flag!!
						
						sendmsg->jump = rcvmsg->jump - 1;	// it jump!
						sendmsg->oldId = rcvmsg->oldId;
						sendmsg->oldCounter = rcvmsg->oldCounter;
						
						for ( i=0; i < RADIO_BUF_SIZE ; i++ ){
							sendmsg->msg[i] = rcvmsg->msg[i];
						}
					}
					
					post SendRidio();	
				
				}
			
			}
   
        }
        return msg;
    }


    event void AMSend.sendDone(message_t* msg, error_t err) {
	
        if(&pkt == msg) {
		
	    dbg("MotesSenseSendC", "Task radio sent.\n");
            atomic {
                radiobusy = FALSE;
            }
            call Leds.led2Toggle();
            putUartToBuffer();
        }else{
		
		 busy = FALSE;
		}
    }
}
