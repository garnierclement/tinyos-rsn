 #ifndef AUTOCONFIG_H
 #define AUTOCONFIG_H
 
 enum {
 	AM_AUTOCONFIGMSG = 1,
   	TIMER_PERIOD_MILLI = 2000
 };
 
 typedef nx_struct AutoConfigMsg {
 	nx_uint16_t nodeid;
 	nx_uint16_t counter;
 } AutoConfigMsg;

 #endif