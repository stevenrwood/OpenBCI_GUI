class DataSourcePlayback implements DataSource, AccelerometerCapableBoard, AnalogCapableBoard, DigitalCapableBoard, EDACapableBoard, PPGCapableBoard, BatteryInfoCapableBoard, FileBoard  {
    private String playbackFilePath;
    private ArrayList<double[]> rawData;
    private int currentSample;
    private ArrayList<double[]> markData;
    private int currentMarkIndex;
    private int timeOfLastUpdateMS;
    private String underlyingClassName;
    private Integer batteryChannelCache = null;
    private int numNewSamplesThisFrame;

    private boolean initialized = false;
    private boolean streaming = false;
    
    private Board underlyingBoard = null;
    private int sampleRate = -1;
    private boolean containsMarks;

    DataSourcePlayback(String filePath) {
        playbackFilePath = filePath;
    }

    @Override
    public boolean initialize() {
        currentSample = 0;
        String[] lines = loadStrings(playbackFilePath);
        
        if(!parseHeader(lines)) {
            return false;
        }
        if(!instantiateUnderlyingBoard()) {
            return false;
        }
        if(!parseData(lines)) {
            return false;
        }

        return true;
    }

    @Override
    public void uninitialize() {
        initialized = false;
    }

    protected boolean parseHeader(String[] lines) {
        for (String line : lines) {
            if (!line.startsWith("%")) {
                break; // reached end of header
            }

            //only needed for synthetic board. can delete if we get rid of synthetic board.
            if (line.startsWith("%Number of channels")) {
                int startIndex = line.indexOf('=') + 2;
                String nchanStr = line.substring(startIndex);
                int chanCount = Integer.parseInt(nchanStr);
                updateToNChan(chanCount); // sythetic board depends on this being set before it's initialized
            }

            // some boards have configurable sample rate, so read it from header
            if (line.startsWith("%Sample Rate")) {
                int startIndex = line.indexOf('=') + 2;
                int endIndex = line.indexOf("Hz") - 1;

                String hzString = line.substring(startIndex, endIndex);
                sampleRate = Integer.parseInt(hzString);
            }

            if (line.startsWith("%AuxInput")) {
                containsMarks = true;
                int startIndex = line.indexOf('=') + 2;
                argumentParser.auxInputExecutable = line.substring(startIndex);
            }

            // used to figure out the underlying board type
            if (line.startsWith("%Board")) {
                int startIndex = line.indexOf('=') + 2;
                underlyingClassName = line.substring(startIndex);
            }
        }

        boolean success = sampleRate > 0 && underlyingClassName != "";
        if(!success) {
            outputError("Playback file does not contain the required header data.");
        }
        return success;
    }

    protected boolean instantiateUnderlyingBoard() {
        try {
            // get class from name
            Class<?> boardClass = Class.forName(underlyingClassName);
            // find default contructor (since this is processing, PApplet is required arg in all constructors)
            Constructor<?> constructor = boardClass.getConstructor(OpenBCI_GUI.class);
            underlyingBoard = (Board)constructor.newInstance(ourApplet);
        } catch (Exception e) {
            outputError("Cannot instantiate underlying board of class " + underlyingClassName);
            println(e.getMessage());
            e.printStackTrace();
            return false;
        }

        return underlyingBoard != null;
    }

    protected boolean parseData(String[] lines) {
        int dataStart;
        // set data start to first line of data (skip header)
        for (dataStart = 0; dataStart < lines.length; dataStart++) {
            String line = lines[dataStart];
            if (!line.startsWith("%")) {
                dataStart++; // skip column names
                break;
            }
        }

        int dataLength = lines.length - dataStart;
        rawData = new ArrayList<double[]>(dataLength);
        
        markData = new ArrayList<double[]>(1000);
        currentMarkIndex = -1;
        double previousMarkValue = 0.0;
        int markChannel = getTimestampChannel() - 1;

        for (int iData=0; iData<dataLength; iData++) {
            String line = lines[dataStart + iData];
            String[] valStrs = line.split(",");

            double[] row = new double[getTotalChannelCount()];
            for (int iCol = 0; iCol < getTotalChannelCount(); iCol++) {
                row[iCol] = Double.parseDouble(valStrs[iCol]);
                if (containsMarks && iCol == markChannel && row[iCol] != 0.0 && row[iCol] != previousMarkValue) {
                    previousMarkValue = row[iCol];
                    double[] markInfo = new double[] {(double) iData, previousMarkValue};
                    println("MarkInfo - Index:" + markInfo[0] + "  Value: " + markInfo[1]);
                    markData.add(markInfo);
                }
            }
            rawData.add(row);
        }
        markData.trimToSize();
        println("#marks found: " + markData.size());

        return true;
    }

    @Override
    public void update() {
        if (!streaming) {
            return; // do not update
        }

        float sampleRateMS = getSampleRate() / 1000.f;

        int timeElapsedMS = millis() - timeOfLastUpdateMS;
        numNewSamplesThisFrame = floor(timeElapsedMS * sampleRateMS);

        // account for the fact that each update will not coincide with a sample exactly. 
        // to keep the streaming rate accurate, we increment the time of last update
        // based on how many samples we incremented this frame.
        timeOfLastUpdateMS += numNewSamplesThisFrame / sampleRateMS;

        currentSample += numNewSamplesThisFrame;
        
        if (endOfFileReached()) {
            topNav.stopButtonWasPressed();
        }

        // don't go beyond raw data array size
        currentSample = min(currentSample, getTotalSamples());
    }

    @Override
    public void startStreaming() {
        streaming = true;
        timeOfLastUpdateMS = millis();
    }

    @Override
    public void stopStreaming() {
        streaming = false;
    }

    @Override
    public boolean isStreaming() {
        return streaming;
    }

    @Override
    public int getSampleRate() {
        return sampleRate;
    }

    @Override
    public void setEXGChannelActive(int channelIndex, boolean active) {
        outputWarn("Deactivating channels is not possible for Playback board.");
    }

    @Override
    public boolean isEXGChannelActive(int channelIndex) {
        return true;
    }
    
    @Override
    public int[] getEXGChannels() {
        return underlyingBoard.getEXGChannels();
    }
    
    @Override
    public int getNumEXGChannels() {
        return getEXGChannels().length;
    }

    @Override
    public int getTimestampChannel() {
        return underlyingBoard.getTimestampChannel();
    }

    @Override
    public int getSampleIndexChannel() {
        return underlyingBoard.getSampleIndexChannel();
    }

    public int getTotalSamples() {
        return rawData.size();
    }

    public float getTotalTimeSeconds() {
        return float(getTotalSamples()) / float(getSampleRate());
    }

    public int getCurrentSample() {
        return currentSample;
    }

    public float getCurrentTimeSeconds() {
        return float(getCurrentSample()) / float(getSampleRate());
    }

    public void goToIndex(int index) {
        currentSample = index;
    }

    @Override
    public int getTotalChannelCount() {
        return underlyingBoard.getTotalChannelCount();
    }

    @Override
    public double[][] getFrameData() {
        double[][] array = new double[getTotalChannelCount()][numNewSamplesThisFrame];
        List<double[]> list = getData(numNewSamplesThisFrame);
        for (int i = 0; i < numNewSamplesThisFrame; i++) {
            for (int j = 0; j < getTotalChannelCount(); j++) {
                array[j][i] = list.get(i)[j];
            }
        }
        return array;
    }

    @Override
    public List<double[]> getData(int maxSamples) {
        int firstSample = max(0, currentSample - maxSamples);
        List<double[]> result = rawData.subList(firstSample, currentSample);

        // if needed, pad the beginning of the array with empty data
        if (maxSamples > currentSample) {
            int sampleDiff = maxSamples - currentSample;

            double[] emptyData = new double[getTotalChannelCount()];
            ArrayList<double[]> newResult = new ArrayList(maxSamples);
            for (int i=0; i<sampleDiff; i++) {
                newResult.add(emptyData);
            }
            
            newResult.addAll(result);
            return newResult;
        }

        return result;
    }

    @Override
    public boolean isAccelerometerActive() { 
        return underlyingBoard instanceof AccelerometerCapableBoard;
    }

    @Override
    public void setAccelerometerActive(boolean active) {
        // nothing
    }

    @Override
    public boolean canDeactivateAccelerometer() {
        return false;
    }

    @Override
    public int[] getAccelerometerChannels() {
        if (underlyingBoard instanceof AccelerometerCapableBoard) {
            return ((AccelerometerCapableBoard)underlyingBoard).getAccelerometerChannels();
        }

        return new int[0];
    }

    @Override
    public boolean isAnalogActive() {
        return underlyingBoard instanceof AnalogCapableBoard;
    }

    @Override
    public void setAnalogActive(boolean active) {
        // nothing
    }

    @Override
    public boolean canDeactivateAnalog() {
        return false;
    }

    @Override
    public int[] getAnalogChannels() {
        if (underlyingBoard instanceof AnalogCapableBoard) {
            return ((AnalogCapableBoard)underlyingBoard).getAnalogChannels();
        }

        return new int[0];
    }

    @Override
    public boolean isDigitalActive() {
        return underlyingBoard instanceof DigitalCapableBoard;
    }

    @Override
    public void setDigitalActive(boolean active) {
        // nothing
    }

    @Override
    public boolean canDeactivateDigital() {
        return false;
    }

    @Override
    public int[] getDigitalChannels() {
        if (underlyingBoard instanceof DigitalCapableBoard) {
            return ((DigitalCapableBoard)underlyingBoard).getDigitalChannels();
        }

        return new int[0];
    }

    @Override
    public boolean isEDAActive() {
        return underlyingBoard instanceof EDACapableBoard;
    }

    @Override
    public void setEDAActive(boolean active) {
        // nothing
    }

    @Override
    public int[] getEDAChannels() {
        if (underlyingBoard instanceof EDACapableBoard) {
            return ((EDACapableBoard)underlyingBoard).getEDAChannels();
        }

        return new int[0];
    }

    @Override
    public boolean isPPGActive() {
        return underlyingBoard instanceof PPGCapableBoard;
    }

    @Override
    public void setPPGActive(boolean active) {
        // nothing
    }

    @Override
    public int[] getPPGChannels() {
        if (underlyingBoard instanceof PPGCapableBoard) {
            return ((PPGCapableBoard)underlyingBoard).getPPGChannels();
        }

        return new int[0];
    }

    @Override
    public Integer getBatteryChannel() {
        if (batteryChannelCache == null && underlyingBoard instanceof BatteryInfoCapableBoard) {
            try {
                batteryChannelCache = BoardShim.get_battery_channel(((BoardBrainFlow)underlyingBoard).getBoardIdInt());
            } catch (BrainFlowError e) {
                e.printStackTrace();
            }
        }

        return batteryChannelCache;
    }

    @Override
    public boolean endOfFileReached() {
        return currentSample >= getTotalSamples();
    }


    @Override
    public boolean goToPrevMark() {
        if (currentMarkIndex > 0) {
            currentMarkIndex -= 1;
            goToIndex((int) markData.get(currentMarkIndex)[0]);
            return true;
        }

        return false;
    }

    @Override
    public boolean goToNextMark() {
        if (currentMarkIndex < markData.size() - 1) {
            currentMarkIndex += 1;
            goToIndex((int) markData.get(currentMarkIndex)[0]);
            return true;
        }

        return false;
    }
}
