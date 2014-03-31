#ifndef MOTESSENSESEND_H
#define MOTESSENSESEND_H

#include <AM.h>

enum {
    TIMER_PERIOD_MILLI = 250,
    AM_MOTESSENSEMSG = 6,
    AM_NODECENTRAL = 6,// The type of the AM
    BUF_SIZE = 72,       // The size of the buffer between serial com and radio com
    UART_BUF_SIZE = 24,
    //RADIO_BUF_SIZE = 24,
	RADIO_BUF_SIZE = 18,
	ARRAY_SIZE = 4,
	PACKET_BUFF_SIZE = 128
};

typedef nx_struct MotesSenseMsg {
	nx_uint16_t nodeid;
    nx_uint16_t counter;
    nx_uint16_t jump;
    nx_uint16_t oldId;
    nx_uint16_t oldCounter;
    nx_uint8_t msg [RADIO_BUF_SIZE]; 
} MotesSenseMsg;

/*
typedef nx_struct RelayMsg {
  nx_uint16_t nodeid[ARRAY_SIZE];
  nx_uint16_t counter[ARRAY_SIZE];
  nx_int16_t RSSI[ARRAY_SIZE];

  nx_uint16_t nodeid;
  nx_uint16_t counter;
  nx_int16_t RSSI;
} RelayMsg;*/

#endif


