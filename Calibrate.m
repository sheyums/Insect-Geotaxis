function Calibrate(sameFile,saveInfo)
%This function is used to Calibrate the FlyTracking function for the
%   Automated Geotaxis Monitoring (AGM) system.
%This function:
%   Creates a background for each input video file 
%   Loads frame from every half second of each recording 
%   Subtracts background from frame and detects blobs
%   Asks the user to catagorize all blobs into 3 possible groups (one fly,
%   multiple flies, not a fly)
%	Saves area information in 2 seperate excel files

    %initialize matrices
    interval=0.5;%interval of time user wants to assess in seconds
    flyArea=[];
    multiArea=[];
    axisLengths=[];
    flyMajLen=[];
    flyMinLen=[];
    multiMajLen=[];
    multiMinLen=[];
    lastPressed=0; %keeps track of the last button pressed
        %0=not a fly, 1=one fly, 2=multiple flies, 3=back
    kk=1; %iterative for the while loop
    backtrack=0; %to go back a frame with the back button
    
    %set default values for inputs
    if nargin<2, saveInfo=1; sameFile=1; end 
        %saveInfo=1 means the user wants to save the information to specified folder
        %saveInfo=0 means user the user does not want to automatically save the information
    if nargin<1 || saveInfo==0, sameFile=0; end
        %if  sameFile=1 it will append to input file else will ask for new
        %name
        %saveInfo must =1 if you want to save to sameFile
    if sameFile==1
        [fileNameVar{1}, filePathVar{1}] = uigetfile('*.*','Select AxisLengths Excel File','MultiSelect','off');
        axisLengths=readmatrix(fullfile(filePathVar{1},fileNameVar{1}));
        flyMajLen=axisLengths(:,1);
        flyMinLen=axisLengths(:,2);
        multiMajLen=nonzeros(axisLengths(:,3));
        multiMinLen=nonzeros(axisLengths(:,4));
        axisLengths=[];
        
        [fileNameVar{2}, filePathVar{2}] = uigetfile('*.*','Select MultiArea Excel File','MultiSelect','off');
        multiArea=readmatrix(fullfile(filePathVar{2},fileNameVar{2}));
        
        [fileNameVar{3}, filePathVar{3}] = uigetfile('*.*','Select PixelArea Excel File','MultiSelect','off');
        flyArea=readmatrix(fullfile(filePathVar{3},fileNameVar{3}));
        
    end
  
    
    %select the videos desired to extract blob(fly) information from 
    [fileName, filePath] = uigetfile('*.*' , 'Select video file','MultiSelect','on');
    if ~iscell(fileName), fileName=cellstr(fileName); end
    
    
    %for each video provided
    for ii=1:length(fileName)
        videoName=fullfile(filePath, char(fileName(1,ii)));
           
        %create background
        vidObj=VideoReader(videoName);
        fsp=vidObj.FrameRate;
        vidObj.CurrentTime=0;
        imgB=im2single(readFrame(vidObj));
        bg=zeros(size(imgB,1),size(imgB,2),vidObj.NumFrames); %preallocate bg
        counter=1;
        while hasFrame(vidObj)    
            %convert image to grayscale 
            imgB=rgb2gray(im2single(readFrame(vidObj)));

            %create a new matrix to save frames
            bg(:,:,counter)=imgB;
            counter=counter+1; 
        end
        
        background=median(bg,3);
        
        
        
        %find objects in the frame every half second second and save information
        counter=interval;
        while counter<vidObj.Duration
            vidObj.CurrentTime=counter;
            frame=readFrame(vidObj);

            %subrtact background from first frame
            imgB=rgb2gray(im2single(frame));
            subframe=background-imgB;
            subframe(subframe(:,:)<=.05)=0;%erase background
        	subframe(subframe(:,:)>0)=1;%make flies brighter

            cleanframe=bwareaopen(subframe,2); %gets rid of too small objects
                    %pixel area is to be considered real objects in any way
            connframe=bwconncomp(cleanframe,8);%fills in the missing pixels  
            
            
            %get rid of very large objects (about 1/6 of frame)
            flies=regionprops('table',connframe,'MajorAxisLength');
            noise=find(table2array(flies(:,{'MajorAxisLength'}))>100);
            for jj=1:length(noise)
                cleanframe(connframe.PixelIdxList{noise(jj)})=0;
            end
            connframe=bwconncomp(cleanframe,8);
            
            
            %get information of detected objects
            flies=regionprops(connframe,'BoundingBox','Area','MajorAxisLength','MinorAxisLength');
            start_bboxes=cat(1,flies.BoundingBox);
            flies_area=cat(1,flies.Area);
            flies_majLen=cat(1,flies.MajorAxisLength);
            flies_minLen=cat(1,flies.MinorAxisLength);
            
            %show frame in figure
            f=figure(1);
            imshow(frame)
            hold on
            %create buttons for user to accept or reject real detection
            uicontrol('Position',[55 95 90 30],'String','Is one fly',...
              'Callback', @YCall);
            uicontrol('Position',[55 65 90 30],'String','Multiple flies',...
              'Callback', @MCall);
            uicontrol('Position',[55 35 90 30],'String','Not one fly',...
              'Callback', @NCall);  
            uicontrol('Position',[55 3 90 30],'String','Back',...
              'Callback', @BCall); 
            f.Position=[449,68,395,560];
            hold on
            %in a loop show each detection for the frame one at a time
            while kk<=size(start_bboxes,1)
                if backtrack==1
                    kk=size(start_bboxes,1);
                    backtrack=0; %reset 
                end

                pushed=0;
                rec=rectangle('Position', start_bboxes(kk,:), 'EdgeColor','c');
          
                %wait for user to push a button
                while pushed==0
                    pause(0.001)
                end
               
                %once the fly is catagorized get rid of the rectangle 
                delete(rec)
                kk=kk+1;
            end            
            counter=counter+((interval*fsp)/fsp);
            kk=1;
        end 
        close(f)
        clear bg
    end
      
    axisLengths(:,1)=flyMajLen;
    axisLengths(:,2)=flyMinLen;
    axisLengths(1:size(multiMajLen,1),3)=multiMajLen;
    axisLengths(1:size(multiMinLen,1),4)=multiMinLen;
    
    %save info to file
    if saveInfo==1
        if sameFile==0
            folder=uigetdir();
            userInput = inputdlg({'Name of Matrix File'},'Select Perameters' ,[1 40],{'Straight_Wing_'});
            fileNameArea=strcat('\',userInput{1},'_pixelarea.xlsx');
            fileMultiArea=strcat('\',userInput{1},'_multiarea.xlsx');
            fileFlyMajLen=strcat('\',userInput{1},'_axisLengths.xlsx');
            writematrix(flyArea, strcat(folder,fileNameArea));
            writematrix(multiArea, strcat(folder,fileMultiArea));
            writematrix(axisLengths, strcat(folder,fileFlyMajLen));
        else
            writematrix(flyArea, fullfile(filePathVar{3},fileNameVar{3}));  
            writematrix(multiArea, fullfile(filePathVar{2},fileNameVar{2}));
            writematrix(axisLengths, fullfile(filePathVar{1},fileNameVar{1}));

        end    
    end
        
    %functions for buttons
    function YCall(~, ~)
        flyArea(end+1,:)=flies_area(kk);
        flyMajLen(end+1,:)=flies_majLen(kk);
        flyMinLen(end+1,:)=flies_minLen(kk); 
        lastPressed=1;
        pushed=1;
    end

    function MCall(~, ~)
        multiArea(end+1,:)=flies_area(kk);
        multiMajLen(end+1,:)=flies_majLen(kk);
        multiMinLen(end+1,:)=flies_minLen(kk); 
        lastPressed=2;
        pushed=1;
    end
    
    function NCall(~, ~)
        lastPressed=0;
        pushed=1;
    end

    function BCall(~,~)
        if kk==1
            counter=counter-1;
            switch lastPressed
                case 0
                    kk=size(start_bboxes,1);
                    pushed=1;
                case 1
                    flyArea(end,:)=[];
                    flyMajLen(end,:)=[];
                    flyMinLen(end,:)=[];
                    kk=size(start_bboxes,1);
                    pushed=1;
                case 2
                    multiArea(end,:)=[];
                    multiMajLen(end,:)=[];
                    multiMinLen(end,:)=[];
                    kk=size(start_bboxes,1);
                    pushed=1;
            end
            backtrack=1;
        else
            switch lastPressed
                case 0
                    kk=kk-2;
                    pushed=1;
                case 1
                    flyArea(end,:)=[];
                    flyMajLen(end,:)=[];
                    flyMinLen(end,:)=[];
                    kk=kk-2;
                    pushed=1;
                case 2
                    multiArea(end,:)=[];
                    multiMajLen(end,:)=[];
                    multiMinLen(end,:)=[];
                    kk=kk-2;
                    pushed=1;
            end
        end
        lastPressed=3;
    end
end