//
// This file implements a socket server to receive events from an auxiliary input process, which is launched
// right after socket server is instantiated.  Aux input events consist of a single double that is written to
//

private UDP auxInputServer;
private int auxInputPort = 6666;
private Process auxInputProcess;
private volatile boolean auxInputRunning = false;
private volatile int nAvailableEvents = 0;
private volatile int readIndex = 0;
private volatile int writeIndex = 0;
private volatile double marker = 0.0;
private volatile double markerTimestamp = 0.0;
private int maxGameEvents = 64;
private double[][] gameEvents = new double[2][maxGameEvents];

public boolean InitializeAuxInput(String executablePath)
{
  try{
    // Start the server that will accept game event messages from bciGame.exe
    thread("serverThread");

    // Get command line args and substitute session folder path and UDP server port
    // as needed.
    List<String> args = new LinkedList<String>();
    for (int i=0; i<argumentParser.auxInputCommandLineTokens.length; i++) {
        String arg = argumentParser.auxInputCommandLineTokens[i];
        if (arg.equalsIgnoreCase("$session")) {
            args.add(directoryManager.getSessionFolderPath());
        } else if (arg.equalsIgnoreCase("$bciport")) {
            args.add(str(auxInputPort));
        } else {
            args.add(arg);
        }
    }
    // Now launch aux input process so it can connect to our server
    ProcessBuilder pb = new ProcessBuilder(args);
    println("Launching " + pb.command());
    pb.inheritIO();
    auxInputProcess = pb.start();
    if (auxInputProcess != null) {
        return true;
    }
  } catch(Exception ex){
    /* Error output when native binary not present */
    System.out.println("Failed to initialize aux input queue" + ex.getMessage());
    ex.printStackTrace();
    System.exit(0);
  }

  auxInputRunning = false;
  return false;
}

public void FinalizeAuxInput()
{
    if (auxInputRunning) {
        auxInputRunning = false;
        auxInputServer.close();
        auxInputProcess.destroy();
        auxInputProcess = null;
    }
}

// Separate thread to listen for UDP datagrams from bciGame.exe application
void serverThread() {
  auxInputServer = new UDP(this, auxInputPort, "127.0.0.1");
  auxInputServer.setBuffer(1024);
  auxInputServer.log(true);
  auxInputServer.setReceiveHandler("receiveGameEvent");
  auxInputRunning = true;
  while (auxInputRunning && auxInputServer.port() != -1) {
    System.out.println("Listening on " + auxInputServer.address() + ":" + auxInputServer.port());
    auxInputServer.listen();
  }
}

// Called by UDP listen handler for each message received.
void receiveGameEvent(byte[] message)
{
  String str = new String(message);
  System.out.println("Received " + message.length + " bytes.  '" + str + "'");
  String[] tokens = str.split("[,]");
  if (tokens.length != 2) {
    return;
  }

  double gameEvent = Double.parseDouble(tokens[0]);
  double timestamp = Double.parseDouble(tokens[1]);
  System.out.println("Game event: " + gameEvent + " @ " + timestamp);
  gameEvents[0][writeIndex] = gameEvent;
  gameEvents[1][writeIndex] = timestamp;
  writeIndex = (writeIndex + 1) % maxGameEvents;
  nAvailableEvents += 1;
  System.out.println("nAvailableEvents: " + nAvailableEvents);
}

public double readMarker()
{
  if (nAvailableEvents == 0) {
    markerTimestamp = 0.0;
    return marker;
  }

  marker = gameEvents[0][readIndex];
  markerTimestamp = gameEvents[1][readIndex];
  readIndex = (readIndex + 1) % maxGameEvents;
  nAvailableEvents -= 1;
  System.out.println("Returning marker: " + marker);

  if (marker == -2)
  {
    FinalizeAuxInput();
  }

  return marker;

}
