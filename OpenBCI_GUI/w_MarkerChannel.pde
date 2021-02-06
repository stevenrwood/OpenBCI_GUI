
////////////////////////////////////////////////////
//
//  W_MarkerChannel is used to visiualze marker channel values
//
//
///////////////////////////////////////////////////,

class W_MarkerChannel extends Widget {

    //to see all core variables/methods of the Widget class, refer to Widget.pde
    //put your custom variables here...

    private int numMarkerChannelBars;
    float xF, yF, wF, hF;
    float mcPadding;
    float mc_x, mc_y, mc_h, mc_w; // values for actual time series chart (rectangle encompassing all markerChannelBars)
    float plotBottomWell;
    float playbackWidgetHeight;
    int markerChannelBarHeight;

    MarkerChannelBar[] markerChannelBars;

    int[] xLimOptions = {0, 1, 3, 5, 10, 20}; // number of seconds (x axis of graph)
    int[] yLimOptions = {0, 50, 100, 200, 400, 1000, 10000}; // 0 = Autoscale ... everything else is uV

    //Initial dropdown settings
    private int mcInitialVertScaleIndex = 5;
    private int mcInitialHorizScaleIndex = 0;

    W_MarkerChannel(PApplet _parent) {
        super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)

        // Marker Channel settings
        settings.mcVertScaleSave = mcInitialVertScaleIndex; //updates in VertScale_MC()
        settings.mcHorizScaleSave = mcInitialHorizScaleIndex; //updates in Duration_MC()

        //This is the protocol for setting up dropdowns.
        //Note that these 2 dropdowns correspond to the 2 global functions below
        //You just need to make sure the "id" (the 1st String) has the same name as the corresponding function
        addDropdown("VertScale_MC", "Vert Scale", Arrays.asList(settings.mcVertScaleArray), mcInitialVertScaleIndex);
        addDropdown("Duration_MC", "Window", Arrays.asList(settings.mcHorizScaleArray), mcInitialHorizScaleIndex);

        numMarkerChannelBars = 1;

        xF = float(x); //float(int( ... is a shortcut for rounding the float down... so that it doesn't creep into the 1px margin
        yF = float(y);
        wF = float(w);
        hF = float(h);

        plotBottomWell = 45.0; //this appears to be an arbitrary vertical space adds GPlot leaves at bottom, I derived it through trial and error
        mcPadding = 10.0;
        mc_x = xF + mcPadding;
        mc_y = yF + (mcPadding);
        mc_w = wF - mcPadding*2;
        mc_h = hF - playbackWidgetHeight - plotBottomWell - (mcPadding*2);
        markerChannelBarHeight = int(mc_h/numMarkerChannelBars);

        markerChannelBars = new MarkerChannelBar[numMarkerChannelBars];

        //create our channel bars and populate our markerChannelBars array!
        for(int i = 0; i < numMarkerChannelBars; i++) {
            int markerChannelBarY = int(mc_y) + i*(markerChannelBarHeight); //iterate through bar locations
            MarkerChannelBar tempBar = new MarkerChannelBar(_parent, i, int(mc_x), markerChannelBarY, int(mc_w), markerChannelBarHeight); //int _channelNumber, int _x, int _y, int _w, int _h
            markerChannelBars[i] = tempBar;
            markerChannelBars[i].adjustVertScale(yLimOptions[mcInitialVertScaleIndex]);
            //sync horiz axis to Time Series by default
            markerChannelBars[i].adjustTimeAxis(w_timeSeries.getTSHorizScale().getValue());
        }
    }

    public int getNumMarkerChannels() {
        return numMarkerChannelBars;
    }

    void update() {
        super.update(); //calls the parent update() method of Widget (DON'T REMOVE)

        //update channel bars ... this means feeding new EEG data into plots
        for(int i = 0; i < numMarkerChannelBars; i++) {
            markerChannelBars[i].update();
        }
    }

    void draw() {
        super.draw(); //calls the parent draw() method of Widget (DON'T REMOVE)

        //remember to refer to x,y,w,h which are the positioning variables of the Widget class
        for(int i = 0; i < numMarkerChannelBars; i++) {
            markerChannelBars[i].draw();
        }
    }

    void screenResized() {
        super.screenResized(); //calls the parent screenResized() method of Widget (DON'T REMOVE)

        xF = float(x); //float(int( ... is a shortcut for rounding the float down... so that it doesn't creep into the 1px margin
        yF = float(y);
        wF = float(w);
        hF = float(h);

        mc_x = xF + mcPadding;
        mc_y = yF + (mcPadding);
        mc_w = wF - mcPadding*2;
        mc_h = hF - playbackWidgetHeight - plotBottomWell - (mcPadding*2);
        markerChannelBarHeight = int(mc_h/numMarkerChannelBars);

        for(int i = 0; i < numMarkerChannelBars; i++) {
            int markerChannelBarY = int(mc_y) + i*(markerChannelBarHeight); //iterate through bar locations
            markerChannelBars[i].screenResized(int(mc_x), markerChannelBarY, int(mc_w), markerChannelBarHeight); //bar x, bar y, bar w, bar h
        }
    }

    void mousePressed() {
        super.mousePressed(); //calls the parent mousePressed() method of Widget (DON'T REMOVE)
    }

    void mouseReleased() {
        super.mouseReleased(); //calls the parent mouseReleased() method of Widget (DON'T REMOVE)
    }
};

//These functions need to be global! These functions are activated when an item from the corresponding dropdown is selected
void VertScale_MC(int n) {
    settings.mcVertScaleSave = n;
    for(int i = 0; i < w_markerChannel.numMarkerChannelBars; i++) {
            w_markerChannel.markerChannelBars[i].adjustVertScale(w_markerChannel.yLimOptions[n]);
    }
}

//triggered when there is an event in the LogLin Dropdown
void Duration_MC(int n) {
    settings.mcHorizScaleSave = n;

    //Sync the duration of Time Series, Accelerometer, and Analog Read(Cyton Only)
    for(int i = 0; i < w_markerChannel.numMarkerChannelBars; i++) {
        if (n == 0) {
            w_markerChannel.markerChannelBars[i].adjustTimeAxis(w_timeSeries.getTSHorizScale().getValue());
        } else {
            w_markerChannel.markerChannelBars[i].adjustTimeAxis(w_markerChannel.xLimOptions[n]);
        }
    }
}

//========================================================================================================================
//                      Analog Voltage BAR CLASS -- Implemented by Analog Read Widget Class
//========================================================================================================================
//this class contains the plot and buttons for a single channel of the Time Series widget
//one of these will be created for each channel (4, 8, or 16)
class MarkerChannelBar{

    private int barIndex;

    private int x, y, w, h;

    private GPlot plot; //the actual grafica-based GPlot that will be rendering the Time Series trace
    private GPointsArray markerChannelPoints;
    private int nPoints;
    private int numSeconds;
    private float timeBetweenPoints;

    private color channelColor; //color of plot trace

    private boolean isAutoscale; //when isAutoscale equals true, the y-axis of each channelBar will automatically update to scale to the largest visible amplitude
    private int autoScaleYLim = 0;
    
    private TextBox markerValue;

    private boolean drawMarkerValue;
    private int lastProcessedDataPacketInd = 0;

    MarkerChannelBar(PApplet _parent, int _barIndex, int _x, int _y, int _w, int _h) { // channel number, x/y location, height, width
        barIndex = _barIndex;
        x = _x;
        y = _y;
        w = _w;
        h = _h;

        numSeconds = 20;
        plot = new GPlot(_parent);
        plot.setPos(x + 36 + 4, y);
        plot.setDim(w - 36 - 4, h);
        plot.setMar(0f, 0f, 0f, 0f);
        plot.setLineColor((int)channelColors[(barIndex)%8]);
        plot.setXLim(-3.2,-2.9);
        plot.setYLim(-200,200);
        plot.setPointSize(2);
        plot.setPointColor(0);
        plot.setAllFontProperties("Arial", 0, 14);
        if(barIndex == 1) {
            plot.getXAxis().setAxisLabelText("Time (s)");
        }

        initArrays();
        
        markerValue = new TextBox("t", x + 36 + 4 + (w - 36 - 4) - 2, y + h);
        markerValue.textColor = OPENBCI_DARKBLUE;
        markerValue.alignH = RIGHT;
        markerValue.alignV = BOTTOM;
        markerValue.drawBackground = true;
        markerValue.backgroundColor = color(255,255,255,125);

        drawMarkerValue = true;
    }

    void initArrays() {
        nPoints = nPointsBasedOnDataSource();
        timeBetweenPoints = (float)numSeconds / (float)nPoints;
        markerChannelPoints = new GPointsArray(nPoints);

        for (int i = 0; i < nPoints; i++) {
            float time = calcTimeAxis(i);
            float marker_value = 0.0; //0.0 for all points to start
            markerChannelPoints.set(i, time, marker_value, "");
        }

        plot.setPoints(markerChannelPoints); //set the plot with 0.0 for all auxReadPoints to start
    }

    void update() {

        // update data in plot
        updatePlotPoints();
        if(isAutoscale) {
            autoScale();
        }

        //Fetch the last value in the buffer to display on screen
        float val = markerChannelPoints.getLastPoint().getY();
        markerValue.string = String.format(getFmt(val),val);
    }

    private String getFmt(float val) {
        String fmt;
        if (val > 100.0f) {
            fmt = "%.0f";
        } else if (val > 10.0f) {
            fmt = "%.1f";
        } else {
            fmt = "%.2f";
        }
        return fmt;
    }

    float calcTimeAxis(int sampleIndex) {
        return -(float)numSeconds + (float)sampleIndex * timeBetweenPoints;
    }

    void updatePlotPoints() {
        List<double[]> allData = currentBoard.getData(nPoints);
        int[] markerChannels = new int[] {currentBoard.getTimestampChannel() - 1};

        if (markerChannels.length == 0) {
            return;
        }
        
        for (int i=0; i < nPoints; i++) {
            double[] points = allData.get(i);
            if (markerChannels[barIndex] < points.length) {
                float timey = calcTimeAxis(i);
                float value = (float)points[markerChannels[barIndex]];
                markerChannelPoints.set(i, timey, value, "");
            }
        }

        plot.setPoints(markerChannelPoints);
    }

    void draw() {
        pushStyle();

        //draw plot
        stroke(31,69,110, 50);
        fill(color(125,30,12,30));

        rect(x + 36 + 4, y, w - 36 - 4, h);

        plot.beginDraw();
        plot.drawBox(); // we won't draw this eventually ...
        plot.drawGridLines(0);
        plot.drawLines();
        if(barIndex == 1) { //only draw the x axis label on the bottom channel bar
            plot.drawXAxis();
            plot.getXAxis().draw();
        }

        plot.endDraw();

        if(drawMarkerValue) {
            markerValue.draw();
        }

        popStyle();
    }

    int nPointsBasedOnDataSource() {
        return numSeconds * currentBoard.getSampleRate();
    }

    void adjustTimeAxis(int _newTimeSize) {
        numSeconds = _newTimeSize;
        plot.setXLim(-_newTimeSize,0);

        nPoints = nPointsBasedOnDataSource();

        markerChannelPoints = new GPointsArray(nPoints);
        if (_newTimeSize > 1) {
            plot.getXAxis().setNTicks(_newTimeSize);  //sets the number of axis divisions...
        }
        else {
            plot.getXAxis().setNTicks(10);
        }
        
        updatePlotPoints();
    }

    void adjustVertScale(int _vertScaleValue) {
        if(_vertScaleValue == 0) {
            isAutoscale = true;
        } else {
            isAutoscale = false;
            plot.setYLim(-_vertScaleValue, _vertScaleValue);
        }
    }

    void autoScale() {
        autoScaleYLim = 0;
        for(int i = 0; i < nPoints; i++) {
            if(int(abs(markerChannelPoints.getY(i))) > autoScaleYLim) {
                autoScaleYLim = int(abs(markerChannelPoints.getY(i)));
            }
        }
        plot.setYLim(-autoScaleYLim, autoScaleYLim);
    }

    void screenResized(int _x, int _y, int _w, int _h) {
        x = _x;
        y = _y;
        w = _w;
        h = _h;

        plot.setPos(x + 36 + 4, y);
        plot.setDim(w - 36 - 4, h);

        markerValue.x = x + 36 + 4 + (w - 36 - 4) - 2;
        markerValue.y = y + h;
    }
};
