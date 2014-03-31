/*
 *
 *
 */

#include<stdio.h>

generic module BufferC(typedef buf_t, uint16_t BUFFER_SIZE) {
    provides interface Buffer<buf_t>;
    uses interface UartLogger as Logger;
}
implementation {
    buf_t buffer[BUFFER_SIZE];
    uint8_t head = 0; // The index of the first data which will be get out of the buffer.
    uint8_t tail = 0; // The index of the first data which will be put into the buffer.
    uint8_t size = 0; // The size of the data in the buffer.

    uint16_t nextIdx(uint16_t curIdx) {
        uint16_t nidx;
        nidx = (curIdx + 1) % BUFFER_SIZE;
        return nidx;
    }

    bool isValidIdx(uint16_t idx) {
        return (idx - head) % BUFFER_SIZE < size;
    }

    command bool Buffer.empty() {
        return size == 0;
    }

    command uint16_t Buffer.size() {
        return size;
    }

    command uint16_t Buffer.maxSize() {
        return BUFFER_SIZE;
    }

    command uint16_t Buffer.get(buf_t* dst, uint16_t off, uint16_t len) {
        uint16_t idx = 0, bufi;
        dbg("BufferC", "Get request[type:%s][off:%d][len:%d]\n", typeid(dst).name(), off, len);
        for (bufi = head; isValidIdx(bufi) && idx < len; bufi = nextIdx(bufi)) {
            dst[idx + off] = buffer[bufi];
            idx++;
        }
        head = bufi;
        size -= idx;
        dbg("BufferC", "Get end[got:%d][head:%d][tail:%d][size:%d]\n", idx, head, tail, size);
        return idx;

    }

    command uint16_t Buffer.put(buf_t* src, uint16_t off, uint16_t len) {
        uint16_t idx = 0, bufi;
        dbg("BufferC", "Put request[type:%s][off:%d][len:%d]\n", typeid(src).name(), off, len);
        for (bufi = tail; bufi < BUFFER_SIZE && !isValidIdx(bufi) && idx < len; bufi = nextIdx(bufi)) {
            buffer[bufi] = src[idx + off];
            idx++;
        }
        tail = bufi;
        size += idx;
        dbg("BufferC", "Put end[put:%d][head:%d][tail:%d][size:%d]\n", idx, head, tail, size);
        return idx;
    }

    command buf_t Buffer.dataAt(uint16_t idx) {
        return buffer[(idx + head) % BUFFER_SIZE];
    }

    command bool Buffer.find(buf_t a, uint16_t* aidx) {
        uint16_t idx = 0, bufi, i;
        uint8_t tsize = (uint8_t)sizeof(buf_t);
        bool found = FALSE;
        uint8_t *tempbuf, *tempa;
        char logs [128];
        //char logc [128];
        tempbuf = (uint8_t *)buffer;
        tempa = (uint8_t *)(&a);
        for (bufi = head; isValidIdx(bufi); bufi = nextIdx(bufi)) {
            found = tsize > 0;
            for (i = 0; i < tsize && found; i++) {
                found = found && (tempbuf[bufi * tsize + i] == tempa[i]);
            }
            if (found) {
                *aidx = idx;
                break;
            }
            idx++;
        }
        sprintf(logs, "%d, find %x at %d, tsize: %d, size: %d, head: %d, tail: %d\n", found, *tempa, idx, tsize, size, head, tail);
        call Logger.log(logs);
/*
        idx = 0;
        for (bufi = head; isValidIdx(bufi); bufi = nextIdx(bufi)) {
            sprintf(logc + (3 * idx), "%2x ", buffer[bufi]);
            idx++;
        }
        call Logger.log(logc);*/
        return found;
    }

    command void Buffer.clearAll() {
        head = 0;
        tail = 0;
        size = 0;
        call Logger.log("ClearAll.\n");
    }

    command void Buffer.clear(uint16_t len) {
        char logs[16];
        if (len > size)
            len = size;
        head += len;
        size -= len;
        sprintf(logs, "Clear %d\n", len);
        call Logger.log(logs);
    }
}
