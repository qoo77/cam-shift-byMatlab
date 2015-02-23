clear;
clc;


%% parameter
dirPath = 'put path here';
fileName = 'put file name here'
maxIterations = 60; % max mean shift iterations
dist_threshold = 2; % threshold of mean shift converge
increasePixel = 7;  % pixel increase by mean shift square each times

%% main
M = mmreader([dirPath '\' fileName]);
frameTotal = M.NumberOfFrames;


frame1 = read(M, 1);

 
% get search window for first frame
[ cmin, cmax, rmin, rmax ] = select( frame1 );
cmin = round(cmin);
cmax = round(cmax);
rmin = round(rmin);
rmax = round(rmax);
ccenter = round(cmax-cmin);
rcenter = round(rmax-rmin);

wsize(1) = abs(rmax - rmin);
wsize(2) = abs(cmax - cmin);
 


hsvimage = rgb2hsv(frame1);
huenorm = hsvimage(:,:,1);
hue = huenorm*255;

hue = uint8(hue);
 
% Getting Histogram of Image:
histogram = zeros(256);

for i=rmin:rmax
    for j=cmin:cmax
        index = uint8(hue(i,j)+1);  
        %count number of each pixel
        histogram(index) = histogram(index) + 1;
    end
end
 
% create "tracking video.avi" and "backprojection video"
avi_trackingVideo = avifile('tracking video.avi');
avi_trackingVideo.colormap = [256 256 256];
avi_trackingVideo.Fps = M.FrameRate;
avi_trackingVideo.compression ='none';

avi_backProjectionVideo = avifile('backprojection video.avi');
avi_backProjectionVideo.colormap = [256 256 256];
avi_backProjectionVideo.Fps = M.FrameRate;
avi_backProjectionVideo.compression ='none';

% for each frame
for i = 1:frameTotal
    disp(['frame ' int2str(i) '/' int2str(frameTotal)]);
    
    thisFrame = read(M,i);
     
    % translate to hsv
    hsvimage = rgb2hsv(thisFrame);
    hue = hsvimage(:,:,1);
    hue = hue * 255;
    hue = uint8(hue);
    
     
     
    [rows cols] = size(hue);
    % the search window is (cmin, rmin) to (cmax, rmax)
 
     
     
    % create a probability map
    probabilityMap = zeros(rows, cols);
    for r=1:rows
        for c=1:cols
            if(hue(r,c) ~= 0)
                probabilityMap(r,c)= histogram(hue(r,c));  
            end
        end 
    end
    probabilityMap = probabilityMap / max(max(probabilityMap));
    probabilityMap = probabilityMap * 255;
     
    count = 0;
     
    rowcenter = rcenter;
    colcenter = ccenter;
    rowcenterold = rcenter;
    colcenterold = ccenter;
    
    
    while (  (sqrt((rowcenter - rowcenterold)^2 + (colcenter - colcenterold)^2) > dist_threshold) || (count < maxIterations) )
        %increase window size and check for center
        rmin = rmin - increasePixel;  
        rmax = rmax + increasePixel;
        cmin = cmin - increasePixel;
        cmax = cmax + increasePixel;
        
        if rmin < 1
            rmin = 1;
        elseif rmax > M.Height
            rmax = M.Height;
        end
        
        if cmin < 1
            cmin = 1;
        elseif cmax > M.Width
            cmax = M.Width;
        end
        
         
        rowcenterold = rowcenter;
        colcenterold = colcenter;
         
        [ rowcenter colcenter M00 ] = meanshift(thisFrame, rmin, rmax, cmin, cmax, probabilityMap);

         
        % redetermine window around new center
        rmin = round(rowcenter - wsize(1)/2);
        rmax = round(rowcenter + wsize(1)/2);
        cmin = round(colcenter - wsize(2)/2);
        cmax = round(colcenter + wsize(2)/2);
        

        if rmin < 1
            rmin = 1;
        elseif rmax > M.Height
            rmax = M.Height;
        end
        
        if cmin < 1
            cmin = 1;
        elseif cmax > M.Width
            cmax = M.Width;
        end
        
        wsize(1) = abs(rmax - rmin);
        wsize(2) = abs(cmax - cmin);
         
        count = count + 1;
    end
     

    trackim = thisFrame;

    % draw square in tracking video
    trackim(rmin:rmax, cmin, :) = 255;
    trackim(rmin:rmax, cmax, :) = 255;
    
    trackim(rmin, cmin:cmax, :) = 255;
    trackim(rmax, cmin:cmax, :) = 255;
    
    avi_trackingVideo = addframe(avi_trackingVideo,trackim);
    
    % draw backprojection video
    backProjectionFrame = zeros(M.Height,M.Width,3);
    backProjectionFrame(:,:,3) = probabilityMap;
    backProjectionFrame = hsv2rgb(backProjectionFrame);

    avi_backProjectionVideo = addframe(avi_backProjectionVideo,backProjectionFrame);
    
  
    % save center coordinates as an x, y by doing col, row
    windowsize = 1.5 * sqrt(M00/256);
     
    % get side length ... window size is an area so sqrt(Area)=sidelength
    sidelength = windowsize;
    
    % determine rmin, rmax, cmin, cmax   
    rmin = round(rowcenter-sidelength/2);
    rmax = round(rowcenter+sidelength/2);
    cmin = round(colcenter-sidelength/2);
    cmax = round(colcenter+sidelength/2);
    wsize(1) = abs(rmax - rmin);
    wsize(2) = abs(cmax - cmin);
end



avi_trackingVideo = close(avi_trackingVideo);
avi_backProjectionVideo = close(avi_backProjectionVideo);

