 // Modified from http://arduino.cc/en/Tutorial/SerialCallResponse
/*
  Serial Call and Response
 Language: Wiring/Arduino
 
 This program sends an ASCII A (byte of value 65) on startup
 and repeats that until it gets some data in.
 Then it waits for a byte in the serial port, and 
 sends three sensor values whenever it gets a byte in.
 */

// SERIAL COMMANDS
// Any Byte will Estabilish Contact and Request next Temp Reading
// 'B' is Turn on Light
// 'Z' is Turn off Light
// '!' is Error -- Currently Unused

const int SENSOR = 0;
const int SWITCH = 13;

boolean STOP = 0;  //STOP = 1 if Stop signal 'Z' has been received 
//through Serial COM

int val = 0;              // stores the current state of SENSOR pin
byte val_low = 0;          // stores low 8 bits of val
byte val_high = 0;        // stores high 8 bits of val
int inByte = 0;           // incoming serial byte
int numAve = 0;           // number of readings averaged together
int ave[3];              // array to hold readings 

// CUSTOM FUNCTIONS
void lightOn() {
  digitalWrite(SWITCH, HIGH);
}

void lightOff() {
  digitalWrite(SWITCH, LOW);
}

void restart() {
  if (STOP = 1){
    STOP = 0;
  }
  else {
    Serial.write('!');  // This should be replaced by an Error Output
  }
}


// NESSESITIES
void setup() {
  pinMode(SWITCH, OUTPUT);

  // start serial port at 9600 bps:
  Serial.begin(9600); 
  establishContact();      // send a byte to establish
  // contact until receiver responds                     
}

void loop() {
  // if we get a valid byte read analog ins:
  if (Serial.available() > 0) {
    inByte = Serial.read();      // get incoming byte:
    if (inByte =='B') {          // If 'B' is recieved turn on light
      lightOn();
      STOP = 0;
      inByte = Serial.read();
    }
    else if (inByte == 'Z') {
      lightOff();
      STOP = 1;
      inByte = Serial.read();    // get next incomming byte to continue
      // transmitting data over serial
    }

    while (numAve <3) {
      collectData();
      delay(300);
      //Serial.println("numAve <3");
    }
    
    if (numAve == 3) {
      //Serial.println("ave[0] = " + String(ave[0]));     // For Debugging
      //Serial.println("ave[1] = " + String(ave[1]));     // For Debugging
      //Serial.println("ave[2] = " + String(ave[2]));     // For Debugging
      
      val = (ave[0]+ave[1]+ave[2])/3.0;
      //Serial.println(val);
      
      //Serial.println("valave = " + String(val));
      
      // Should I also send the standard deviation of these measurements?
      // What about changing the number of measurements that are averaged?
      
      val_high = highByte(val);
      val_low = lowByte(val);
      //Serial.println(int(val_high));  // For Debugging
      //Serial.print(int(val_low));     // For Debugging
      Serial.write(val_high);
      Serial.write(val_low);
      
      numAve = 0; // reset counter
    }

    delay(300);
  }
}


void collectData() {
  val = analogRead(SENSOR);
  
  //Serial.println("val = " + String(val));
  ave[numAve] = val;
  numAve++;
}

void establishContact() {
  while (Serial.available() <= 0) {
    Serial.print('A');      // send capital A
    delay(300);
  }
}

