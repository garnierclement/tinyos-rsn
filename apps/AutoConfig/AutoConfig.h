#ifndef AUTOCONFIG_H
#define AUTOCONFIG_H

 
 enum {
 	AM_AUTOCONFIGMSG = 1
 };
 
 typedef nx_struct AutoConfigMsg {
 	nx_uint8_t srcRank;
 	nx_uint8_t dstRank;
 } AutoConfigMsg;

#endif