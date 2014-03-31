#include <Timer.h>
#include "AutoConfig.h"

configuration AutoConfigAppC {
}
implementation {
	components MainC;
	components AutoConfigC as App;

	App.Boot -> MainC;

}