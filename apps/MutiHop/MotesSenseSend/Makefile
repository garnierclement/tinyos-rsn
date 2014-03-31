COMPONENT=MotesSenseSendAppC
CFLAGS += -I$(TOSDIR)/lib/printf
BUILD_EXTRA_DEPS += MotesSenseMsg.class
MotesSenseMsg.class: MotesSenseMsg.java
	javac MotesSenseMsg.java
MotesSenseMsg.java:
	mig java -target=null -java-classname=MotesSenseMsg ../MotesSense.h MotesSenseMsg -o $@
include $(MAKERULES)

