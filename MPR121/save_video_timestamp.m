function save_video_timestamp (vidObj, ~)
[~, ~, metadata] = getdata(vidObj, 1);
ts = {metadata.AbsTime};
timestamps = vidObj.UserData;
timestamps(end+1,:) = cell2mat(ts);
vidObj.UserData = timestamps;
end