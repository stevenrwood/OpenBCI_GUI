class DirectoryManager {

    private final String guiDataPath = System.getProperty("user.home")+File.separator+"Documents"+File.separator+"OpenBCI_GUI"+File.separator;
    private final DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss");
    private boolean alternateFolderLayout;
    private String sessionName;
    private String sessionPath;

    DirectoryManager() {
    }

    public String getFileNameDateTime() {
        return dateFormat.format(new Date());
    }
    
    public String getGuiDataPath() {
        return guiDataPath;
    }

    public String getRecordingsPath() {
        return alternateFolderLayout ? guiDataPath : guiDataPath+"Recordings"+File.separator;
    }

    public String getSettingsPath() {
        return alternateFolderLayout ? guiDataPath : guiDataPath+"Settings"+File.separator;
    }

    public String getConsoleDataPath() {
        return alternateFolderLayout ? guiDataPath : guiDataPath+"Console_Data"+File.separator;
    }

    public void setSessionName(String s) {
        sessionName = s;
        sessionPath = getSettingsPath() + sessionName + File.separator;
        File dir = new File(sessionPath);
        println("Session Folder: " + dir.getAbsolutePath());
        dir.mkdirs();
    }

    public String getSessionFolderPath() {
        return sessionPath;
    }

    public String getSessionFilePath(String fileName) {
        return sessionPath + fileName;
    }

    public String getConsoleLogFilePath() {
        String fileName = "Console_" + getFileNameDateTime();
        if (alternateFolderLayout) {
            return getSessionFilePath(fileName + ".log");
        } else {
            return getConsoleDataPath() + fileName + ".txt";
        }
    }

    public void init(boolean _alternateFolderLayout) {
        alternateFolderLayout = _alternateFolderLayout;
        // Create GUI data folder in Users' Documents and copy sample data if it doesn't already exist
        String directoryName = guiDataPath + File.separator + "Sample_Data" + File.separator;
        String guiv4fileName = directoryName + "OpenBCI-sampleData-2-meditation.txt";
        String guiv5fileName = directoryName + "OpenBCI_GUI-v5-meditation.txt";
        File directory = new File(directoryName);
        File guiv4_fileToCheck = new File(guiv4fileName);
        File guiv5_fileToCheck = new File(guiv5fileName);

        if (guiv4_fileToCheck.exists()) {
            //Delete old gui v4 files in Documents folder
            try {
                for (File subFile : directory.listFiles()) {
                    subFile.delete();
                }
                println("OpenBCI_GUI::Setup: Successfully deleted old GUI v4 sample data files!");
            } catch (SecurityException e) {
                println("OpenBCI_GUI::Setup: Error trying to delete old GUI Sample Data in Documents folder.");
            }
        }
        
        if (!guiv5_fileToCheck.exists()) {
            copySampleDataFiles(directory, directoryName);
        } else {
            println("OpenBCI_GUI::Setup: GUI v5 Sample Data exists in Documents folder.");
        }

        // If original folder layout, create Recordings subfolder
        if (!_alternateFolderLayout) {
            makeRecordingsFolder();
        }
    }

    private void copySampleDataFiles(File directory, String directoryName) {
        println("OpenBCI_GUI::Setup: Copying sample data to Documents/OpenBCI_GUI/Sample_Data");
        // Make the entire directory path including parents
        directory.mkdirs();
        try {
            File[] filesFound = new File(dataPath("EEG_Sample_Data")).listFiles();
            //If this pathname does not denote a directory, then listFiles() returns null.
            for (File file : filesFound) {
                if (file.isFile()) {
                    Files.copy(file.toPath(),
                        (new File(directoryName + file.getName())).toPath(),
                        StandardCopyOption.REPLACE_EXISTING);
                }
            }
        } catch (IOException e) {
            println("OpenBCI_GUI::Setup: Error trying to copy Sample Data to Documents directory.");
        }
    }

    private void makeRecordingsFolder() {
        //Create \Documents\OpenBCI_GUI\Recordings\ if it doesn't exist
        String recordingDirString = guiDataPath + File.separator + "Recordings";
        File recDirectory = new File(recordingDirString);
        if (recDirectory.mkdir()) {
            println("OpenBCI_GUI::Setup: Created \\Documents\\OpenBCI_GUI\\Recordings\\");
        }
    }
    
};
