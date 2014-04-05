#include "Rsn.h"

configuration RsnC {

}
implementation {
	components MainC;
	components RsnAppC as App;

	components AutoConfigC;
	components SyncC;
	components ActiveMessageC;

	/* Wiring components */
	App.Boot -> MainC;
	App.AutoConfig -> AutoConfigC.AutoConfig;
	App.GetAutoConfigInfo -> AutoConfigC.GetNodeInfo;
	App.GetSyncInfo -> SyncC.GetNodeInfo;
	App.SetSyncInfo -> SyncC.SetNodeInfo;
	App.Sync -> SyncC.Sync;
	App.AMControl -> ActiveMessageC;
}
