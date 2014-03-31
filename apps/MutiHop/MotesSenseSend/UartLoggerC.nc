/*
 *
 *
 */

#include "UartLogger.h"

configuration UartLoggerC {
    provides interface UartLogger;
}
implementation {
    components UartLoggerP;
#ifdef UARTLOGGER
    components new BufferC(uint8_t, LOG_BUF_SIZE);
    components PlatformSerialC;
#endif

    UartLogger = UartLoggerP;
#ifdef UARTLOGGER
    UartLoggerP.Buffer -> BufferC;
    UartLoggerP.UartStream -> PlatformSerialC;
    UartLoggerP.UartControl -> PlatformSerialC;
    BufferC.Logger -> UartLoggerP;
#endif
}

