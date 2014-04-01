// $Id: RadioCountToLedsC.nc,v 1.7 2010-06-29 22:07:17 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
 
#include "Timer.h"
#include "RadioCountToLeds.h"
 
/**
 * Implementation of the RadioCountToLeds application. RadioCountToLeds 
 * maintains a 4Hz counter, broadcasting its value in an AM packet 
 * every time it gets updated. A RadioCountToLeds node that hears a counter 
 * displays the bottom three bits on its LEDs. This application is a useful 
 * test to show that basic AM communication and timers work.
 *
 * @author Philip Levis
 * @date   June 6 2005
 */

module RadioCountToLedsC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as SensorTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface PacketAcknowledgements;
    interface AMPacket;
    //interface LocalTime as Time;
  }
}
implementation {


  bool useacks = FALSE;
  message_t packet;
  message_t startPacket;
  uint16_t packageSize = 400;
  uint16_t bufferSize;
  nx_uint8_t *bufferPointer;
  nx_uint8_t *receiving;
  uint16_t packagesSent; //= counter
  uint16_t attempts;
  uint16_t maxAttempts = 5;
  rcv_buffer_t rcv_buffers[10]; 
  
  bool locked;
  uint16_t receiverAddress = ID_OF_GATEWAY; //always send directly to the gateway
  
  event void Boot.booted() {
    dbg("Boot,WSN_Project", "Application booted.\n");
    printf("Boot,WSN_Project: Application booted with TOS_NODE_ID = %d.\n", TOS_NODE_ID);
    call AMControl.start();
    dbg("WSN_Project_DEBUG", "MAX_BUFFER_SIZE: '%d'.\n",MAX_BUFFER_SIZE);
  }

  event void AMControl.startDone(error_t err) {
    struct rcv_buffer *buffer_ptr;
  	dbg("WSN_Project", "Start performed.\n");
    if (err == SUCCESS) {
      switch (TOS_NODE_ID) {
        case ID_OF_GATEWAY: {
          int i;
          dbg("WSN_Project", "NodeID %d --> Gateway node started.\n", ID_OF_GATEWAY);
          printf("WSN_Project: NodeID %d --> Gateway node started.\n", ID_OF_GATEWAY);
          for (i=0; i<10; i++) {
            buffer_ptr = (struct rcv_buffer *) malloc(sizeof(struct rcv_buffer));
            buffer_ptr->received=(struct rcv_msg *)NULL;
            rcv_buffers[i]=*buffer_ptr;
           } 
          break;
        }
        default: {
          dbg("WSN_Project", "Normal node with NodeID: '%d' started.\n",TOS_NODE_ID);
          printf("WSN_Project: Normal node with NodeID: '%d' started.\n",TOS_NODE_ID);    
          call SensorTimer.startPeriodic(1000);
          }
      }
    } else {
      dbg("WSN_Project", "Starting not succesfull. Try again ...\n");
      call AMControl.start();
    }
  }
  
  void cleanUp() {
    locked = FALSE;
    free(bufferPointer);
    packagesSent = 0;
    bufferSize = 0;
    attempts=0;
  }
  
  event void AMControl.stopDone(error_t err) {
  	dbg("WSN_Project", "AMControl stopped.\n");
    // do nothing
    cleanUp();
  }
  
  void sendNext() {
  
    uint16_t nodePrev;
    radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
    if (rcm == NULL) {
        // no memory available?
        printf("WSN_Project: try to set payload, but received no memory. only NULL\n");
	return;	
    }  
    //dbg("WSN_Project", "Medium free, sent package number %d, BufferSize: %d and buffer %d\n", packagesSent, bufferSize, *(bufferPointer+packagesSent*MAX_BUFFER_SIZE));
    //printf("WSN_Project: Medium free, sent package number %d, BufferSize: %d and buffer %d\n", packagesSent, bufferSize, *(bufferPointer+packagesSent*MAX_BUFFER_SIZE));
    rcm->messageType = PIECEMESSAGE_TYPE;
    rcm->nodeId = TOS_NODE_ID;
    nodePrev = rcm->nodeId-1;

    if ((packagesSent+1)*MAX_BUFFER_SIZE >= bufferSize) {
      //last package, copy just left bytes to the payload
      int leftToCopy = bufferSize - (packagesSent * MAX_BUFFER_SIZE);
      // assert leftToCopy <=MAX_BUFFER_SIZE;
      dbg("WSN_Project", "Last package. Left to copy = %d\n", leftToCopy);
      memcpy(rcm->buffer, bufferPointer+(packagesSent*MAX_BUFFER_SIZE), leftToCopy);
    } else {
      memcpy(rcm->buffer,bufferPointer+(packagesSent*MAX_BUFFER_SIZE),MAX_BUFFER_SIZE);
    }
    rcm->counter = packagesSent;
    dbg("WSN_Project", "rcm->buffer before sending: %d\n", *(rcm->buffer));
    
    // assert TOS_NODE_ID != 1
    //dbg("WSN_Project", "Try to send package %d\n", packagesSent);
    //printf("WSN_Project: Try to send package %d\n", packagesSent);
    if (useacks==TRUE) {
      call PacketAcknowledgements.requestAck(&packet);
    }

    if (call AMSend.send(nodePrev, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
      dbg("RadioCountToLedsC", "RadioCountToLedsC: packet %d sent.\n", packagesSent);
      printf("RadioCountToLedsC (node %d): packet %d sent to %d.\n", TOS_NODE_ID,packagesSent,nodePrev);
    } else {
      dbg("WSN_Project", "Package sending (result send != SUCCESS) for package %d \n", packagesSent);
      printf("WSN_Project (node %d): Package sending (result send != SUCCESS) for package %d \n", TOS_NODE_ID, packagesSent);
      cleanUp();
    }
  }
  
  task void initializeSending() {
    int i=0;
    uint16_t nodePrev;
    radio_start_msg_t* rsm = (radio_start_msg_t*)call Packet.getPayload(&startPacket, sizeof(radio_start_msg_t));
    if (rsm == NULL) {
      // no memory available?
	  return;	
    }
    rsm->messageType = STARTMESSAGE_TYPE;
    rsm->nodeId = TOS_NODE_ID;
    nodePrev=TOS_NODE_ID-1;
    //calculate amount of packages to send
    while(i*MAX_BUFFER_SIZE < bufferSize) {
      i++;
    }
    
    dbg("WSN_Project", "Medium free, sent initializiation package for %d packages to send at all.\n", i);
    rsm->amount = i;
    rsm->flag = TOS_NODE_ID%2;
    //rsm->timeStamp=call Time.get();
    rsm->timeStamp=0;
    rsm->total_payload_size=bufferSize;
    
    // assert TOS_NODE_ID != ID_OF_GATEWAY
    if (useacks==TRUE) {
      call PacketAcknowledgements.requestAck(&startPacket);
    }
    if (call AMSend.send(nodePrev, &startPacket, sizeof(radio_start_msg_t)) == SUCCESS) {
	  dbg("WSN_Project", "Start package sent from node %d to node %d.\n", TOS_NODE_ID, nodePrev);
          printf("WSN_Project (node %d): Start package sent from node %d to node %d.\n", TOS_NODE_ID, TOS_NODE_ID, nodePrev);
    } else {
      dbg("WSN_Project", "Start Package sending (result send != SUCCESS)\n");
      cleanUp();
    }
  }
  
  void simulatedSensorInterrupt(uint16_t size, void * sensorBuffer) {
    printf("Sensor itnerrupted\n");    
    if (locked) {
     dbg("WSN_Project", "Sensor fired, but locked. Nothing happend.Medium locked.\n");
     return;
    } else {
      locked=TRUE;
    }
    
    bufferSize = size;
    
    
    // sensor fired, copy sensor buffer localy
    bufferPointer = (nx_uint8_t *)malloc(bufferSize);

    dbg("WSN_Project", "Sensor fired, size = %d, bufferSize = %d \n", size, bufferSize);
    memcpy(bufferPointer, sensorBuffer, bufferSize);
    dbg("WSN_Project", "Sensor data copied \n");
    
    attempts=1;
    post initializeSending();
  }
  
  event void SensorTimer.fired() {
    // dbg("WSN_Project", "Sensor fired \n");
    nx_uint8_t *sensorBuffer = (nx_uint8_t *)malloc(packageSize*sizeof(nx_uint8_t));
    uint32_t i;
    for (i = 0; i<packageSize;i++) {
        sensorBuffer[i] = (i+1)*TOS_NODE_ID;
    }
    simulatedSensorInterrupt(packageSize, sensorBuffer);
    free(sensorBuffer);
  }
  
  void finish_packet_rcv(nx_uint16_t nodeId) {
    uint32_t i;
    dbg("WSN_Project", "All packages received from node %d. Could forward it to the gateway now.... Content: amount = %d, total_buffer_size = %d. buffer will come \n", nodeId, rcv_buffers[nodeId].amount, rcv_buffers[nodeId].total_payload_size);
printf("WSN_Project: All packages received from node %d. Could forward it to the gateway now.... Content: amount = %d, total_buffer_size = %d. buffer will come \n", nodeId, rcv_buffers[nodeId].amount, rcv_buffers[nodeId].total_payload_size);

    for(i=0;i<rcv_buffers[nodeId].total_payload_size;i++) {
      //printf("WSN_Project: buffer[%d] = %d\n", i, rcv_buffers[nodeId].receiving[i]);
    }
  }    

  void handleData(message_t* bufPtr, void* payload, uint8_t len) {
    
    uint16_t nodeId;
    uint16_t packetId;
    struct rcv_msg* spy;
    int i=0;
    uint16_t amount;
    radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
    dbg("WSN_Project", "rcm->counter: '%d'\n", rcm->counter);
    packetId=rcm->counter;
    //nodeId = call AMPacket.source(bufPtr);
    nodeId = rcm->nodeId;
    spy = rcv_buffers[nodeId].received;
    
    printf("RadioCountToLedsC : Test");


/*  for (i=0; i<packetId; i++) 
	{
      spy=spy->next;
    }
    //set the data received flag to true
    spy->packet_got=TRUE;
    
    // copy the buffer from the package to the receving buffer (merging)
    if ((packetId+1)*MAX_BUFFER_SIZE >= rcv_buffers[nodeId].total_payload_size) {
      //last package, copy just left bytes to own buffer
      uint16_t leftToCopy = ((rcv_buffers[nodeId].total_payload_size)-(packetId*MAX_BUFFER_SIZE));
      // assert leftToCopy <=MAX_BUFFER_SIZE;
      dbg("WSN_Project", "Last package received. Left to copy = %d, rcv_buffers[nodeId].total_payload_size=%d, pacetId = %d, packedId*MAX_BUFFER_SIZE = %d\n", leftToCopy,rcv_buffers[nodeId].total_payload_size, packetId, packetId*MAX_BUFFER_SIZE);
      memcpy(rcv_buffers[nodeId].receiving + (packetId*MAX_BUFFER_SIZE), rcm->buffer, leftToCopy);
    } else {
      // not the last package. Copy the whole buffer to the rcver
      memcpy(rcv_buffers[nodeId].receiving + (packetId*MAX_BUFFER_SIZE), rcm->buffer, MAX_BUFFER_SIZE);
    }
    
    //check if all packages are arived. If not return, else proceed the received package
    spy = rcv_buffers[nodeId].received;
    amount = rcv_buffers[nodeId].amount;
    for (i=0; i<amount; i++) {
      if ((spy->packet_got) == TRUE) {
        spy=spy->next;
      } else {
        return;
      }
    }
    finish_packet_rcv(nodeId); 
*/

  }
  
  void initializeReceiving(message_t* bufPtr, void* payload, uint8_t leng) {
    
    radio_start_msg_t* rcm = (radio_start_msg_t*)payload;
    int i = 0;
    int p = 0;
    struct rcv_msg *spy;
    struct rcv_msg *msg_ptr; 
    
    int nb = rcm->amount; 
    // uint16_t nodeId = call AMPacket.source(bufPtr);
    uint16_t nodeId = rcm->nodeId;
    rcv_buffers[nodeId].receiving = (nx_uint8_t *)malloc(rcm->total_payload_size);
    rcv_buffers[nodeId].amount=nb;
    rcv_buffers[nodeId].total_payload_size=rcm->total_payload_size;
    
    spy =rcv_buffers[nodeId].received;
    
    if (spy != NULL) {

      while(spy->next != NULL) {
        spy = spy->next;
        i++;
      }
    
      spy=rcv_buffers[nodeId].received;
      while(p<i+1) {
        (*spy).packet_got=FALSE;
        p++;
        spy = spy->next;
      }
    } else {
        struct rcv_msg *msg_stuff = (struct rcv_msg *)malloc(sizeof(struct rcv_msg));
        msg_stuff->next=(struct rcv_msg *)NULL;
        msg_stuff->packet_got=FALSE;
        rcv_buffers[nodeId].received=msg_stuff;
        spy =rcv_buffers[nodeId].received;
    }
    
    while(i<nb-1) {
        msg_ptr=(struct rcv_msg *)malloc(sizeof(struct rcv_msg));
        msg_ptr->next=(struct rcv_msg *)NULL;
        spy->next=msg_ptr;
        (spy->next)->packet_got=FALSE;
        i++;
        spy=spy->next;
      }
    
    //counter[0] = rcm->counter;
    //counter[0]++;
  }
  
  
 void transferdata(message_t* bufPtr, void* payload, uint8_t len)
 {
    uint16_t nodeId;
    uint16_t packetId;
    uint16_t PrevNode;
    struct rcv_msg* temp;
    int i=0;
    uint16_t amount;
    radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
    dbg("WSN_Project", "rcm->counter: '%d'\n", rcm->counter);
    packetId=rcm->counter;
    rcm->messageType = PIECEMESSAGE_TYPE;
    //nodeId = call AMPacket.source(bufPtr);
    nodeId = rcm->nodeId;
    PrevNode = nodeId-1;
    temp = rcv_buffers[nodeId].received;
    
    
    // Récupérer données du message, 
    // Stocker dans un buffer intermédiaire
    
    printf("RadioCountToLedsC (node %d): Transfert en cours, TOS_NODE_ID");

    for (i=0; i<packetId; i++) 
    {
    temp=temp->next;
    }
    //set the data received flag to true
    temp->packet_got=TRUE;
    
    // copy the buffer from the package to the receving buffer (merging)
    if ((packetId+1)*MAX_BUFFER_SIZE >= rcv_buffers[nodeId].total_payload_size) 
    {
      //last package, copy just left bytes to own buffer
      uint16_t leftToCopy = ((rcv_buffers[nodeId].total_payload_size)-(packetId*MAX_BUFFER_SIZE));
      // assert leftToCopy <=MAX_BUFFER_SIZE;
      dbg("WSN_Project", "Last package received. Left to copy = %d, rcv_buffers[nodeId].total_payload_size=%d, pacetId = %d, packedId*MAX_BUFFER_SIZE = %d\n", leftToCopy,rcv_buffers[nodeId].total_payload_size, packetId, packetId*MAX_BUFFER_SIZE);
      memcpy(rcv_buffers[nodeId].receiving + (packetId*MAX_BUFFER_SIZE), rcm->buffer, leftToCopy);
    } 
    else 
    {
      // not the last package. Copy the whole buffer to the rcver
      memcpy(rcv_buffers[nodeId].receiving + (packetId*MAX_BUFFER_SIZE), rcm->buffer, MAX_BUFFER_SIZE);
    }
    
    //check if all packages are arived. If not return, else proceed the received package
    temp = rcv_buffers[nodeId].received;
    amount = rcv_buffers[nodeId].amount;
    for (i=0; i<amount; i++) {
      if ((temp->packet_got) == TRUE) {
        temp=temp->next;
      } else {
        return;
      }
    }
    finish_packet_rcv(nodeId); 

    // Envoyer au noeud suivant 
    
    
    if (call AMSend.send(PrevNode, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
      dbg("RadioCountToLedsC", "RadioCountToLedsC: packet %d transfered.\n", packagesSent);
      printf("RadioCountToLedsC (node %d): packet %d transfered.\n", PrevNode,packagesSent);
    } else {
      dbg("WSN_Project", "Package transferring (result send != SUCCESS) for package %d \n", packagesSent);
      printf("WSN_Project (node %d): Package sending (result send != SUCCESS) for package %d \n", TOS_NODE_ID, packagesSent);
      cleanUp();
    }
  
    

    
  }   
    

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    
    if (TOS_NODE_ID != ID_OF_GATEWAY) 
    {
      printf("RadioCountToLedsC (node %d): Node %d received a package with payloadaddress %d. Transfer process...\n", TOS_NODE_ID, TOS_NODE_ID, payload);
		if (bufPtr != NULL && payload != NULL) 
			{
			switch (((uint8_t *)payload)[0]) 
				{ 
				case PIECEMESSAGE_TYPE: 
					{
					transferdata(bufPtr,payload,len);
					printf("RadioCountToLedsC (node %d):  Transfer done, TOS_NODE_ID");
					break;
					}
				default: 
					{
					printf("RadioCountToLedsC (node %d): Received packet of length %hhu from node %d. But it has an unknown type\n", TOS_NODE_ID, len, (call AMPacket.source(bufPtr)));
					dbg("WSN_Project", "Unknown package received\n");
      // TO DO 
					return bufPtr;
					}   
				}
			}	
	}

    
    // GATEWAY

    dbg("RadioCountToLedsC", "Received packet of length %hhu from node %d.\n", len, (call AMPacket.source(bufPtr)));
    printf("RadioCountToLedsC (node %d): Received packet with payload %d of length %hhu from node %d.\n", TOS_NODE_ID, payload, len, (call AMPacket.source(bufPtr)));
    
    if (bufPtr != NULL && payload != NULL) {
      switch (((uint8_t *)payload)[0]) { // here we take a look at the first field of the message, that shows the message type due to symphony has a bug with length and alwys send length 11
        case STARTMESSAGE_TYPE: {
          initializeReceiving(bufPtr, payload, len);
          break;
        }
        case PIECEMESSAGE_TYPE: {
          handleData(bufPtr, payload, len);
          break;
        }
        default: {
          printf("RadioCountToLedsC (node %d): Received packet of length %hhu from node %d. But it has an unknown type\n", TOS_NODE_ID, len, (call AMPacket.source(bufPtr)));
          dbg("WSN_Project", "Unknown package received\n");
        }
      }
    } else {
      dbg("WSN_Project", "Received buffer or receveid payload is empty.\n");
      printf("WSN_Project: Received buffer or receveid payload is empty.\n");
    }
    
    return bufPtr;
  
/*if (len != sizeof(radio_count_msg_t)) {
        if (len != sizeof(radio_start_msg_t)) {
    	    dbg("WSN_Project", "Unknown package received\n");
    	    return bufPtr;
    	} else {
    	  // start message received
    	  initializeReceiving(bufPtr, payload, len);
    	  return bufPtr;
    	}
    } else {
      switch (TOS_NODE_ID) {
        case ID_OF_GATEWAY:{
          // gateway
          handleData(bufPtr, payload, len);
          break;
          }
        default:
          // no gateway, TODO
          dbg("WSN_Project", "Normal node received a package...\n");
      }
      return bufPtr;
    }*/
    
  }
  
 
  
  

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      if(useacks == FALSE || (call PacketAcknowledgements.wasAcked(bufPtr))) {
        if (useacks==TRUE) {
          dbg("WSN_Project", "Ack received for package %d.\n", packagesSent);
        }
        packagesSent++;
        if ((packagesSent)*MAX_BUFFER_SIZE < bufferSize) {
          attempts = 1;
          sendNext();
        } else {
          dbg("WSN_Project", "Succesfully sent all %d packages.  \n", packagesSent);
          printf("WSN_Project (Node %d): Succesfully sent all %d packages. \n", TOS_NODE_ID, packagesSent);
          cleanUp();
        }
      } else {
        // not acked, sent it again, until maxAttempts reached
        if (attempts < maxAttempts) {
          dbg("WSN_Project", "No ack received for package %d and %d/%d tries. Try to resend it...\n", packagesSent, attempts, maxAttempts);
          printf("WSN_Project: No ack received for package %d and %d/%d tries. Try to resend it...\n", packagesSent, attempts, maxAttempts);
          attempts++;
          sendNext();
        } else {
          dbg("WSN_Project", "Sending aborted, no ack received for package %d after %d tries.\n", packagesSent, maxAttempts);
          printf("WSN_Project: Sending aborted, no ack received for package %d after %d tries.\n", packagesSent, maxAttempts);
          cleanUp();
        }
      }
    } else {
      if (&startPacket == bufPtr) {
        if(useacks==FALSE || call PacketAcknowledgements.wasAcked(bufPtr)) {
          if (useacks==TRUE) {
            dbg("WSN_Project", "Ack received for initialization packages.\n");
            printf("WSN_Project: Ack received for initialization packages.\n");
          } else {
            printf("WSN_Project: Finished sending of initialization package without acknowledgement.\n");
          }
          packagesSent = 0;
          attempts = 1;
          sendNext();
        } else {
          if (attempts < maxAttempts) {
            dbg("WSN_Project", "No ack received for initialization package after %d/%d tries. Try to resend it...\n", attempts, maxAttempts);
            printf("WSN_Project: No ack received for initialization package after %d/%d tries. Try to resend it...\n", attempts, maxAttempts);
            attempts++;
            post initializeSending();
          } else {
            dbg("WSN_Project", "Sending aborted, no ack received for initialation package after %d tries.\n", maxAttempts);
            printf("WSN_Project: Sending aborted, no ack received for initialation package after %d tries.\n", maxAttempts);
            cleanUp();
          }
        } 
      } else {
        cleanUp();
        dbg("WSN_Project", "Received a send done event for a package that was not sent from this node %d\n", TOS_NODE_ID);
        printf("WSN_Project: Received a send done event for a package that was not sent from this node %d\n", TOS_NODE_ID);
      }
    }
  }
}
