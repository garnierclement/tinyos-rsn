#ifndef AUTOCONFIG_H
#define AUTOCONFIG_H

 
enum {
	AM_AUTOCONFIGMSG = 1,
	TIMEOUT_PERIOD_MILLI = 2000,
	IS_AUTOCONFIGACK = 1,
	NOT_AUTOCONFIGACK = 0
};
 
typedef nx_struct AutoConfigMsg {
 	nx_uint8_t srcRank;
 	nx_uint8_t dstRank;
 	nx_uint8_t txPower;
 	nx_uint8_t ack;
} AutoConfigMsg;

#endif