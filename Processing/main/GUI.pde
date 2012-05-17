/*****  GUI Class *****/

// By Justin Silverman
// Curently not to usefull outside of use with PolyNIPAM Experiment
// Uses controlP5 Library for Processing

import controlP5.*;

class GUI {
  //ControlP5 object defined in Main Tab for reasons explained here: 
  // http://processing.org/discourse/beta/num_1163646039_225.html
  private Button btnManual;
  private Toggle togLight;
  private Toggle togWrite;
  private Textfield textFilename;
  private Button btnBrowse;
  private Textlabel labLight;
  private Textlabel labWrite;
  private Button btnYes;
  private Button btnNo;
 
  String savePath;               // Filename to save temperature data to
  String savePath2;               // If we are going to rename the file this is the new file name
  boolean gotName = false;       // Has a valid filename been entered?
  boolean rename = false;        // Will we have to rename the file at the end?

  boolean manualMode = false;  // Are we in Manual Mode?
  boolean ask = false;          // Do we need to confirm something with user?


  GUI() {                       // Construction
    // Add Text box
    textFilename =  cp5.addTextfield("textA", 10, 10, 300, 40)
      .setFont(inFont)               // Prompt User for File Name to save temperature data to
        .setAutoClear(false);          // Do not clear the screen after entering text.

    btnBrowse = cp5.addButton("browse", 1, 320,10,70,40);

    // Add manual button
    btnManual = cp5.addButton("manual", 1, 10, 51, 150, 30);

    // Add Light On/Off Toggle
    togLight = cp5.addToggle("light")
      .setPosition(300, 50)
        .setSize(50, 20)
          //.setState(false)          // Enabling this caused errors (seems to work fine without it)
          .setMode(ControlP5.SWITCH)
            .setVisible(false);

    // Add Write to File Toggle
    togWrite = cp5.addToggle("write2File")
      .setPosition(300, 90)
        .setSize(50, 20)
          //.setState(false)        // Enabling this caused errors (seems to work fine without it)
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
  }  // End GUI Constructor


  /****************/
  /*  Manual Mode */
  /****************/

  private boolean manualMode() {
    if (!this.manualMode) { 
      this.manualMode = true;

      // pretend a filename as been entered but just skip creating it.
      gotName = true;

      // hide input textfield
      cp5.controller("textA").setVisible(false);
    }
    else {
      this.manualMode = false;
      gotName = false;

      // show textfield that was hidden
      textFilename.setVisible(true);
      togLight.setVisible(false);
      togWrite.setVisible(false);
      labLight.setVisible(false);
      labWrite.setVisible(false);
    }

    return manualMode;
  } // End manualMode()


  boolean getManualMode() {
    return this.manualMode;
  }


  private void userConfirm() {    // Are you sure you want to do <whatever triggered this method>?
    background(0);

    /* Print message to Window */    // If this was implemented as cp5 object then could call from outside draw()....
    textFont(fontMessage, 18);  
    fill (255);
    textAlign(CENTER);
    text("Are you sure?", width/2, 20);

  } //END userConfirm()

  void lightOn() {

    labLight.setText("ON");

    if (togLight.getState() == false) {
      togLight.setState(true);
    }
    if (togWrite.getState() == true) {
      file.println("# Light ON");    // Will this work? Calling Outer Class?
    }
  } // END lightOn()

  void lightOff() {

    labLight.setText("OFF");

    if (togLight.getState() == true) {
      togLight.setState(false);
    }
    if (togWrite.getState() == true) {
      file.println("# Light OFF");    // Will this work?  Calling Outer Class?
    }
  } // END lightOff()



  public boolean getLightState() {    // Return if light (toggle) is on or off. 
      return togLight.getState();
  }


  /********************************/
  /**** Private GUI FUNCTIONS  ****/
  /*********************************/
  // for every change (a textfield event confirmed with a return) in textfield textA,
  // function textA will be invoked
  void textA(String theValue) {
   
  if (gotName == false) {   // If we have not already started writing the file
      //println("### got an event from textA : "+theValue);
      String fileName = theValue;
      gotName = true;    
      savePath = fileName;  // Can add File Path as is just saves it to current directory
  

      file = createWriter(savePath);          // Create file to write to write to at defined
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
    else if (gotName == true) { // we must rename the file
      rename = true;
      String fileName = theValue;

      // Strip savePath and save to same folder as you browsed to.
      int lastDiv;
      if (OSname.equals("Mac OS X")) {
        lastDiv = savePath.lastIndexOf('/');
      } 
      else if (OSname.equals("Windows XP") || OSname.equals("Windows 7")) {
        lastDiv = savePath.lastIndexOf('\\');
      } 
      else {
        lastDiv = 0; // Delete the whole things and just save it to current directory. 
      }
      savePath2 = savePath.substring(0,lastDiv+1);
      savePath2 += fileName;   // Can add File Path as is just saves it to current directory
    }
  } // END textA()

  // Browse using system dialog for location to save data file
  void browse(int theValue) {
      println("inBrowse");
      savePath = selectOutput("Choose a Location and Filename to Save Data to");
      if (savePath == null) {
        // If a file was not selected
        println("No output file was selected...");
      } else {
        // If a file was selected, print path to folder
        println(savePath);
      }

      btnBrowse.setLock(true); // Lock the button so that you cannot 
                               //stall the program latter by pushing it
      btnBrowse.setColorBackground(color(23,80,70));
      //btnBrowse.setColorBackground(color(0,52,77));
  }




  // actions to be executed when the manual button is clicked.
  public void manual(int theValue) {

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
      btnBrowse.setVisible(false);

      ask = true;                // Sends draw() into loop specified by GUI method userConfirm();
    } 
    else {
      gui.manualMode();
    }
  } // END manual()

  void yes(int theValue) {
    ask = false;
    gui.manualMode();
    btnYes.setVisible(false);
    btnNo.setVisible(false);
    btnManual.setVisible(true);
    togLight.setVisible(true);
    togWrite.setVisible(true);
    labLight.setVisible(true);
    labWrite.setVisible(true);
    btnBrowse.setVisible(true);
    textFilename.setVisible(true);
  } // END yes()

  void no(int theValue) {
    ask = false;
    btnYes.setVisible(false);
    btnNo.setVisible(false);
    btnManual.setVisible(true);
    textFilename.setVisible(true);
    togLight.setVisible(false);
    togWrite.setVisible(false);
    labLight.setVisible(false);
    labWrite.setVisible(false);
  } // END no()


  void light(boolean toggleValue) {
    if (togLight.getState() == true) {
      this.lightOn();
      main.this.lightOn();
      //println("lighton!");  // Debugging only
    } 
    else {
      this.lightOff();
      main.this.lightOff();
      //println("lightoff!");  // Debugging only
    }
  } // END light()

  void write2File(boolean toggleValue) {
    if (togWrite.getState() == true) {
      cp.copyString("X");                    // Replace contents of Clipboard with "X"
      // Will this work since the cp object is in outer class?
      labWrite.setText("ON");
      println("writeon!");
    } 
    else if (togWrite.getState() == false) {
      cp.copyString("Y");                    // Replace contents of Clipboard with "Y"
      // Will this work since the cp object is in outer class?
      labWrite.setText("OFF");                    
      println("writeOFF!");
    }
  } //END write2File()
} // END of GUI Class

