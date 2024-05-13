function VideoProcessor(prev_roi,n_ROI,startFrame,saveROI, videoName)
%This function is designed to 
%   take an input video of a geotaxis experiment with D.malengaster flies,
%   remove the slamming portion of the video (specifying start frame),
%   cut the video into regions of interest (ROI),
%   wait for the user to be satisfied with the ROI (button/mouse click),
%   and save the separated vials into new videos for tracking. 
%
%However, this function can be used to cut down ROIs for any video
%
%1st input previous ROI matrix input 
%2nd input is how many ROIs are desired by the user
%3ed input is the startFrame (# of frames user desires to skip in the beginning)
%4th input specifies if you want to save the ROI information into a .mat file
%5th input if the user already has the FULL PATH to the desired file


    %set defualts for the necessary inputs
    %read in the desired video file
    if nargin<5
        [fileName, filePath] = uigetfile('*.*' , 'Select video file','MultiSelect','off');
        videoName=fullfile(filePath, fileName);
    end
    vidObj=VideoReader(videoName);

    if nargin<4, saveROI=0;end
    if nargin<3, startFrame=0;end
    if nargin<2, n_ROI=10;end

    %convert the # of frames cut from the beginning into the start time of
    %cropped ROI videos
    startTime=startFrame/vidObj.FrameRate;

    %draw the ROIs
    vidObj.CurrentTime=startTime;%begin the cropped video at the desired start frame

    f2=figure;
    title('Draw ROIs for Cropping');
    imshow(readFrame(vidObj));

    if nargin<1 || isempty(prev_roi)
        for ii=1:n_ROI 
            roi(ii) = drawrectangle('LineWidth',2,'Color','cyan');
        end
    else
        for ii=1:n_ROI 
            roi(ii)=drawrectangle('Position',prev_roi(ii).Position,'LineWidth',2,'Color','cyan');  
        end      
    end
    pause; %waits for user to accept ROIs by pressing enter or clicking to the side


    %crop vidoes to ROI's
    for ii=1:n_ROI

        vialROI=roi(1,ii);

        %write crop video to the same folder
        newfilename=strcat(strcat(videoName(1:end-4),'_'),int2str(ii));

        writer = VideoWriter(newfilename, 'MPEG-4');%create a video writer
        writer.FrameRate = vidObj.FrameRate;

        vidObj.CurrentTime=startTime;%reset the begining frame for the for loop

        open(writer);
        while hasFrame(vidObj)
            currFrame=readFrame(vidObj);%load frame
            croppedFrame = imcrop(currFrame, vialROI.Position);%apply roi to the frame
            writeVideo(writer,croppedFrame);%write cropped frame to new file
        end
        close(writer);

    end

    %save the ROI to open folder for future analysis (if specified)
    if saveROI==1
        [vidpath,vname,~] = fileparts(videoName);
        filepath=fullfile(vidpath,strcat(vname,'_roi.mat'));
        save(filepath, 'roi');
    end


    close(f2);



end

