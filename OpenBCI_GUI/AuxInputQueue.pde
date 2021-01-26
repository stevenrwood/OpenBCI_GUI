//
// This file implements a socket server to receive events from an auxiliary input process, which is launched
// right after socket server is instantiated.  Aux input events consist of a single double that is written to
//

private UDP auxInputServer;
private int auxInputPort = 6666;
private Process auxInputProcess;
private volatile boolean auxInputEnabled = false;
private volatile int nAvailableEvents = 0;
private volatile int readIndex = 0;
private volatile int writeIndex = 0;
private int maxGameEvents = 64;
private double[][] gameEvents = new double[3][maxGameEvents];

public boolean InitializeAuxInput(String executablePath)
{
  try{
    // Start the server that will accept game event messages from bciGame.exe
    thread("serverThread");

    // Now launch bciGame.exe so it can connect to our server
    List<String> args = new LinkedList<String>();
    args.add(executablePath);
    args.add("--game");
    args.add("FollowMe");
    args.add("--logFolder");
    args.add(directoryManager.getSessionFolderPath());
    args.add("--stimulusDelay");
    args.add("1000");
    args.add("--feedbackDelay");
    args.add("500");
    args.add("--trialCount");
    args.add("10");
    args.add("--openBCIPort");
    args.add(str(auxInputPort));
    ProcessBuilder pb = new ProcessBuilder(args);
    verbosePrint("Launching " + pb.command());
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

  auxInputEnabled = false;
  return false;
}

public void FinalizeAuxInput()
{
    if (auxInputEnabled) {
        auxInputEnabled = false;
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
  auxInputEnabled = true;
  while (auxInputEnabled && auxInputServer.port() != -1) {
    System.out.println("Listening on " + auxInputServer.address() + ":" + auxInputServer.port());
    auxInputServer.listen();
  }
}

// Called by UDP listen handler for each message received.
void receiveGameEvent(byte[] message)
{
  String str = new String(message);
  System.out.println("Received " + message.length + " bytes.  '" + str + "'");
  StringTokenizer st = new StringTokenizer(str, ",");
  if (st.countTokens() != 3)
    return;

  for (int i=0; i<3; i++)
    gameEvents[i][writeIndex] = Double.parseDouble(st.nextToken());
  writeIndex = (writeIndex + 1) % maxGameEvents;
  nAvailableEvents += 1;
  System.out.println("nAvailableEvents: " + nAvailableEvents);
}

public double[] readAuxInput()
{
  if (nAvailableEvents == 0)
    return null;

  double[] ge = new double[3];
  for (int i=0; i<3; i++)
    ge[i] = gameEvents[i][readIndex];
  readIndex = (readIndex + 1) % maxGameEvents;
  nAvailableEvents -= 1;
  if (ge[1] == -1)
  {
    FinalizeAuxInput();
  }
  return ge;
}
