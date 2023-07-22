function save_video_timestamp (vidObj, ~)
[~, ts] = getdata(vidObj, 1);
timestamps = vidObj.UserData;
timestamps(end+1,1) = ts;
vidObj.UserData = timestamps;
end