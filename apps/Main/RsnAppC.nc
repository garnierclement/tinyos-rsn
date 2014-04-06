#include <Timer.h>
#include "Rsn.h"
#include "AutoConfig.h"
#include "Sync.h"

module RsnAppC {

	/* General interfaces */
	uses interface Boot;
	uses interface Leds;
	uses interface SplitControl as AutoConfig;
	uses interface SplitControl as Sync;
	uses interface Get<NodeInfo> as GetAutoConfigInfo;
	uses interface Get<NodeInfo> as GetSyncInfo;
	uses interface Set<NodeInfo> as SetSyncInfo;
	uses interface SplitControl as AMControl;
	uses interface Timer<TMilli> as LedTimer;
}
implementation {

	/* Variables */
	NodeInfo info;

	/* At boot time, start auto configuration algorithm */
	event void Boot.booted() {
		call AMControl.start();
	}

	/* When the radio has started */
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS){
			call AutoConfig.start();	
		}
		else {
			// Restart the radio if it doesn't work
			call AMControl.start();										
		}
	}

	/* When the auto configuration algorithm has ENDED, start the synchronization algorithm */
	event void AutoConfig.startDone(error_t err) {
		if (err == SUCCESS){
			info = call GetAutoConfigInfo.get();
			//call Leds.set(info.neighborsRank[0]);
			call AutoConfig.stop();
		    call SetSyncInfo.set(info);
			call Sync.start();
		}
		else {
			call AutoConfig.start();										
		}
	}

	/* When the synchronization algorithm has ENDED */
	event void Sync.startDone(error_t err) {
		if (err == SUCCESS)
		{
			info = call GetSyncInfo.get(); 
			// ?
		}
		else {
			call Sync.start();
		}
	}

	event void AutoConfig.stopDone(error_t err){

	}

	event void Sync.stopDone(error_t err){

	}

	/* When the radio has shutdown */
	event void AMControl.stopDone(error_t err) {

	}

	/* Timer leds*/
	event void LedTimer.fired() {
		
	}

}