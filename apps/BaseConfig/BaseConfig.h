#ifndef BASECONFIG_H
#define BASECONFIG_H

 
enum {
	/* AM type for AutoCOnfi algorithm */
	AM_AUTOCONFIGMSG = 1,
	/* Timers */
	TIMEOUT_PERIOD_MILLI = 120000,
	WAITACK_PERIOD_MILLI = 1000,
	WAITFORRADIO_PERIOD_MILLI = 1000,
	/* Message type */
	AUTOCONFIGMSG = 0,
	AUTOCONFIGACK = 1,
	AUTOCONFIGWIN = 2,
	/* Rank id forbase station */
	IS_BASESTATION = 0,
	/* Distance between nodes */
	ONE_HOP = 1,
	TWO_HOP = 2,
	/* TX power */
	ONE_HOP_POWER = 0x0f,
	TWO_HOP_POWER = 0x05,
	/* Rank for unranked nodes */
	NOT_DEFINED = 255,
	/* Maximum attempts of retransmission at a specific TX power */
	MAX_ATTEMPT = 10,
	/* Backoff multiplicator for Ack answer */
	BACKOFF_COEFF = 10,
	/* Maximum number of neighbors in one hop communication range */
	MAX_NEIGHBORS = 10
};
 
typedef nx_struct AutoConfigMsg {
 	nx_uint16_t srcRank;
 	nx_uint16_t dstRank;
 	nx_uint8_t txPower;
 	nx_uint8_t type;
 	nx_uint16_t rssi;
} AutoConfigMsg;

#endif