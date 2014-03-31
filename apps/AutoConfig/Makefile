COMPONENT=AutoConfigAppC
BUILD_EXTRA_DEPS=AutoConfigMsg.class

BlinkToRadioMsg.class: AutoConfigMsg.java
	javac AutoConfigMsg.java

BlinkToRadioMsg.java:
	mig java -target=null  -java-classname=AutoConfigMsg AutoConfig.h AutoConfigMsg -o $@

include $(MAKERULES)