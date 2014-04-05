#ifndef RSN_H
#define RSN_H

enum {
	/* Maximum payload size in bytes */
	TOSH_DATA_LENGTH = 128,
	/* Rank id forbase station */
	IS_BASESTATION = 0
};

typedef struct NodeInfo{
	uint16_t myRank;
	uint16_t neighborsRank[2];
	bool lastNode;
	uint32_t localTime;
} NodeInfo;

#endif RSN_H