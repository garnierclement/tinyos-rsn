#ifndef AUTOCONFIG_H
#define AUTOCONFIG_H

 
enum {
	AM_AUTOCONFIGMSG = 1,
	TIMEOUT_PERIOD_MILLI = 120000,
	WAITACK_PERIOD_MILLI = 1000,
	WAITFORRADIO_PERIOD_MILLI = 1000,
	IS_AUTOCONFIGACK = 1,
	NOT_AUTOCONFIGACK = 0,
	IS_BASESTATION = 0,
	ONE_HOP = 1,
	TWO_HOP = 2,
	ONE_HOP_POWER = 0x0F,
	TWO_HOP_POWER = 0x05,
	NOT_DEFINED = 255,
	MAX_ATTEMPT = 10
};
 
typedef nx_struct AutoConfigMsg {
 	nx_uint8_t srcRank;
 	nx_uint8_t dstRank;
 	nx_uint8_t txPower;
 	nx_uint8_t ack;
} AutoConfigMsg;

#endif