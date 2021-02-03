import brainflow.*;

class ArgumentParser {
    public boolean valid;
    public boolean consumed;
    public String sessionName;
    public int dataSource;
    public BoardProtocol boardProtocol;
    public int numberOfChannels;
    public String serialPort;
    public String ipAddress;
    public int ipPort;
    public String auxInputExecutable;
    public String[] auxInputCommandLineTokens;
    public File defaultUserSettingsFile;
    public String playBackFile;
    public BoardIds boardId;
    public int[] allChannels;
    public int[] eegChannels;
    public int[] emgChannels;
    public int[] eogChannels;
    public boolean eegChannelsEnabled;
    public boolean emgChannelsEnabled;
    public boolean eogChannelsEnabled;

    // Parses any command line arguments.  Returns false if none found or args
    // given are invalid.
    //
    public boolean init(String[] args) {
        valid = false;
        consumed = false;
        if (args == null || args.length == 0) {
            return false;
        }
        File file  = new File(sketchPath() + File.separator + "bciGame" + File.separator + "bcigame.exe");
        println("ArgumentParser.init called with " + args.length + " args");
        println("SketchPath: " + sketchPath());
        if (file.exists() && file.canExecute()) {
            auxInputExecutable = file.getAbsolutePath();
            println("AuxInputExe: " + auxInputExecutable);
        }

        // Default value is a board we don't support so we can tell whether or not args
        // specified one of: --synthetic, --galea, --cyton or --playback
        sessionName = directoryManager.getFileNameDateTime();
        dataSource = -1;
        numberOfChannels = 8;
        serialPort = null;
        ipAddress = "192.168.4.1";
        ipPort = 6677;
        defaultUserSettingsFile = null;
        playBackFile = null;

        boolean boardTypeDetermined = false;
        boolean wifi = false;
        boolean badArgSeen = false;
        String settingsFilePrefix = null;
        for (int i = 0; i < args.length; i++) {
            String arg = args[i];
            String possibleValue  = null;
            boolean havePossibleValue = false;
            if (i+1 < args.length) {
                possibleValue = args[i+1];
                havePossibleValue = possibleValue.length() > 0;
            }
            println("  arg[" + i + "]: '" + arg + "'" + (havePossibleValue ? ("  possibleValue: '" + possibleValue + "'") : ""));
            if (arg.equalsIgnoreCase("--debug")) {
                isVerbose = true;
            }
            else
            if (havePossibleValue && arg.equalsIgnoreCase("--sessionname")) {
                sessionName = possibleValue;
                i += 1;
            }
            else
            if (havePossibleValue && arg.equalsIgnoreCase("--auxInput")) {
                auxInputCommandLineTokens = possibleValue.split("[\\s]");
                if (auxInputCommandLineTokens.length > 0) {
                    file= new File(auxInputCommandLineTokens[0]);
                    i += 1;
                    if (file.exists() && file.canExecute()) {
                        auxInputExecutable = file.getAbsolutePath();
                        auxInputCommandLineTokens[0] = auxInputExecutable;
                    }
                    continue;
                }

                println(arg + " " + possibleValue + " - path does not exist or is not an executable file.");
                badArgSeen = true;
            }
            else
            if (!boardTypeDetermined && arg.equalsIgnoreCase("--synthetic")) {
                boardId = BoardIds.SYNTHETIC_BOARD;
                dataSource = DATASOURCE_SYNTHETIC;
                boardTypeDetermined = true;
                numberOfChannels = 16;
                settingsFilePrefix = "SynthSixteen";
                if (havePossibleValue) {
                    numberOfChannels = int(possibleValue);
                    i += 1;
                }
            }
            else
            if (!boardTypeDetermined && (arg.equalsIgnoreCase("--galea"))) {
                boardId = BoardIds.GALEA_BOARD;
                dataSource = DATASOURCE_GALEA;
                boardTypeDetermined = true;
                wifi = true;
                numberOfChannels = 16;
                settingsFilePrefix = "Galea";
            }
            else
            if (!boardTypeDetermined && arg.equalsIgnoreCase("--cyton")) {
                boardId = BoardIds.CYTON_BOARD;
                dataSource = DATASOURCE_CYTON;
                boardProtocol = BoardProtocol.SERIAL;
                boardTypeDetermined = true;
                numberOfChannels = 8;
                serialPort = findFirstOpenBCIDongle();
                settingsFilePrefix = "Cyton";
            }
            else
            if (!boardTypeDetermined && arg.equalsIgnoreCase("--playback") && havePossibleValue) {
                file = new File(possibleValue);
                i += 1;
                if (file.isDirectory()) {
                    File files[] = file.listFiles();
                    if (files.length > 0) {
                        playBackFile = files[0].getAbsolutePath();
                    }
                }
                else
                if (file.exists()) {
                    playBackFile = file.getAbsolutePath();
                }

                if (playBackFile != null) {
                    dataSource = DATASOURCE_PLAYBACKFILE;
                    boardTypeDetermined = true;
                    settingsFilePrefix = "Playback";
                }
            }
            else    // --wifi only valid for Cyton boards
            if (boardTypeDetermined && dataSource == DATASOURCE_CYTON && arg.equalsIgnoreCase("--wifi")) {
                wifi = true;
                boardProtocol = BoardProtocol.WIFI;
            }
            else    // --daisy only valid for Cyton boards
            if (boardTypeDetermined && dataSource == DATASOURCE_CYTON && arg.equalsIgnoreCase("--daisy")) {
                boardId = BoardIds.CYTON_DAISY_BOARD;
                numberOfChannels = 16;
                settingsFilePrefix = "Daisy";
            }
            else
            if (havePossibleValue && boardTypeDetermined && !wifi && arg.equalsIgnoreCase("--port")) {
                serialPort = possibleValue;
                i += 1;
            }
            else
            if (havePossibleValue && boardTypeDetermined && wifi && arg.equalsIgnoreCase("--ipAddress")) {
                ipAddress = possibleValue;
                i += 1;
            }
            else
            if (havePossibleValue && boardTypeDetermined && wifi && arg.equalsIgnoreCase("--ipPort")) {
                ipPort = int(possibleValue);
                i += 1;
            }
            else {
                println("'" + arg + "' is unexpected.");
                badArgSeen = true;
            }
        }

        if (badArgSeen || !boardTypeDetermined) {
            println("usage: OpenBCI_GUI.exe [--sessionName <folderName>] [--auxInput <commandLine>]");
            println("                       [--synthetic <nChannels>] |");
            println("                        --galea [--ipAddress <ipAddress>] [--ipPort <portNumber])] |");
            println("                        --cyton [--daisy] ([--port <comport>] | [--wifi] [--ipAddress <ipAddress>] [--ipPort <portNumber])] |");
            println("                        --playBack <playbackFolder>)");
            valid = false;

            // Copy sample data to the Users' Documents folder +  create Recordings folder
            directoryManager.init(true);
        }
        else {
            if (dataSource == DATASOURCE_CYTON && wifi) {
                boardId = numberOfChannels == 16 ? BoardIds.CYTON_DAISY_WIFI_BOARD : BoardIds.CYTON_WIFI_BOARD;
            }

            allChannels = new int[numberOfChannels];
            for (int i=0; i<numberOfChannels; i++) {
                allChannels[i] = i + 1;
            }

            if (dataSource == DATASOURCE_GALEA) {
                eegChannels = new int[] {1, 2, 3, 4, 5, 6, 7, 8, 10, 15};
                emgChannels = new int[] {9, 12, 14, 16};
                eogChannels = new int[] {11, 13};
            }

            println("Debug: " + isVerbose);
            println("SessionName: " + sessionName);
            println("DataSource: " + dataSource);
            println("BoardProtocol: " + boardProtocol);
            if (wifi) {
                println("ipAddress: " + ipAddress);
                println("ipPort: " + ipPort);
            }
            else
            if (dataSource == DATASOURCE_CYTON) {
                println("SerialPort: " + serialPort);
            }

            println("#Channels: " + numberOfChannels);
            if (dataSource == DATASOURCE_PLAYBACKFILE) {
                println("PlayBack file: " + playBackFile);
            }

            if (auxInputExecutable != null) {
                println("Aux Input executable: " + auxInputExecutable);
            }

            // Copy sample data to the Users' Documents folder +  create Recordings folder
            directoryManager.init(true);

            directoryManager.setSessionName(sessionName);

            if (settingsFilePrefix != null) {
                defaultUserSettingsFile = new File(directoryManager.getSettingsPath() + File.separator + settingsFilePrefix + "UserSettings.json");
                println("Default user settings file: " + defaultUserSettingsFile.getAbsolutePath() + "  Exists: " + str(defaultUserSettingsFile.exists()));
            }

            valid = true;
        }

        return valid;
    }

    private String findFirstOpenBCIDongle() {
        final String[] names = {"FT231X USB UART", "VCP"};
        final SerialPort[] comPorts = SerialPort.getCommPorts();
        for (SerialPort comPort : comPorts) {
            for (String name : names) {
                if (comPort.toString().startsWith(name)) {
                    // on macos need to drop tty ports
                    if (isMac() && comPort.getSystemPortName().startsWith("tty")) {
                        continue;
                    }
                    String found = "";
                    if (isMac() || isLinux()) found += "/dev/";
                    found += comPort.getSystemPortName();
                    println("ArgumentParser: Found Cyton Dongle on COM port: " + found);
                    return found;
                }
            }
        }

        return null;
    }

    public boolean setSessionDefaults() {
        if (!valid || consumed) {
            return false;
        }

        println("ArgumentParser: Autostart session " + dataSource);

        eegDataSource = dataSource;
        if (dataSource == DATASOURCE_PLAYBACKFILE) {
            playbackData_fname = playBackFile;
        }

        selectedProtocol = boardProtocol;
        wifi_ipAddress = ipAddress;
        openBCI_portName = serialPort;
        if (selectedProtocol == BoardProtocol.WIFI) {
            controlPanel.setWiFiDefaultStaticIP();
        }
        nchan = numberOfChannels;
        consumed = true;
        return true;
    }

    public void switchToPlaybackFile(String filePath) {
        println("Setting datasource to PLAYBACKFILE - " + filePath);
        playBackFile = filePath;
        dataSource = DATASOURCE_PLAYBACKFILE;
        defaultUserSettingsFile = new File(directoryManager.getSettingsPath() + File.separator + "PlaybackUserSettings.json");
        println("Default user settings file: " + defaultUserSettingsFile.getAbsolutePath() + "  Exists: " + str(defaultUserSettingsFile.exists()));

        // Arguments to consume now.
        consumed = false;
    }
}

public class Command {

  protected final ArrayList<String> outputBuffer = new ArrayList<String>();
  protected final ArrayList<String> errorBuffer = new ArrayList<String>();
  protected final Runtime runtime = Runtime.getRuntime();

  public String command;
  public boolean success;

  public Command(final String theCommand) {
    command = theCommand;
  }

  /**
   * Runs the command. Returns true if the command was successful.
   * The output of the command can be accessed by calling getOutput().
   *
   * @return true if the command ran successfully,
   * false if there was an error running the command.
   */
  public boolean run() {
    success = false;
    outputBuffer.clear();
    errorBuffer.clear();

     try {
      final Process process = runtime.exec(command);

      final BufferedReader
        out = new BufferedReader(new InputStreamReader(process.getInputStream())),
        err = new BufferedReader(new InputStreamReader(process.getErrorStream()));

      String read;
      while ((read = out.readLine()) != null)  outputBuffer.add(read);

      while ((read = err.readLine()) != null)  errorBuffer.add(read);

      success = process.waitFor() == 0;
    }
    catch (final IOException e) {
      System.err.println("COMMAND ERROR: " + e.getMessage());
    }
    catch (final InterruptedException e) {
      System.err.println("COMMAND INTERRUPTED: " + e.getMessage());
    }

    return success;
  }

  /**
   * Returns each line of the command's output as a List of String objects.
   * Useful if you need to capture the results from running a command.
   */
  @SuppressWarnings("unchecked") public List<String> getOutput() {
    return (List<String>) outputBuffer.clone();
  }

  @SuppressWarnings("unchecked") public List<String> getErrors() {
    return (List<String>) errorBuffer.clone();
  }

  /**
   * Returns the command String being used.
   *
   * @return String
   */
  @Override public String toString() {
    return command + " returned " + success;
  }
}
