#ifndef AUTOCONFIG_H
#define AUTOCONFIG_H

 
enum {
	AM_AUTOCONFIGMSG = 1,
	TIMEOUT_PERIOD_MILLI = 2000
};
 
typedef nx_struct AutoConfigMsg {
 	nx_uint8_t srcRank;
 	nx_uint8_t dstRank;
 	nx_uint8_t txPower;
} AutoConfigMsg;

#endif