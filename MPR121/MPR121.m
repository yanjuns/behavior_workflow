% This function aims to use MPR121 touch sensor to triger a solenoid valve
% delivering water reward. The MPR121 is connected to an Arduino Uno
% control board. The final data was write to an .mat file. 
% The code is sampling at ~15Hz at the current configuration. However, use
% the code inside MPR121_VideoRec for a better performance. 
%% Set up MPR121 with Arduino
% First, you need to load MPR121_arduino.ino to arduino. 

% Set up parameters
savpath = '';
RecLength = 60; %seconds
Delay = 5; %seconds
Port = 'COM7';
OutputPin = 'D13';

% Create an arduino object and include the I2C library.
a = arduino(Port, 'Uno');

% Scan for available I2C addresses.
addrs = scanI2CBus(a);
mpr121 = device(a,'I2CAddress',addrs{1});

% Config the output digital pin of MPR121. 
configurePin(a, OutputPin, 'DigitalOutput');

%% Start recording
timeRun = RecLength;
t0 = clock;
touchRec = [];
touchTime = [];
n = 0;
while etime(clock, t0) < timeRun
    n = n+1;
    % Extract individual touch status values and process them as needed
    % For example, touchStatus(1) corresponds to the touch status of
    % channels. The value of touchStatus corresponding to each pins are
    % channel0: 1, channel1: 2, channel2: 4, channel3: 8, channel4: 16,
    % channel5: 32, etc.
    touchStatus = read(mpr121,1,'uint16');
    % convert touchStatus to corresponding pin numbers.
    touchedPin = log2(touchStatus);
    % use touchStatus to trigger solenoid valve. 
    if touchedPin >= 0
        writeDigitalPin(a,'D13',1);
    else
        writeDigitalPin(a,'D13',0);
    end
    touchRec = [touchRec;touchedPin];
    touchTime = [touchTime;etime(clock, t0)*1000]; % in miliseconds
    %     % Delay between readings (in seconds)
    %     pause(1/SamplingRate);
    if n >= 2
        if touchedPin >= 0 && touchedPin == touchRec(end-1)
            writeDigitalPin(a,'D13',0);
            pause(Delay);
        end
    end
end
% make sure the valve is closed after recoding
writeDigitalPin(a,'D13',0);

%% Post processing and data saving
lickdata = [touchRec, touchTime];
save([savpath,'\lickdata.mat']);
