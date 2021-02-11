import org.apache.commons.lang3.tuple.Pair;

abstract class Board implements DataSource {

    private FixedStack<double[]> accumulatedData = new FixedStack<double[]>();
    private double[][] dataThisFrame;
    private boolean capturingMarks;
    private PacketLossTracker packetLossTracker;

    // accessible by all boards, can be returned as valid empty data
    protected double[][] emptyData;

    @Override
    public boolean initialize() {
        boolean res = initializeInternal();

        double[] fillData = new double[getTotalChannelCount()];
        accumulatedData.setSize(getCurrentBoardBufferSize());
        accumulatedData.fill(fillData);

        emptyData = new double[getTotalChannelCount()][0];

        packetLossTracker = setupPacketLossTracker();

        return res;
    }

    @Override
    public void uninitialize() {
        uninitializeInternal();
    }

    @Override
    public void startStreaming() {
        packetLossTracker.onStreamStart();
    }

    @Override
    public void stopStreaming() {
        
        // empty
    }

    @Override
    public void update() {
        int channelCount = getTotalChannelCount();
        // Analog channel on Cyton and Battery channel on Galea
        int markerChannel = getTimestampChannel() - 1;

        updateInternal();

        dataThisFrame = getNewDataInternal();
        int numSamples = dataThisFrame[0].length;
        if (numSamples > 0) {
            println("getdata returned " + numSamples + " samples of " + channelCount + " channels.  cb = " + (numSamples * channelCount * 8));
            println("auxInputExe: " + argumentParser.auxInputExecutable + "  Running: " + auxInputRunning);
        }


        if (argumentParser.auxInputExecutable != null) {
            for (int i = 0; i < numSamples; i++) {
                double marker = auxInputRunning ? readMarker() : 0.0;       // readMarker function also sets markerTimestamp global variable
                if (markerTimestamp != 0.0) {
                    if (marker < 0) {
                        // Start capturing after first negative mark (-100 or start input)
                        // and stop capturing after second negative mark (-200 or end input)
                        capturingMarks = !capturingMarks;
                        println("Capturing marks: " + capturingMarks + "  Mark: " + marker);
                        dataThisFrame[markerChannel][i] = 0.0;
                        continue;
                    }

                    if (capturingMarks) {
                        double timestamp = dataThisFrame[getTimestampChannel()][i];
                        double delta = timestamp - markerTimestamp;
                        if (marker != 0.0) {
                            // Scale numbers for display in analog channel
                            marker = ((marker * marker) + 1) * 100.0;
                            println("Marker: " + marker + "  TimeStamp: " + timestamp + "  Delta: " + delta);
                        }
                    }
                }
                else if (marker != 0.0) {
                    marker = ((marker * marker) + 1) * 100.0;
                }

                dataThisFrame[markerChannel][i] = marker;
            }
        }

        for (int i = 0; i < dataThisFrame[0].length; i++) {
            double[] newEntry = new double[channelCount];
            for (int j = 0; j < channelCount; j++) {
                newEntry[j] = dataThisFrame[j][i];
            }
            accumulatedData.push(newEntry);
        }

        if( packetLossTracker != null) {
            //TODO: make all API including getNewDataInternal() return List<double[]> 
            // and we can just pass dataThisFrame here.
            packetLossTracker.addSamples(getData(dataThisFrame[0].length));
        }
    }

    @Override
    public int getNumEXGChannels() {
        return getEXGChannels().length;
    }

    // returns all the data this board has received in this frame
    @Override
    public double[][] getFrameData() {
        return dataThisFrame;
    }

    @Override
    public List<double[]> getData(int maxSamples) {
        int endIndex = accumulatedData.size();
        int startIndex = max(0, endIndex - maxSamples);

        return accumulatedData.subList(startIndex, endIndex);
    }

    public String[] getChannelNames() {
        String[] names = new String[getTotalChannelCount()];
        Arrays.fill(names, "Other");

        names[getTimestampChannel()] = "Timestamp";
        names[getSampleIndexChannel()] = "Sample Index";

        int[] exgChannels = getEXGChannels();
        for (int i=0; i<exgChannels.length; i++) {
            names[exgChannels[i]] = "EXG Channel " + i;
        }

        addChannelNamesInternal(names);
        return names;
    }

    public PacketLossTracker getPacketLossTracker() {
        return packetLossTracker;
    }

    public abstract boolean isConnected();

    public abstract boolean isStreaming();

    public abstract Pair <Boolean, String> sendCommand(String command);

    // ***************************************
    // protected methods implemented by board

    // implemented by each board class and used internally here to accumulate the FixedStack
    // and provide with public interfaces getFrameData() and getData(int)
    protected abstract double[][] getNewDataInternal();

    protected abstract boolean initializeInternal();

    protected abstract void uninitializeInternal();

    protected abstract void updateInternal();

    protected abstract void addChannelNamesInternal(String[] channelNames);

    protected abstract PacketLossTracker setupPacketLossTracker();
};
