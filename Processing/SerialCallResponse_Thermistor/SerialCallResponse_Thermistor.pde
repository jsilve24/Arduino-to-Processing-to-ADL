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
PFont inFont;                   // font to write filename input text
float volt;                   // The Voltage read by Arduino Pin A0
String voltVal;               // The string version of variable "volt"
// Used to print value to screen
PrintWriter file;

String fileName;              // Filename to save temperature data to
boolean gotName = false;      // Has a valid filename been entered?

float temp;                   // the temperature converted from voltage
// measured in celcius
boolean manualMode = false;  // are we in manual mode? (manual mode averages 
// temperature measurements according to intAveTemp;
int intAveTemp;                // number of temperature readings to average during
// manual of thermistor

boolean manualConfirm = false; // are you sure you want to enter manual mode?
boolean manualAnswer = false;  // has the user answered the question and given a value to manualConfirm?
boolean ask = false;          // do we need to prompt the user for input?

ArrayList<Integer> graph;     // create an ArrayList to handle graph values and easily implement a queue. 
int dataLength;               // Temporarily hold graph point

// Identify Operating System
String OSname = System.getProperty("os.name");
int serialport = 0;  // What serial port should be used

// controlP5 declarations
ControlP5 cp5;
Button btnManual;
Toggle togLight;
Toggle togWrite;
Textfield textFilename;
Textlabel labLight;
Textlabel labWrite;
Button btnYes;
Button btnNo;


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
  inFont = createFont("arial", 20);   // See Above listed Font

  // Create GUI
  cp5 = new ControlP5(this); 

  // Add Text box
  textFilename =  cp5.addTextfield("textA", 10, 10, 300, 40)
    .setFont(inFont)               // Prompt User for File Name to save temperature data to
      .setAutoClear(false);          // Do not clear the screen after entering text.

  // Add manual button
  btnManual = cp5.addButton("manual", 1, 10, 51, 150, 30);

  // Add Light On/Off Toggle
  togLight = cp5.addToggle("light")
    .setPosition(300, 50)
      .setSize(50, 20)
        //.setState(false)
          .setMode(ControlP5.SWITCH)
            .setVisible(false);
  // Add Write to File Toggle
  togWrite = cp5.addToggle("write2File")
    .setPosition(300, 90)
      .setSize(50, 20)
        //.setState(false)
          .setMode(ControlP5.SWITCH)
            .setVisible(false);

  // Add Light On/Off State Indicator
  labLight = cp5.addTextlabel("lighton")
    .setText("OFF")
      .setPosition(355, 55)
        .setColorValue(0xffffff00)
          .setVisible(false);

  // Add Write On/Off State Indicator
  labWrite = cp5.addTextlabel("write")
    .setText("OFF")
      .setPosition(355, 97)
        .setColorValue(0xffffff00)
          .setVisible(false);

  // create Message with Yes/No Buttons
  btnYes = cp5.addButton("yes", 1, 10, 150, 190, 100)
    .setVisible(false);
  btnNo = cp5.addButton("no", 1, 200, 150, 190, 100)
    .setVisible(false);

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

  // Instantiate Linked list for Graph
  graph = new ArrayList<Integer>(Collections.nCopies(200, 0));
}


/**********************/
/****    DRAW()    ****/
/**********************/

public void draw() {

  if (gotName == false) {
    background (bgcolor); //Needed otherwise each loop just draws ontop of itself.
    //delay(50);
  } 

  if (ask == true) {
    background (0);

    /* Print message to Window */
    textFont(fontMessage, 18);  
    fill (255);
    textAlign(CENTER);
    text("Are you sure?", width/2, 20);
  } 
  else {  
    background (bgcolor); //Needed otherwise each loop just draws ontop of itself.
    /* Print Voltage to Window */
    textFont(font, 72);  
    fill(0);
    textAlign(CENTER);
    voltVal = nf(volt, 1, 3);
    text(voltVal + " V", width/2, 200);


    // Draw Graph (each line stored in ArrayList graph.
    stroke(127, 34, 255);             // draw this line
    for (int i = graph.size(); i>0; i--) {
      line(i*2, height, i*2, height - graph.get(i - 1));
    }


    if (manualMode == true) {
      //Average Thermometer Readings...
      clipboardCheck();
    }
    else if (manualMode == false) {
      clipboardCheck();

      //Add File Extension Text Label
      textFont(inFont, 25);
      fill(0);
      text(".dat", 334, 40);
    }
  }
}


/****  BEGIN SERIALEVENT()  ****/

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

      /*  Graph Voltage Measurement  */
      dataLength =(int) map(inByte, 0, 1023, 0, height);

      graph.remove(0);
      graph.add(dataLength);


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
    file.println(volt2temp(volt) + "\t" + volt);     // If Start Signal "X" has been recieved write 
    // Value of temp and volt (from arduino) to File
    if (manualMode == false) {
      lightOn();
      write2File(true);
    }
  } 
  else if (clipped.equals("Y")) {
    file.flush();                      // Writes the remaining data to the file
    file.close();                      // Finishes the file
    if (manualMode == false) {
      lightOff();
      write2File(false);
    }
    
    // Add some notification so we know this is not happening by accident
    delay(500);
    myPort.stop();                      // Stop Serial Communication to Arduino
    exit();                             // Exit this Application
  }
  else {
    delay(300);                         // Give it 0.3s and then test clipboard again.
  }
}


/*******************************/
/****  CUSTOM FUNCTIONS  *******/
/*******************************/

/*  LIGHTON
 */
void lightOn() {
  myPort.write('B');                   // Send signal (To Arduino) to turn on light
  labLight.setText("ON");
  if (togLight.getState() == false) {
    togLight.setState(true);
  }
  if (togWrite.getState() == true) {
    file.println("# Light ON");
  }
}
/*  LIGHTOFF
 */
void lightOff() {
  myPort.write('Z');                 // Send signal (To Arduino) to turn off light
  labLight.setText("OFF");
  if (togLight.getState() == true) {
    togLight.setState(false);
  }
  if (togWrite.getState() == true) {
    file.println("# Light OFF");
  }
}

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


/*  ENTERMANUALMODE
 */

void entermanualMode() {
  // Properly adjust boolean manualMode
  if (manualMode == false) {
    manualMode = true;

    // pretend a filename as been entered but just skip creating it.
    gotName = true;

    // hide input textfield
    cp5.controller("textA").setVisible(false);
  } 
  else {
    manualMode = false;
    gotName = false;

    // show textfield that was hidden
    textFilename.setVisible(true);
    togLight.setVisible(false);
    togWrite.setVisible(false);
    labLight.setVisible(false);
    labWrite.setVisible(false);
  }
}


/*******************************/
/****  GUI FUNCTIONS  ****/
/*******************************/

// for every change (a textfield event confirmed with a return) in textfield textA,
// function textA will be invoked
void textA(String theValue) {
  //println("### got an event from textA : "+theValue);
  fileName = theValue;
  gotName = true;
  file = createWriter("C:\\Documents and Settings\\Lecomte Lab\\Desktop\\Justin Silverman\\DATA\\" +fileName + ".dat");          // Create file to write to write to at defined
  // location (relative to sketch folder) 

  // WRITE HEADER INFO
  file.println("# temp = x3 * pow(v,3) + x2 * pow(v,2) + x1 * v + x0");
  file.println("# x0 = " + x0 );
  file.println("# x1 = " + x1 );
  file.println("# x2 = " + x2 );
  file.println("# x3 = " + x3 );
  file.println("# temperature measurements taken approximately every 300ms");
  file.println("# temperature measurements given in units of degrees celcius");
  file.println("#");
  file.println("#");
  file.println("# DATA");
  file.println("# Temp \t Voltage");
  file.println("# Celcius \t Volts");
}

// actions to be executed when the manual button is clicked.
public void manual(int theValue) {
  manualAnswer = false;
  manualConfirm = false; 

  // Make sure the user wants to do this. (Should do this with MultiThreading in the Future)
  if (manualMode == false) {
    btnYes.setVisible(true);
    btnNo.setVisible(true);
    textFilename.setVisible(false);
    btnManual.setVisible(false);
    togLight.setVisible(false);
    togWrite.setVisible(false);
    labLight.setVisible(false);
    labWrite.setVisible(false);

    ask = true;
  } 
  else {
    entermanualMode();
  }
}

void yes(int theValue) {
  boolean manualConfirm = true;
  ask = false;
  entermanualMode();
  btnYes.setVisible(false);
  btnNo.setVisible(false);
  btnManual.setVisible(true);
  togLight.setVisible(true);
  togWrite.setVisible(true);
  labLight.setVisible(true);
  labWrite.setVisible(true);
}

void no(int theValue) {
  boolean manualConfirm = false;
  ask = false;
  btnYes.setVisible(false);
  btnNo.setVisible(false);
  btnManual.setVisible(true);
  textFilename.setVisible(true);
  togLight.setVisible(false);
  togWrite.setVisible(false);
  labLight.setVisible(false);
  labWrite.setVisible(false);
}


void light(boolean toggleValue) {
  if (toggleValue == true) {
    lightOn();
    println("lighton!");
  } 
  else {
    lightOff();
    println("lightoff!");
  }
}

void write2File(boolean toggleValue) {
  if (toggleValue == true) {
    cp.copyString("X");                    // Replace contents of Clipboard with "X"
    labWrite.setText("ON");
    println("writeon!");
  } 
  else if (toggleValue == false) {
    cp.copyString("Y");                    // Replace contents of Clipboard with "Y"
    labWrite.setText("OFF");
    println("writeOFF!");
  }
}

