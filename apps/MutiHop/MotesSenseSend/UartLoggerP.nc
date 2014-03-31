/*
 *
 *
 */

#include <string.h>
#include "UartLogger.h"
module UartLoggerP {
    provides interface UartLogger;
#ifdef UARTLOGGER
    uses interface StdControl as UartControl;
    uses interface UartStream;
    uses interface Buffer<uint8_t>;
#endif
}
implementation {
#ifdef UARTLOGGER
    bool uartOn = FALSE;
    uint8_t logbuf [LOG_BUF_SIZE];

    task void sendLog() {
        uint16_t got = 0;
        got = call Buffer.get(logbuf, 0, LOG_BUF_SIZE);
        if (call UartStream.send(logbuf, got) != SUCCESS)
            post sendLog();
    }
#endif

    command void UartLogger.log(const char *msg) {
#ifdef UARTLOGGER
        if (uartOn == FALSE && call UartControl.start() == SUCCESS) {
            uartOn = TRUE;
        }
        call Buffer.put((uint8_t *)msg, 0, strlen(msg));
        post sendLog();
        //call UartStream.send((uint8_t *)msg, strlen(msg));
#endif
    }

#ifdef UARTLOGGER
    async event void UartStream.receivedByte(uint8_t byte) {
    }

    async event void UartStream.receiveDone(uint8_t* buf, uint16_t len, error_t error) {
    }

    async event void UartStream.sendDone(uint8_t* buf, uint16_t len, error_t error) {
        if (error != SUCCESS || (error == SUCCESS && call Buffer.size() > 0))
            post sendLog();
    }
#endif
}
