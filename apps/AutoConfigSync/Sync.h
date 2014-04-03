#ifndef SYNC_H
#define SYNC_H


enum{
	/* AM type for synchronization algorithm */
	AM_SYNC = 2,

};

typedef nx_struct SyncMsg{
 	nx_uint16_t srcRank;
 	nx_uint16_t dstRank;
 	nx_uint16_t lastNodeRank;
} SyncMsg;

#endif

