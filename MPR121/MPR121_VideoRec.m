% This workflow aims to use MPR121 touch sensor to triger a solenoid valve
% delivering water reward. The MPR121 is connected to an Arduino Uno
% control board. The solenoid valves listen to the input from Arduino
% through Qunqi L298N motor drive board. Video recording start
% simultanousely with the touch sensor recording. 
% The final data was writen into an .mat file. 

%% SECTION NEEDS MANUAL INPUTS
%% Set up hardware parameters
% First, you need to load MPR121_arduino.ino to arduino. 
% set data saving path and recording length
mouse = 'test5';
RecLength = 120; %seconds
savpath = ['E:\behavior_workflow_test\',mouse];
if ~exist(savpath,'dir')
    mkdir(savpath);
end
cd(savpath);

% Set parameters for MPR121 on Arduino (one time set up)
Delay = 5; %seconds, delay between two reward delivery
Port = 'COM7';
OutputPin1 = 'D13';
OutputPin2 = 'D12';
% OutputPin3 = 'D11';
% OutputPin4 = 'D10';

% Set parameters for video recording (Logitech c920, one time set up)
CamLocation = 1;
CamExposure = -5;
CamFocus = 0;
CamGain = 255;
CamZoom = 100;
maxRecTime = 1800; %seconds, needs to be longer than RecLength
RecFormat = 'MJPG_1920x1080'; %can be changed, see di in line 52-53;

%% SECTIONS DO NOT NEEDS MANUAL INPUTS
%% Set up MPR121 with Arduino and create video object
% First, you need to load MPR121_arduino.ino to arduino. 
% Create an arduino object and include the I2C library.
a = arduino(Port, 'Uno');
% Scan for available I2C addresses.
addrs = scanI2CBus(a);
mpr121 = device(a,'I2CAddress',addrs{1});
% Config the output digital pin of MPR121. 
configurePin(a, OutputPin1, 'DigitalOutput');
configurePin(a, OutputPin2, 'DigitalOutput');
% configurePin(a, OutputPin3, 'DigitalOutput');
% configurePin(a, OutputPin4, 'DigitalOutput');

% Create video object
ci = imaqhwinfo;
% List number of supported resolutions for the camera
% di = imaqhwinfo(ci.InstalledAdaptors{1,CamLocation});
% di.DeviceInfo.SupportedFormats'
vidObj = videoinput(ci.InstalledAdaptors{1,CamLocation},CamLocation,RecFormat);
% Set camera parameters
v = vidObj.Source;
v.ExposureMode = "manual";
v.Exposure = CamExposure;
v.FocusMode ="manual";
v.Focus = CamFocus;
v.Gain = CamGain;
v.Zoom = CamZoom;
% configure recorded video
vidObj.FramesPerTrigger = 30*maxRecTime;
vidObj.LoggingMode = "disk&memory";
vidObj.FramesAcquiredFcnCount = 1;
vidObj.FramesACquiredFcn = @save_video_timestamp;
outputVideo = VideoWriter('behavVideo.avi');
vidObj.DiskLogger = outputVideo;
% select for video recording ROI
frame = getsnapshot(vidObj);
ax = figure;
imshow(frame)
title('Please select an ROI for video recording')
roi = drawrectangle(gca);
vidObj.ROIPosition = roi.Position;
close(ax)

%% Start recording for both video and touch sensor
preview(vidObj)
touchRec = [];
touchTime = [];
t0 = clock;
start(vidObj);
while etime(clock, t0) < RecLength
    % Extract individual touch status values and process them as needed
    % For example, touchStatus(1) corresponds to the touch status of
    % channels. The value of touchStatus corresponding to each pins are
    % channel0: 1, channel1: 2, channel2: 4, channel3: 8, channel4: 16,
    % channel5: 32, etc.
    touchStatus = read(mpr121,1,'uint8');
    touchRec = [touchRec;touchStatus];
    touchTime = [touchTime;clock]; % in seconds
    % use touchStatus to trigger solenoid valve. 
    if touchStatus == 1
        writeDigitalPin(a,'D13',1);
        writeDigitalPin(a,'D13',0);
        pause(Delay);
    elseif touchStatus == 2 || touchStatus == 4 || touchStatus == 8
        writeDigitalPin(a,'D12',1);
        writeDigitalPin(a,'D12',0);
        pause(Delay);
    end
end
% make sure the valve is closed after recoding
writeDigitalPin(a,'D13',0);
writeDigitalPin(a,'D12',0);

% Stop video recording and make sure the video was completely writen into
% the disk before closing the vidObj. 
stop(vidObj);
while (vidObj.FramesAcquired ~= vidObj.DiskLoggerFrameCount) 
    pause(.1)
end
closepreview(vidObj);

%% Post processing and data saving
lick = touchRec;
licktime = touchTime;
videotime = vidObj.UserData;
save([savpath,'\behavData.mat'],'lick','licktime','videotime');

% Retrive the timestamp of recorded video
% [~, time, metadata] = getdata(vidObj, vidObj.FramesAvailable);

%% close recording and clear objects
delete(vidObj)
clear

