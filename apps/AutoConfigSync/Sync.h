#ifndef SYNC_H
#define SYNC_H


enum{
	/* AM type for synchronization algorithm */
	AM_SYNC = 2,

};

typedef nx_struct SyncMsg{
 	nx_uint16_t srcRank;
 	nx_uint16_t dstRank;
 	nx_uint16_t sender;		// can be the base station (0) or the last node of the linear network
} SyncMsg;

#endif

