%% Coordinate3DCalculator_v1
% Leanne Iannucci
% Written on 7/19/18
% Last Edited 3/10/20

% Designed to take in videos from 3D Camera that have points to track in
% them. 

% Major Modification List
% batch process added 7/25/18
% modified to take in images or videos 3/19/19
% made exponentially more user friendly 3/10/20

%% get user input

clc
clearvars

% ask user for local
disp('Please indicated local directory');
local = uigetdir;

%ask user for where 3D videos are
cd(local)
disp('Please select all 3D images and videos');
[files,path] = uigetfile('*.*', 'MultiSelect', 'on');
if (ischar(files))
    files = string(files);
end

%ask user if this is a mac or PC
    answer = questdlg('What kind or computer are you running this on?', ...
    'Computer Choice', ...
    'Mac','PC','Cancel','Cancel');
    % Handle response
        switch answer
            case 'Mac'
                mac = 1;
                slashY = '/';
            case 'PC'
                type = 0;
                slashY = '\';
            case 'Cancel'
                error('User ended thresholding');
        end

addpath(genpath(local))

%% big analysis loop
for grandI = 1:length(files)
 

   
%% get sample name and make folders for data and get camera parameters
clear name pathStr ext

%get sample name
if (numel(files) == 1)
    [pathstr,name,ext] = fileparts(char(files));
    sampleName = name;
else
    [pathstr,name,ext] = fileparts(files{1,grandI});
    sampleName = name;
end

% ask user for camera Parameters
     cd(local)
     disp('Please select DLT parameters for' + " " + string(name));

     [paramsfiles,path2] = uigetfile('*.*', 'MultiSelect', 'on');
     load(paramsfiles);


tempPath = erase(path, strcat(slashY,'Image or Video',slashY, '3D', slashY));

%direct to or make folder for data to be saved in
saveMeHere = strcat(tempPath, slashY, 'Data', slashY, sampleName, slashY);
a = isdir(string(saveMeHere));
if (~a)
    mkdir(saveMeHere)
    cd(saveMeHere)
else
    cd(saveMeHere)
end

%% ask user if this is going to be a video or an image
        answer = questdlg(strcat('What file type is', name,' ?'), ...
        'Threshold Me', ...
        'Image','Video','Cancel','Cancel');
        % Handle response
            switch answer
                case 'Image'
                    type = 1;
                case 'Video'
                    type = 0;
                case 'Cancel'
                    error('User ended thresholding');
            end

%% load left and right videos
    clear leftfiles leftpath rightfiles rightpath
    cd(tempPath)
    disp('Please Select Left Img/Video for' + " " + string(sampleName));
    [leftfiles,leftpath] = uigetfile('*.*', 'MultiSelect', 'on');
    cd(tempPath)
    disp('Please Select Right Img/Video for'+" " + string(sampleName));
    [rightfiles,rightpath] = uigetfile('*.*', 'MultiSelect', 'on');
    
if type == 0
    clear leftVid leftFile rightVid rightFile
    leftVid = VideoReader(leftfiles);
    count = 0;
    while hasFrame(leftVid)
        count = count+1;
        leftFile(:,:,:,count) = readFrame(leftVid);
    end

    rightVid = VideoReader(rightfiles);
    count = 0;
    while hasFrame(rightVid)
        count = count+1;
        rightFile(:,:,:,count) = readFrame(rightVid);
    end

    %% break down left videos into individual images

    leftFolder = strcat(saveMeHere, 'Left', slashY);
    mkdir(leftFolder);
    cd(leftFolder);
    for i = 1:size(leftFile, 4)

        temp = leftFile(:,:,:,i);
        imwrite(temp, strcat(sampleName, '-Left ', num2str(i), '.png'))
    end

    %% break down right videos into individual images
    cd(saveMeHere);
    rightFolder = strcat(saveMeHere, 'Right', slashY);
    mkdir(rightFolder);
    cd(rightFolder);
    for i = 1:size(rightFile, 4)

        temp = rightFile(:,:,:,i);
        imwrite(temp, strcat(sampleName, '-Right ', num2str(i), '.png'))
    end
    
else
%% load left and right images

   leftFile = imread(leftfiles);
   rightFile = imread((rightfiles));
   
end

%% perform colorThresholding

% ask user if they want to color threshold

        answer = questdlg('Do you want to color threshold your video?', ...
        'Threshold Me', ...
        'Yes','No','Cancel','Cancel');
        % Handle response
            switch answer
                case 'Yes'
                    colorType = 1;
                case 'No'
                    colorType = 0;
                case 'Cancel'
                    error('User hit cancel');
            end
            
% perform color thresholding for the left

if colorType == 1
        if type == 0
            colorThresholder(leftFile(:,:,:,1))
        else
            colorThresholder(leftFile)
        end
        doneThresholding = msgbox('Click ok when you are done thresholding');
        waitfor(doneThresholding);
        
        
    % calculate average color of positive pixels from leftFile
        LABfileVid1 = rgb2lab(maskedRGBImage);
        indexMe = sum(sum(BW));
        colorList = zeros(indexMe,3);
        count = 0;
        for k = 1:size(LABfileVid1,1)
            for l = 1:size(LABfileVid1,2)
                if BW(k,l) == 1
                    count= count+1;
                    colorList(count,1) = LABfileVid1(k,l,1);
                    colorList(count,2) = LABfileVid1(k,l,2);
                    colorList(count,3) = LABfileVid1(k,l,3);
                end
            end
        end
        
        Lup = max(colorList(:,1));
        Ldown = min(colorList(:,1));
        Aup = max(colorList(:,2));
        Adown = min(colorList(:,2));
        Bup = max(colorList(:,3));
        Bdown = min(colorList(:,3));

        bwMask = true(size(leftFile,1), size(leftFile,2), size(leftFile,4));
  q = waitbar(0,'Thresholding in Progress');
  for m = 1:size(leftFile,4)
      tempLAB = rgb2lab(leftFile(:,:,:,m));
      bwMask(:,:,m) = ((tempLAB(:,:,1) > Ldown) & (tempLAB(:,:,1) < Lup)) & ...
          ((tempLAB(:,:,2) > Adown) & (tempLAB(:,:,2) < Aup)) & ...
          ((tempLAB(:,:,3) > Bdown) & (tempLAB(:,:,3) < Bup));
      leftThresh(:,:,1,m) = uint8(bwMask(:,:,m)).*leftFile(:,:,1,m);
      waitbar(m/size(leftFile,4),q)
  end
    
  close(q)
  
else
    leftThresh = leftFile;
end

% perform color thresholding for the right

if colorType == 1
        if type == 0
            colorThresholder(rightFile(:,:,:,1))
        else
            colorThresholder(rightFile)
        end
        doneThresholding = msgbox('Click ok when you are done thresholding');
        waitfor(doneThresholding);
        
        
    % calculate average color of positive pixels from leftFile
        LABfileVid1 = rgb2lab(maskedRGBImage);
        indexMe = sum(sum(BW));
        colorList = zeros(indexMe,3);
        count = 0;
        for k = 1:size(LABfileVid1,1)
            for l = 1:size(LABfileVid1,2)
                if BW(k,l) == 1
                    count= count+1;
                    colorList(count,1) = LABfileVid1(k,l,1);
                    colorList(count,2) = LABfileVid1(k,l,2);
                    colorList(count,3) = LABfileVid1(k,l,3);
                end
            end
        end
        
        Lup = max(colorList(:,1));
        Ldown = min(colorList(:,1));
        Aup = max(colorList(:,2));
        Adown = min(colorList(:,2));
        Bup = max(colorList(:,3));
        Bdown = min(colorList(:,3));

        bwMask = true(size(rightFile,1), size(rightFile,2), size(rightFile,4));
  q = waitbar(0,'Thresholding in Progress');
  for m = 1:size(rightFile,4)
      tempLAB = rgb2lab(rightFile(:,:,:,m));
      bwMask(:,:,m) = ((tempLAB(:,:,1) > Ldown) & (tempLAB(:,:,1) < Lup)) & ...
          ((tempLAB(:,:,2) > Adown) & (tempLAB(:,:,2) < Aup)) & ...
          ((tempLAB(:,:,3) > Bdown) & (tempLAB(:,:,3) < Bup));
      rightThresh(:,:,1,m) = uint8(bwMask(:,:,m)).*rightFile(:,:,1,m);
      waitbar(m/size(rightFile,4),q)
  end
    
  close(q)
  
else
    rightThresh = rightFile;
end



%% track points in original left video & save coordinates
clear leftTracker
strainTrackSaveMeLeft = strcat(saveMeHere, 'Left Tracking/');
mkdir(strainTrackSaveMeLeft);
strainTrackNameLeft = strcat(sampleName, '-LeftTracker');
cd(strainTrackSaveMeLeft);
[leftTracker] = strain_autoCentroid_lei(leftThresh, colorType);
cd(saveMeHere);

%% track points in original right video & save coordinates
clear rightTracker
strainTrackSaveMeRight = strcat(saveMeHere, 'Right Tracking/');
mkdir(strainTrackSaveMeRight);
strainTrackNameRight = strcat(sampleName, '-RightTracker');
cd(strainTrackSaveMeRight);
[rightTracker] = strain_autoCentroid_lei(rightThresh, colorType);
cd(saveMeHere);


%% calculate 3d coordinates of points
clear totalPoints
for i = 1:size(leftFile, 4)
    for j = 1:size(leftTracker,3)
   totalPoints{j, i} = triangulateDLT_LEI_v1(leftTracker(i,1,j),leftTracker(i,2,j),rightTracker(i,1,j), rightTracker(i,2,j),...
        DLTstructPairs.DLTparams{1, 1}, DLTstructPairs.DLTparams{1, 2} );
    end
end

%% save left, right and 3d coordinates

save(strcat(sampleName, '.mat'), 'leftTracker', 'rightTracker', 'totalPoints');

%% clear variables before next loop 

end