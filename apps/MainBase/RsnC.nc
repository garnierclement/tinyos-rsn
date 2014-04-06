#include "Rsn.h"

configuration RsnC {

}
implementation {
	components MainC;
	components RsnAppC as App;

	components AutoConfigBaseC;
	components SyncC;
	components ActiveMessageC;
	components new TimerMilliC() as LedTimer;
	components LedsC;


	/* Wiring components */
	App.Boot -> MainC;
	App.AutoConfig -> AutoConfigBaseC.AutoConfig;
	App.GetAutoConfigInfo -> AutoConfigBaseC.GetNodeInfo;
	App.GetSyncInfo -> SyncC.GetNodeInfo;
	App.SetSyncInfo -> SyncC.SetNodeInfo;
	App.Sync -> SyncC.Sync;
	App.AMControl -> ActiveMessageC;
	App.LedTimer -> LedTimer;
	App.Leds -> LedsC;
}
