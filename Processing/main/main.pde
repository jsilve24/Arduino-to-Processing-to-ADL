//Add Error of Temp to output
//Double Check manual of Thermistor

// Modified from http://arduino.cc/en/Tutorial/SerialCallResponse
/*
  Serial Call and Response
 Language: Processing
 
 This program sends an ASCII A (byte of value 65) on startup
 and repeats that until it gets some data in.
 Then it waits for a byte in the serial port, and 
 sends three sensor values whenever it gets a byte in.
 
 The handshake between ADL and processing is now being done with the clipboard.
 
 Ascii Codes:
 To Arduino:
 'B' - Send signal to turn on light
 'Z' - Send signal to turn off light
 
 From ADL:
 'X' - Start writing Temperature Measurements to File
 This means that ADL has started to take measurements
 
 'Y' - Stop writing Temperature Measurements to File
 This means that ADL has stopped taking measurements 
 
 */

// Font Tutorial at http://processing.org/learning/text
// Tutorial on Printing to a File: http://processing.org/reference/PrintWriter.html
// interfacia library can be found at: http://www.superstable.net/interfascia/   


import controlP5.*;
import processing.serial.*;
import java.io.File;

/****  BEGIN DECLARATIONS  ****/

int bgcolor = 155;            // Background Color
int xpos = 1;                 // horizontal position of the graph
Serial myPort;                // the serial port
int[] serialInArray = new int[2]; //where we'll put what we receive
int serialCount = 0;          // a count of how many bytes we have recieved
int val_high;                 // First Part of Received int
int val_low;                  // Second Part of Received int
int val;                      // Full Received int
boolean firstContact = false; // whether we've heard from the microcontroller
String clipped;               // Stores Contents of the Clipboard
PFont font;                   // font to write display text
PFont fontMessage;            // font for user prompt messages
PFont inFont;                 // font to write filename input text
float volt;                   // The Voltage read by Arduino Pin A0
String voltVal;               // The string version of variable "volt"
float temp;                   // the temperature converted from voltage
                              // measured in celcius
PrintWriter file;             // Used to Write to file


String OSname = System.getProperty("os.name");  // Identify Operating System
int serialport = 0;  // What serial port should be used

// One Global Call to create this (not supported in internal classes)
ControlP5 cp5;

// Custom Classes
Graph graph;                    // Declare new Graph object
GUI gui;                        // Declare new GUI object




/*
 manual Constants
 */

final double x3 = -8.8608;
final double x2 = 85.7174;
final double x1 = -290.8986;
final double x0 = 409.0631;







/****************************/
/****  BEGIN SETUP/DRAW  ****/
/****************************/

public void setup() {
  size(400, 400);                    // Display Window size
  background(bgcolor);               // Set Background Color for Display Window
  font = loadFont("AdobeHeitiStd-Regular-48.vlw"); // See Above listed Font 
  fontMessage = loadFont("Dialog-18.vlw");  // create font for user prompt messages. 
  inFont = createFont("arial", 20);
  
  cp5 = new ControlP5(this);
  gui = new GUI();

  println(Serial.list());          // Print a list of the serial ports, for debugging purposes:
  // On Mac:
  //  String portName = Serial.list()[0];
  // On Windows:
  //  String portName = Serial.list()[1];
  if (OSname.equals("Mac OS X")) {
    serialport = 0;
  }
  else if (OSname.equals("Windows XP") || OSname.equals("Windows 7")) {
    serialport = 1;
  }

  String portName = Serial.list()[serialport]; // Pick Serial Port to comunicate over (From Above List printed to screen)
  myPort = new Serial(this, portName, 9600); // Take this port and define the communication scheme. 
  // This scheme is an object "myPort" 
  // Should Get Filename from ADL
  cp.copyString("Not X");                    // Replace contents of Clipboard with "Not X"

  // Instantiate graph object
  graph = new Graph();
}


/**********************/
/****    DRAW()    ****/
/**********************/

public void draw() {

  if (gui.gotName == false) {
    background (bgcolor); //Needed otherwise each loop just draws ontop of itself.
    //delay(50);
  } 

  if (gui.ask == true) {
    gui.userConfirm();
  } 
  else {  
    background (bgcolor); //Needed otherwise each loop just draws ontop of itself.
    /* Print Voltage to Window */
    textFont(font, 72);  
    fill(0);
    textAlign(CENTER);
    voltVal = nf(volt, 1, 3);
    text(voltVal + " V", width/2, 200);

    graph.pushVal(150);
    graph.drawGraph();        // Draw Graph (each line stored in ArrayList in Graph Object.)


    if (gui.getManualMode() == true) {
      //Average Thermometer Readings...
      clipboardCheck();
    }
    else if (gui.getManualMode() == false) {
      clipboardCheck();
    }
  }
}

/*******************************/
/****  BEGIN SERIALEVENT()  ****/
/*******************************/

void serialEvent(Serial myport) {
  int inByte = myPort.read();          // read a byte from the serial port
  // if this is the first byte received, and it's an A,
  // clear the serial buffer and note that you've
  // had first contact from the microcontroller. 
  // Otherwise, add the incoming byte to the array:

  if (firstContact == false) {
    if (inByte == 'A') { 
      myPort.clear();                 // clear the serial buffer
      firstContact = true;            // you've had first contact from the microcontroller
      myPort.write('A');              // ask for more
    }
  } 
  else {
    // Add the latest byte from the serial port to array:
    serialInArray[serialCount] = inByte;
    serialCount++;

    if (serialCount > 1) {             // if we have 2 byte:
      val_high = serialInArray[0];     // The byte that was recieved first 
      // is the first 8 bits of val
      val_low = serialInArray[1];      // The byte that was recieved second
      // is the second 8 bits of val
      val = val_high << 8 | val_low;   // Place the first 8 bits in val_high 
      // before the last 8 bits in val_low
      // to make val
      //println(int(val));             // For Debugging Purposes
      volt = mapDouble(val, 0, 1023, 0.00, 5.00); //Change the range of val from 0-1023
      // to 0.00-5.00 to be a meaningful quantity (voltage)

      graph.pushVal((int) map(inByte, 0, 1023, 0, height));  // Add Corresponding value to graph object


        myPort.write('A');                // Send a capital A to request new sensor readings:   
      serialCount = 0;                  // Reset serialCount:
    }
  }
}




/*******************************/
/****  CLIPBOARD FUNCTIONS  ****/
/*******************************/

public void clipboardCheck() {
  /* Clipboard Operations */
  clipped = cp.pasteString();            // Get contents of Clipboard and store them in Clipped
  println(clipped);                      // Print Contents of Clipboard to screen (For Debugging)
  if (clipped.equals("X")) {             // If Signal "X" recieved from ADL (Through Clipboard)
    // cp.copyString("HandShake!!!");    // For Debugging Purposes

    /* Begin Writing Temp Data to File */
    try {
      file.println(volt2temp(volt) + "\t" + volt);     // If Start Signal "X" has been recieved write
    } 
    catch (NullPointerException ex) {   // no data to write to file... 
      println("Cannot write to file, no data to write.");
    }
    println("here");

    // Value of temp and volt (from arduino) to File
    if (gui.getManualMode() == false) {
      lightOn();
      gui.write2File(true);
    }
    delay(300);
  } 
  else if (clipped.equals("Y")) {

    try {
      file.flush();                      // Writes the remaining data to the file
      file.close();                      // Finishes the file
      if (gui.rename == true) {          // If we have to rename the file. 
        renameFile();                    // Function Declaration below
      }
    } 
    catch (NullPointerException ex) {   // no data to write to file... 
      println("Cannot write to file, no data to write.");
    }

    if (gui.getManualMode() == false) {
      lightOff();
      gui.write2File(false);
    }

    // Add some notification so we know this is not happening by accident
    delay(300);
    myPort.stop();                      // Stop Serial Communication to Arduino
    //exit();                             // Exit this Application
  }
  else {
    delay(300);                         // Give it 0.3s and then test clipboard again.
  }
}


/*******************************/
/****  CUSTOM FUNCTIONS  *******/
/*******************************/

/*  VOLT2TEMP
 */
public double volt2temp(float v) {
  double temp;
  temp = x3 * pow(v, 3) + x2 * pow(v, 2) + x1 * v + x0;
  return temp;
}


/*  MAPDOUBLE
 Change the range of x from range in_min to in_max
 to out_min to out_max
 */
float mapDouble(float x, float in_min, float in_max, float out_min, float out_max) {
  float result;
  result = (x-in_min)*(out_max - out_min)/(in_max -in_min) +out_min;
  return result;
}


/*  LIGHT ON/OFF FUNCTIONS
*/
void lightOn() {
  // println("LightON Main");  // Debugging Only

  try {
    myPort.write('B');                // Will this work? myPort is defined in outer class...
    // Send signal (To Arduino) to turn on light
  }  
  catch (NullPointerException e) {
    println("Can't send lightOff ('Z') to arduino, no serial connection detected");
  }

  if (gui.getLightState() == false) { // If the light (toggle) has not already be switched). 
    gui.lightOn();
  }
} // END lightOn()



void lightOff() {
  //println("LightOFF Main"); // Debugging Only

  try {
    myPort.write('Z');                // Will this work? myPort is defined in outer class...
    // Send signal (To Arduino) to turn on light
  } 
  catch (NullPointerException e) {
    println("Can't send lightOff ('Z') to arduino, no serial connection detected");
  }

  if (gui.getLightState() == true) { // If the light (toggle) has not already be switched). 
    gui.lightOff();
  }
} // END lightOff()


/*********************************************/
/***  Forward Control Events to GUI Class  ***/
/*********************************************/
// The following forwards control events to the GUI class where they should be stored.
// This has to be done because of a limitation of the controlP5 library (Or maybe its for a reason). 
void controlEvent(ControlEvent theEvent) { 
  if (theEvent.isController()) {
    println("control event from: " +theEvent.controller().name());

    if (theEvent.controller().name() == "textA") {
      gui.textA(theEvent.controller().getStringValue());
    }

    if (theEvent.controller().name() == "manual") {
      gui.manual((int) theEvent.controller().value());
    }

    if (theEvent.controller().name() == "yes") {
      gui.yes((int) theEvent.controller().value());
    }

    if (theEvent.controller().name() == "no") {
      gui.no((int) theEvent.controller().value());
    }

    if (theEvent.controller().name() == "light") {
      gui.light(false);    // Note that the value passed here (false is not used by gui.light() it is simply to prevent compile errors
    }

    if (theEvent.controller().name() == "write2File") {
      gui.write2File(false);  // // Note that the value passed here (false is not used by gui.light() it is simply to prevent compile errors
    }

    if (theEvent.controller().name() == "browse") {
      gui.browse((int) theEvent.controller().value());  // // Note that the value passed here (false is not used by gui.light() it is simply to prevent compile errors
    }
  }
}

/*****************/
/** Rename File **/
/*****************/
// From: http://processing.org/discourse/beta/num_1203753837.html
void renameFile() {
  File oldFile = new File(gui.savePath);             // Reopen original saved file
  oldFile.renameTo(new File(gui.savePath2));
}


