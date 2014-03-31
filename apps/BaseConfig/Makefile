COMPONENT=BaseConfigAppC
BUILD_EXTRA_DEPS=AutoConfigMsg.class

BaseConfigMsg.class: AutoConfigMsg.java
	javac AutoConfigMsg.java

BaseConfigMsg.java:
	mig java -target=null  -java-classname=AutoConfigMsg BaseConfig.h AutoConfigMsg -o $@

include $(MAKERULES)