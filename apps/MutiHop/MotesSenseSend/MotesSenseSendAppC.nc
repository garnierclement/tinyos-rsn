/**
 *
 *
 **/

#include <Timer.h>
#include "../MotesSense.h"

configuration MotesSenseSendAppC {
}
implementation {
    components MainC;
    components LedsC;
    components MotesSenseSendC as App;
    components new TimerMilliC() as Timer0;
    components ActiveMessageC;
    components new AMSenderC(AM_MOTESSENSEMSG);			// send and receive the same packets
    components new AMReceiverC(AM_MOTESSENSEMSG);

    components PlatformSerialC;
    //components new BufferC(uint8_t, BUF_SIZE);
    components UartLoggerC as Logger;
    //BufferC.Logger -> Logger;

    components  RF230ActiveMessageC as RF230ActiveMessageCRSSI;
    components  RF230ActiveMessageC as RF230ActiveMessageCPower;


    App.PacketRSSI -> RF230ActiveMessageCRSSI.PacketRSSI;
    App.PacketTransmitPower -> RF230ActiveMessageCPower.PacketTransmitPower;

    //App -> RF230ActiveMessageCPower.PacketTransmitPower;

    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.Timer0 -> Timer0;
    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.AMSend -> AMSenderC;
    App.Receive -> AMReceiverC;
    App.AMControl -> ActiveMessageC;
    //App.AMControl -> ActiveMessageC;
    App.UartStream -> PlatformSerialC;
    App.UartControl -> PlatformSerialC;
    //App.Buffer -> BufferC;
    App.Logger -> Logger;
}
