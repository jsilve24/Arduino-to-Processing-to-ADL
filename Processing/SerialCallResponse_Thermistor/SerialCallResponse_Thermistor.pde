//Add Error of Temp to output
//Double Check Calibration of Thermistor

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
PFont inFont;                   // font to write filename input text
float volt;                   // The Voltage read by Arduino Pin A0
String voltVal;               // The string version of variable "volt"
                              // Used to print value to screen
PrintWriter file;

String fileName;              // Filename to save temperature data to
boolean gotName = false;      // Has a valid filename been entered?

float temp;                  // the temperature converted from voltage
                              // measured in celcius
                              
/*
 Global Constants
*/

final double x3 = -8.8608;
final double x2 = 85.7174;
final double x1 = -290.8986;
final double x0 = 409.0631;


// controlP5 declarations
ControlP5 cp5;
Textlabel myTextLabelA;

/****  BEGIN SETUP/DRAW  ****/

public void setup() {
  size(400, 400);            // Display Window size
  background(bgcolor);       // Set Background Color for Display Window
  font = loadFont("AdobeHeitiStd-Regular-48.vlw"); // See Above listed Font 
  inFont = createFont("arial",20); // See Above listed Font
  cp5 = new ControlP5(this); 
  cp5.addTextfield("textA", 10, 10, 300, 40)
     .setFont(inFont)  // Prompt User for File Name to save temperature data to
     .setAutoClear(false); // Do not clear the screen after entering text.
  //Add File Extension Text Label
    textFont(inFont,20);
    fill(0);
    text(".dat",315,30);

  println(Serial.list());    // Print a list of the serial ports, for debugging purposes:
  // On Mac:
  //  String portName = Serial.list()[0];
  // On Windows:
  //  String portName = Serial.list()[1];
  String portName = Serial.list()[1]; // Pick Serial Port to comunicate over (From Above List printed to screen)
  myPort = new Serial(this, portName, 9600); // Take this port and define the communication scheme. 
                                             // This scheme is an object "myPort" 
// Should Get Filename from ADL
  cp.copyString("Not X");                    // Replace contents of Clipboard with "Not X"
}

void draw() { 
  if (gotName == false) {
    delay(50);
  }
  else{  
  //cp5.setColorBackground(color(255));
  /* Print Voltage to Window */
  textFont(font, 72);  
  fill(0);
  textAlign(CENTER);
  voltVal = nf(volt, 1, 3);
  text(voltVal + " V", width/2, 200);

  /* Clipboard Operations */
  clipped = cp.pasteString();  // Get contents of Clipboard and store them in Clipped
  println(clipped);            // Print Contents of Clipboard to screen (For Debugging)
  if (clipped.equals("X")) {   // If Signal "X" recieved from ADL (Through Clipboard)
    // cp.copyString("HandShake!!!"); // For Debugging Purposes
    /* Begin Writing Temp Data to File */
    file.println(volt2temp(volt) + "\t" + volt);        // If Start Signal "X" has been recieved write 
                                                           // Value of temp and volt (from arduino) to File
    myPort.write('B');         // Send signal (To Arduino) to turn on light
  } 
  else if (clipped.equals("Y")) {
    file.flush();                // Writes the remaining data to the file
    file.close();                // Finishes the file
    myPort.write('Z');           // Send signal (To Arduino) to turn off light
// Add some notification so we know this is not happening by accident
    delay(500);
    myPort.stop();            // Stop Serial Communication to Arduino
    exit();                    // Exit this Application
  }
  else {
    delay(300);                // Give it 0.3s and then test clipboard again.
  }
  }
}

/****  BEGIN SERIALEVENT()  ****/

void serialEvent(Serial myport) {
  int inByte = myPort.read();      // read a byte from the serial port
  // if this is the first byte received, and it's an A,
  // clear the serial buffer and note that you've
  // had first contact from the microcontroller. 
  // Otherwise, add the incoming byte to the array:

  if (firstContact == false) {
    if (inByte == 'A') { 
      myPort.clear();               // clear the serial buffer
      firstContact = true;          // you've had first contact from the microcontroller
      myPort.write('A');            // ask for more
    }
  } 
  else {
    // Add the latest byte from the serial port to array:
    serialInArray[serialCount] = inByte;
    serialCount++;

    if (serialCount > 1) {           // if we have 2 byte:
      val_high = serialInArray[0];   // The byte that was recieved first 
                                     // is the first 8 bits of val
      val_low = serialInArray[1];    // The byte that was recieved second
                                     // is the second 8 bits of val
      val = val_high << 8 | val_low; // Place the first 8 bits in val_high 
                                     // before the last 8 bits in val_low
                                     // to make val
      //println(int(val));             // For Debugging Purposes
      volt = mapDouble(val, 0, 1023, 0.00, 5.00); //Change the range of val from 0-1023
                                                  // to 0.00-5.00 to be a meaningful quantity (voltage)

      /*  Graph Voltage Measurement  */
      float dataLength;

      dataLength = map(inByte, 0, 1023, 0, height);
      stroke(127, 34, 255);           // draw this line
      line(xpos, height, xpos, height - dataLength);

      if (xpos >= width) {        // at the edge of the screen, go back to the beginning:
        xpos = 0;
        background(bgcolor); 
      } 
      else {
        // increment the horizontal position:
        xpos = xpos+2;
      }

      myPort.write('A');             // Send a capital A to request new sensor readings:   
      serialCount = 0;               // Reset serialCount:
    }
  }
}





/****  CUSTOM FUNCTIONS  ****/
public double volt2temp(float v){
  double temp;
  temp = x3 * pow(v,3) + x2 * pow(v,2) + x1 * v + x0;
  return temp;
}

// for every change (a textfield event confirmed with a return) in textfield textA,
// function textA will be invoked
void textA(String theValue) {
  println("### got an event from textA : "+theValue);
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


/*  MAPDOUBLE
 Change the range of x from range in_min to in_max
 to out_min to out_max
*/
float mapDouble(float x, float in_min, float in_max, float out_min, float out_max) {
  float result;
  result = (x-in_min)*(out_max - out_min)/(in_max -in_min) +out_min;
  return result;
}





/****  CLIPBOARD CLASS  ****/

// //////////////////
// Clipboard class for Processing
// by seltar, modified by adamohern
// v 0115AO
// only works with programs. applets require signing
// From:
// http://processing.org/discourse/beta/num_1274718629.html
import java.awt.datatransfer.*;
import java.awt.Toolkit; 

ClipHelper cp = new ClipHelper();

class ClipHelper {
  Clipboard clipboard;

  ClipHelper() {
    getClipboard();
  }

  void getClipboard () {
    // this is our simple thread that grabs the clipboard
    Thread clipThread = new Thread() {
      public void run() {
        clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
      }
    };

    // start the thread as a daemon thread and wait for it to die
    if (clipboard == null) {
      try {
        clipThread.setDaemon(true);
        clipThread.start();
        clipThread.join();
      }  
      catch (Exception e) {
      }
    }
  }

  void copyString (String data) {
    copyTransferableObject(new StringSelection(data));
  }

  void copyTransferableObject (Transferable contents) {
    getClipboard();
    clipboard.setContents(contents, null);
  }

  String pasteString () {
    String data = null;
    try {
      data = (String)pasteObject(DataFlavor.stringFlavor);
    }  
    catch (Exception e) {
      System.err.println("Error getting String from clipboard: " + e);
    }
    return data;
  }

  Object pasteObject (DataFlavor flavor)  
    throws UnsupportedFlavorException, IOException
  {
    Object obj = null;
    getClipboard();

    Transferable content = clipboard.getContents(null);
    if (content != null)
      obj = content.getTransferData(flavor);

    return obj;
  }
}

