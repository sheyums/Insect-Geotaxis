function RecordVideos(numVideos,userFrameRate,duration, waitTime,filename)
%to record multiple videos in succession directly using Matlab
%
%numVideos = the number of videos to record in succession
%userFrameRate = the frame rate of each video (could be limited by the camera)
%duration = duration of each recording (in seconds)
%waitTime = the time between each video (in seconds)
%filename = the name of the videos (the number will be appended). For
%   example, if 'exp1_' is inputed for 3 videos, you will get files labeled
%   exp1_1.mp4, exp1_2.mp4, exp1_3.mp4

%****videoinput should change in line 25 if different camera is used
%****if not using in tandum with the fly slamming device with the same motor
%(or any) comment out line 34-36, 60-62, 87

    %get the duration and the frame rate desired by the user if not specified
    if nargin<5
        userInput = inputdlg({'# of Videos','Time (in seconds)','Frame Rate',...
            'Wait Time Between Videos (in seconds)','Video Name (to be incrimented)'}...
            ,'Select Perameters' ,[1 40; 1 40; 1 40; 1 40; 1 40],{'10','13','30','15','exp1_'});
        numVideos=str2double(userInput{1});
        userFrameRate = str2double(userInput{3});
        duration = str2double(userInput{2})*userFrameRate; %shoudl be in Hz
        waitTime=uint8(str2double(userInput{4}));
        filename=userInput{5};
    end

    %create the camera obj
    vid = videoinput('tisimaq_r2013_64', 1); %should change if different camera is used
    set(vid,'Timeout',50);
    vid.FramesPerTrigger=Inf;
    
    %create slammer device obj
    clear serialdev
    serialdev = visadev("ASRL3::INSTR");
    writeline(serialdev,"Q");

    for jj=1:numVideos
        %check to make sure you are not overwriting the file
        if jj==1&&~isempty(find(contains({dir().name},filename),1))
            answer = questdlg('Would you like to overwrite your file?', ...
                    'Same File Name', 'Yes','No','Default');
                % Handle response
                switch answer
                    case 'Yes'
                        disp('Overwriting File');
                    case 'No'
                        break
                end          
        end
        
        %inform user what video is being recorded
        disp(strcat('Now Recording: ',strcat(filename,num2str(jj))));
        
        %create a video writer to write a new file
        writer = VideoWriter(strcat(filename,num2str(jj)), 'MPEG-4');
        writer.FrameRate = userFrameRate;
       
        %sends on message to slammer deviece to beginning slammeing
        writeline(serialdev,"1");
        pause(3); %program pauses while slamms are happening
        writeline(serialdev,"Q"); %turns off message to slammer so it is able to 
        %be slammed again
        
        %write camera frames to desired video file
        open(writer);
        start(vid)
        for ii=1:duration
           snap=im2double(getsnapshot(vid));
           writeVideo(writer,snap)
        end
        
        %close writer and stop gathering frames when finished
        close(writer);
        stop(vid);
                
        %inform user when the video has stopped recording 
        disp('Recording Completed');
         
        %inform user that the program is waiting as requested
        if jj~=numVideos
            disp(strcat('Now waiting: ',int2str(waitTime),' sec'));
            pause(waitTime)
        end
    end
    clear serialdev
end