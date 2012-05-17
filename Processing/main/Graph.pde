/*****  Graph Class *****/

// By Justin Silverman
// Curently not to usefull outside of use with PolyNIPAM Experiment

class Graph {
  private ArrayList<Integer> graph;

  Graph() {    // Class Constructor
    graph = new ArrayList<Integer>(Collections.nCopies(200, 0)); // Set 200 0s
  }

  void drawGraph() { // Draw Graph (each line stored in ArrayList graph.
   
    stroke(127, 34, 255);             // draw this line
    for (int i = graph.size(); i>0; i--) {
      line(i*2, height, i*2, height - graph.get(i - 1));
    }
  }

  void pushVal(int dataLength) {
    graph.remove(0);
    graph.add(dataLength);
  }
}

