//#include <Timer.h>
//#include "../MotesSense.h"
module MotesSenseSendC {
    uses interface Boot;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer0;
    uses interface Timer<TMilli> as Timer1;
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface SplitControl as AMControl;

    uses interface UartStream;
    uses interface StdControl as UartControl;
}
implementation {
    bool radiobusy = FALSE;
    message_t pkt;
    uint8_t uartbuf [BUF_SIZE];
    bool uarttask = FALSE;

    void clearBuf(uint8_t* buf);
    void sendToRadio(uint8_t* buf, uint16_t len);

    void putUartToBuffer() {
        uint16_t sent;
        if (!uarttask) {
            uarttask = TRUE;
            clearBuf(uartbuf);
            dbg("MotesSenseSendC", "uart buf cleaned\n");
            call Leds.led1Toggle();
            if (call UartStream.receive(uartbuf, BUF_SIZE) != SUCCESS) {
                call Timer1.startOneShot(200);
                call Leds.led1Toggle();
            }
            uarttask = FALSE;
        }
    }

    event void Boot.booted() {
        call Leds.set(7);
        call AMControl.start();
    }

    event void Timer0.fired() {
        call Leds.led0Toggle();
    }

    event void Timer1.fired() {
       putUartToBuffer();
    }

    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            dbg("MotesSenseSendC", "AMControl started.\m");
            call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
            if (call UartControl.start() == SUCCESS) {
                dbg("MotesSenseSendC", "UartControl started.\m");
                call Leds.set(0);
                call Timer1.startOneShot(200);
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

    event void AMSend.sendDone(message_t* msg, error_t error) {
        radiobusy = FALSE;
    }

    async event void UartStream.receivedByte(uint8_t byte) {
    }

    async event void UartStream.receiveDone(uint8_t* buf, uint16_t len, error_t error) {
        uint16_t left;
        dbg("MotesSenseSendC", "Task uart received.\n");
        call Leds.led1Toggle();
        if (error == SUCCESS)
            sendToRadio(buf, len);
        else
            call Leds.led2Toggle();
        call Timer1.startOneShot(200);
    }

    async event void UartStream.sendDone(uint8_t* buf, uint16_t len, error_t error) {
    }

    void clearBuf(uint8_t* buf) {
        uint16_t i ;
        for (i = 0; i < BUF_SIZE; ++i) {
            buf[i] = 0;
        }
    }

    void sendToRadio(uint8_t* buf, uint16_t len) {
        int i;
        dbg("MotesSenseSendC", "Task radio begin[radiooff:%d][radiolen:%d]\n", radiooff, radiolen);
        if (!radiobusy) {
            MotesSenseMsg* mspkt = (MotesSenseMsg*) (call Packet.getPayload(&pkt, (uint8_t)sizeof(MotesSenseMsg)));
            mspkt->nodeid = TOS_NODE_ID;
            mspkt->msglength = len;
            for (i = 0; i < mspkt->msglength; i++)
                mspkt->msg[i] = buf[i];
            if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MotesSenseMsg)) == SUCCESS) {
                dbg("MotesSenseSendC", "Task radio send SUCCESS\n");
                call Leds.led2Toggle();
                radiobusy = TRUE;
            } else {
                dbgerror("MotesSenseSendC", "Task radio send FAIL\n");
                //post getRadioFromBuffer();
            }
        }
    }


}
