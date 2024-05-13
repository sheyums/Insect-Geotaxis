function vidMatrix=FlyTracking(numFliesArray,saveTrackVideo,showTracking,saveCoord,timeOfInterest,numVials)
%Meant to be used in tandem with the Automated Geotaxis Monitoring (AGM) system. 
%This function is designed to locate individual flies and track their
%progress through time.
%
%This function:
%   Detects flies per frame by background subtraction and blob analysis
%   Predicts the future location of the fly using a kalman filter
%   Assigns tracking numbers to each object using  Munkres' version of the
%       Hungarian algorithm which uses a combination of the square root of
%       the Euclidean distance cost matrix between the predicted coordinates and 
%       detection coordinates multiplied by the square root of the Euclidean 
%       distance between the preivous and current centroids, as well as the
%       cost of non assignment
%   Checks that number of tracks <= number of flies
%   Follows the progress of each fly frame by frame updating the Kalman
%   filter as it goes
%   The coordinates of the flies will be saved in a MxN matrix within a 1xP cell
%       matrix
%       P = number of vials per video
%       M = number of frames, N = 2*number of flies
%       Every two columns correlate to one fly (x-coordinate,y-coordinate)
%       The cell matrix name will correlate to the vial number recieved from the 
%       filename
%           for example: video exp3_1 will have a corresponding cell array
%                           coord3_1
%
%Inputs:
%   numFliesArray: an array containing the number of flies per vial per experiment
%       selected. This could also be a partial array or a single number. The
%       function will use the last number input to fill in any missing
%       information. For 3 videos, possible inputs could be:
%       ex1) [6,7,7]  ex2) [6,7] ---> [6,7,7] ex3) 7 ---> [7,7,7]
%           defualt = 7
%   saveTrackVideo: 1 = save new video with tracking numbers present. 
%       0 = do not save new video
%           default = 0
%   showTracking: 1 = show the video with tracking numbers present as it
%       runs through the tracking function. 
%       0 = track without showing video with tracking
%           default = 0
%   saveCoord: 1 = save the end coordinate result from tracking to file
%       0 = output coordinates to workspace without saving to file
%           default = 1
%   timeOfInterest: the amount of time (in seconds) user desires to track
%       flies in video
%           default = duration of video input
%   numVials: number of vials per video
%           default = 10
%
%Outputs:
%   vidMatrix: an 1xP cell array with MxN matrices enclosed
%       P = number of vials in selected experiment
%       M = number of frames, N = 2*number of flies
%       Every two columns correlate to one fly (x-coordinate,y-coordinate)
%

    %select the videos you desire to track
    [fileName, filePath] = uigetfile('*.*' , 'Select Video Files','MultiSelect','on');   
    if ~iscell(fileName)
        fileName=cellstr(fileName);
    end

    %set default inputs
    if nargin<6, numVials=10; end 
    if nargin<5, timeOfInterest=[]; end %in seconds, how much time is tracked 
    if nargin<4 , saveCoord=1; end%1=saves coordinate to excel files in folder, 0=not
    if nargin<3, showTracking=1; end %1=displays tracking real time, 0=not
    if nargin<2, saveTrackVideo=1; end %1=saves the tracked video, 0=not
 
    %completes the numFliesArray if user has not
    if nargin<1 || isempty(numFliesArray) 
        numFliesArray(1,1:numVials)=7; %default 7 flies
    elseif size(numFliesArray,2)<numVials
        lastFlyNum=numFliesArray(1,end); %uses the last fly in array to fill missing fly numbers
        numFliesArray(1,end:numVials)=lastFlyNum;
    end
    
    %get calibrations from file 
    [fileNameVar, filePathVar] = uigetfile('*.*','Select AxisLengths, MultiArea, and PixelArea Excel Files','MultiSelect','on');
    
    %check if correct files were chosen
    if ~iscell(fileNameVar) ...
            || isempty(strfind(fileNameVar{2},'_multiarea.xlsx'))...
            || isempty(strfind(fileNameVar{3},'_pixelarea.xlsx'))...
            || isempty(strfind(fileNameVar{1},'_axisLengths.xlsx'))
        
        disp('User DID NOT select necessary files. Default fly information used');
        
        %default areas assigned using straight winged flies
        maxLengthMult=50;
        minLengthMult=5;
        minLengthSingle=3;
        flyMin=20;
        flyMax=129;
        multMax=500;
        multMin=130;
    else
        %read in calibration matrices
        axisLengths=readmatrix(fullfile(filePathVar,fileNameVar{1}));
        fmin=sort(axisLengths(:,2),'ascend');
        multiArea=sort(readmatrix(fullfile(filePathVar,fileNameVar{2})),'ascend');
        flyArea=sort(readmatrix(fullfile(filePathVar,fileNameVar{3})),'ascend');
        
        %extract size information from calibration files     
        maxLengthMult=max(axisLengths(:,3));
        minLengthMult=min(nonzeros(axisLengths(:,4)));
        minLengthSingle=fmin(10);
        flyMin=flyArea(10);
        flyMax=max(flyArea);
        multMax=max(multiArea);
        multMin=flyMax+1;
        %multMin=mean(flyMax,min(multiArea));
    end    
     
    %analyze the videos one at a time
    for gg=1:size(fileName,2)
        videoName=fullfile(filePath, fileName{gg});
        
        %needed for naming the output cell matrix
        vialNumber=fileName{gg}(max(strfind(fileName{gg},'_'))+1:end-4);

        % Create a video reader.
        obj.reader = VideoReader(videoName); 
        
        %set time of interest default to full video duration if unspecified
        if isempty(timeOfInterest)
            timeOfInterest=obj.reader.Duration; 
        end
        %adjust time of interest to number of frames
        analyzedTime=timeOfInterest*obj.reader.FrameRate; 
        if obj.reader.NumFrames<analyzedTime %check if there are enough frames in the video
            analyzedTime=obj.reader.NumFrames;
            disp(strcat('not enough frames, will analyse the partial video for ', fileName{gg}));
        end
        
        % If applicable, create video player 
        if showTracking==1
            obj.videoPlayer = vision.VideoPlayer('Position', [540, 200, 100, 800]);
        end  
        
        % Create an empty array of tracks.
        tracks = initializeTracks();
        
        %initialize variables
        nextId = 1; % ID of the next track. Initialized at 1.
        currframes=1; %keep track of the frame you are analyzing
        numFlies=numFliesArray(str2double(vialNumber));
        coord=NaN(analyzedTime,numFlies*2);%initialize coordinate output

        %use videoreader to obtain the background for FindFlies function
        %This step is here to avoid looping. Makes the analysis faster. 
        obj.reader.CurrentTime=0; 
        bg=zeros(obj.reader.Height,obj.reader.Width,obj.reader.NumFrames); %preallocate bg
        counter=1;
        while hasFrame(obj.reader)
            imgB=rgb2gray(im2single(readFrame(obj.reader)));
            bg(:,:,counter)=imgB;
            counter=counter+1; 
        end
        background=median(bg,3);%create background

        obj.reader.CurrentTime=0;%rewind video to first frame

        
        %If applicable, create video writer for recording tracked video
        if saveTrackVideo==1
            newfilename=strcat(videoName(1:end-4),'_track'); %append 'track' to file name
            writer = VideoWriter(newfilename, 'MPEG-4');%create a video writer
            %match new video file framerate to original video file frame rate
            writer.FrameRate = obj.reader.FrameRate;
            open(writer);%prepare it to start writing
        end

        
        % Detect moving objects, and track them across video frames.   
        while currframes<=analyzedTime
            %detect objects in the frame using multiobject motion tracking
            frame = readFrame(obj.reader);

            %find the center of of the flies
            [centroids,bboxes]=FindFlies();
            
            predictNewLocationsOfTracks();
            
            [assignments, unassignedTracks, unassignedDetections] = ...
            detectionToTrackAssignment();

            updateAssignedTracks();
            updateUnassignedTracks();
            %deleteLostTracks(); 
            createNewTracks();
           
            %if displaying or saving tracked video to file
            if saveTrackVideo==1 || showTracking==1
                displayTrackingResults();
            end

            %record coordinates to coord variable that is eventually placed
            %in the vidMatrix cell array for the completed tracking
            if ~isempty(tracks)
                centers=cat(2,tracks.centroid);
                coord(currframes,1:size(centers,2))=centers;
            end

            %incriment the frame number
            currframes=currframes+1;       
        end
        
        %at the end of tracking, fill in coordinates for motionless flies
        c=numFlies*2;
        while c>1 && isnan(coord(analyzedTime,c))&& isnan(coord(analyzedTime/2,c)) 
            coord(:,c-1)=randi([1,obj.reader.Width],1);
            coord(:,c)=obj.reader.Height;
            c=c-2;
        end

        if saveTrackVideo==1
            close(writer);
        end

        if saveCoord==1
            %names for saved files extrapolated from input video file names
            coordName=strcat(strcat('coord',fileName{gg}(4:max(strfind(fileName{gg},'_'))-1)),'.mat');
            
            %save video mat file 
            if isfile(coordName)
                vidMatrix=struct2cell(load(coordName));
                vidMatrix=vidMatrix{1};
                vidMatrix{str2double(vialNumber)}=coord(1:analyzedTime,:);
                save(coordName,'vidMatrix');
            else
                vidMatrix{str2double(vialNumber)}=coord(1:analyzedTime,:);
                save(coordName,'vidMatrix');
            end
        else
            vidMatrix{str2double(vialNumber)}=coord(1:analyzedTime,:);
        end
    end
    
    
    function tracks = initializeTracks()
        % create an empty array of tracks
        tracks = struct(...
            'id', {}, ...
            'centroid',{},...
            'bbox', {}, ...
            'kalmanFilter', {}, ...
            'age', {}, ...
            'totalVisibleCount', {}, ...
            'consecutiveInvisibleCount', {},...
            'prevCentroid', {});
    end

    function [centroids,bboxes]=FindFlies()

        %subtract background from input frame
        imgA=rgb2gray(im2single(frame));
        subframe=background-imgA;
        subframe(subframe(:,:)<=.06)=0;%erase background
        subframe(subframe(:,:)>0)=1;%make flies brighter

        %gets rid of small objects
        cleanframe=bwareaopen(subframe,flyMin); 
        connframe=bwconncomp(cleanframe,8);%fills in the missing pixels  

        %get rid of large objects
        flies=regionprops(connframe,'Area','MajorAxisLength','MinorAxisLength');
        temp_area=cat(1,flies.Area);
        temp_max=cat(1,flies.MajorAxisLength);
        temp_min=cat(1,flies.MinorAxisLength);
        noise=find(temp_area>multMax|temp_max>maxLengthMult|temp_min<minLengthSingle);
        for ii=1:length(noise)
            cleanframe(connframe.PixelIdxList{noise(ii)})=0;
        end
        connframe=bwconncomp(cleanframe,8);

        %get information about detected objects after cleaning
        flies=regionprops(connframe,'Centroid','BoundingBox','Area','MajorAxisLength','MinorAxisLength');
        start_centroids=cat(1,flies.Centroid);
        start_bboxes=cat(1,flies.BoundingBox);
        temp_area=cat(1,flies.Area);
        majLengths=cat(1,flies.MajorAxisLength);
        minLengths=cat(1,flies.MinorAxisLength);
        

        counter=0;
        %for every area that is greater than the area of a single fly 
        %duplicate the centroid and bbox thus creating 2 detections. This
        %is done because the likelyhood of this one detection being
        %multipile flies is high, and we want to be able to include them
        %both in our detection list. 
        for ii=1:size(temp_area,1)
            counter=counter+1;
            if temp_area(ii)>=multMin&&...
                    majLengths(ii)<=maxLengthMult&&...
                    minLengths(ii)>=minLengthMult  
                instances=floor(temp_area(ii)/flyMax);
                for pp=1:instances
                    start_centroids(end+1,:)=start_centroids(ii,:);
                    start_bboxes(end+1,:)=start_bboxes(ii,:);
                end                
            end
        end
        centroids=start_centroids;
        bboxes=start_bboxes;
    end
    
    function predictNewLocationsOfTracks()
        for i = 1:length(tracks)
            bbox = int32(tracks(i).bbox);

            % Predict the current location of the track using Kalman filter
            predictedCentroid = predict(tracks(i).kalmanFilter);
            predictedCentroid = int32(predictedCentroid) - bbox(3:4) / 2;           
        end
    end


    function [assignments, unassignedTracks, unassignedDetections] = ...
            detectionToTrackAssignment()
       
        nTracks = length(tracks);
        nDetections = size(centroids, 1);
        
        if nDetections~=0                
            %using Euclidean distances between the predicted and detected
            %coordinates and between the previous and deteced coordinates
            % to create a cost matrices
            cost = zeros(nTracks, nDetections);
            costk = zeros(1, nDetections);
            costp = zeros(1, nDetections);
            if ~isempty(tracks)
                prevCenters=vertcat(tracks.prevCentroid);
            end
            for i = 1:nTracks
                %cost between predicted and detected coordinates
                costk(1, :) = distance(tracks(i).kalmanFilter, centroids);
                
                %cost between previous and detected coordinates
                costpp=pdist([prevCenters(i,:);centroids(:,:)],'euclidean');
                costp(1,:)=sqrt(costpp(1,1:nDetections));
                
                %final cost is sqrt(costk * sqrt(costp))
                cost(i,:)=sqrt(costk.*costp);
                
                %The reason I use this cost is because both of these are important
                %factors to consider when assigning the detection to a
                %track. You want to know where it 'should' be and where
                %it was and compare to what is found. Both a large and small
                %number varation will make defining the threshold of what
                %is correct difficult. And because flies fly and fall, the
                %are not always following a linear pattern as is assumed by
                %the prediction. In addition the distance traveled by a
                %a fly can vary dramatically. This is why costp is square rooted 
                %first. The prediction is between the predicted and
                %detected coordinates so this variation may be big, but
                %ultimatly will on average be much smaller in comparision.
                %The multiplication of these values makes the range much
                %bigger than optimal, which is why we square it again. 
            end

            costOfNonAssignment =11; %found by trial and error and analysis
            [assignments, unassignedTracks, unassignedDetections] = ...
                assignDetectionsToTracks(cost, costOfNonAssignment);

            %make sure there are only the same amount of tracks as there are 
            %number of flies
            tooManyTracks=find(assignments(:,1)>numFlies);
            unassignedDetections=vertcat(unassignedDetections,assignments(tooManyTracks,2));
            assignments(tooManyTracks,:)=[];

            %because unassignedDetections create new tracks, it is
            %important to make sure you do not create extra tracks
            unforgivenNum=numFlies-size(assignments,1)-numel(unassignedTracks);
            while unforgivenNum<numel(unassignedDetections) 
                if ~isempty(assignments)
                    prevCentroids=vertcat(tracks.prevCentroid);
                    unassCentroids=centroids(unassignedDetections,:);
                    tsize=size(unassignedTracks,1);
                    dista=NaN(tsize,size(unassCentroids,1));
                    %find the distance between previous centroids of
                    %unassignedTracks and current unassignedDetections
                    for jj=1:tsize
                        dista(jj,:)=sqrt(((prevCentroids(unassignedTracks(jj),1)-unassCentroids(:,1)) .^2) ...
                            + ((prevCentroids(unassignedTracks(jj),2)-unassCentroids(:,2)) .^2));
                    end
                    %find the maximum distance and remove from list
                    %entirely. This method is a bit arbitrary, but since
                    %the cost of each was too high for any of these
                    %detections to be assigned it would be a lot of work
                    %for little pay off.  
                    [maxRowDista,locRowDista]=max(dista,[],2);
                    [~,locDista]=max(maxRowDista);
                    if ~isempty(locDista) && unforgivenNum>0
                        unassignedDetections(locRowDista(locDista))=[];
                    else 
                        unassignedDetections=[];
                    end          
                else
                    nDetect=numFlies-size(unassignedTracks,1);
                    unassignedDetections=unassignedDetections(1:nDetect);
                end
            end
        else
            %if no detections are found
            unassignedTracks=vertcat(tracks.id);
            assignments=[];
            unassignedDetections=[];
        end
                
    end

    function updateAssignedTracks()
        numAssignedTracks = size(assignments, 1);
        for i = 1:numAssignedTracks
            trackIdx = assignments(i, 1);
            detectionIdx = assignments(i, 2);
            centroid = centroids(detectionIdx, :);
            bbox = double(bboxes(detectionIdx, :));    

            % Correct the estimate of the object's location using the new detection.
            correct(tracks(trackIdx).kalmanFilter, centroid);

            %update track
            tracks(trackIdx).prevCentroid=centroid;
            tracks(trackIdx).centroid=centroid;
            tracks(trackIdx).bbox = bbox;
                
           % Update track's age.
            tracks(trackIdx).age = tracks(trackIdx).age + 1;

            % Update visibility.
            tracks(trackIdx).totalVisibleCount = tracks(trackIdx).totalVisibleCount + 1;
            tracks(trackIdx).consecutiveInvisibleCount = 0; 
                                  
        end
    end
    
    function updateUnassignedTracks()
        for i = 1:length(unassignedTracks)
            ind = unassignedTracks(i);
            %use previous centroid to fill in coordinates so at the end of
            %the tracking there are no gaps that will effect analysis
            tracks(ind).centroid=tracks(ind).prevCentroid;
            tracks(ind).age = tracks(ind).age + 1;
            tracks(ind).consecutiveInvisibleCount = ...
                tracks(ind).consecutiveInvisibleCount + 1;
        end
    end
    
%{
    function deleteLostTracks()
        %Not used in our experiment because all the flies should be visible
        %throughout the entirety of the expeirment (theoretically). This is
        %left over from the Multi-object tracking code shell provided by
        %Matlab. If someone wishes to modify the code to fit a different
        %experiment it is left in. 
        
        if isempty(tracks)
            return;
        end

        invisibleForTooLong =analyzedTime;
        ageThreshold = 1;

        % Compute the fraction of the track's age for which it was visible.
        ages = [tracks(:).age];
        totalVisibleCounts = [tracks(:).totalVisibleCount];
        visibility = totalVisibleCounts ./ ages;

        % Find the indices of 'lost' tracks.
        lostInds = (ages < ageThreshold & visibility < 0.6) | ...
            [tracks(:).consecutiveInvisibleCount] >= invisibleForTooLong;

        % Delete lost tracks.
        tracks = tracks(~lostInds);
    end
%}        

    function createNewTracks()
        %If a new detection is found at the top for the first time, most
        %liekely it is noise, so we get rid of it (particularly important
        %in the beginning of each geotaxis experiment)
        if ~isempty(unassignedDetections)
            unassignedCenters=centroids(unassignedDetections,2);
            unassignedDetections(unassignedCenters<obj.reader.Height/4)=[];
        end
        
        %triple check you are not creating more tracks then there are flies
        if nextId<=numFlies
            centroids = centroids(unassignedDetections, :);
            bboxes = bboxes(unassignedDetections, :);

            for i = 1:size(centroids, 1)

                centroid = centroids(i,:);
                bbox = bboxes(i, :);

                % Create a Kalman filter object.
                kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
                    centroid, [200,50],[10000,10000],20);
                
                % Create a new track.
                newTrack = struct(...
                    'id', nextId, ...
                    'centroid', centroid,...
                    'bbox', bbox, ...
                    'kalmanFilter', kalmanFilter, ...
                    'age', 1, ...
                    'totalVisibleCount', 1, ...
                    'consecutiveInvisibleCount', 0,...
                    'prevCentroid',centroid);

                % Add it to the array of tracks.
                tracks(end + 1) = newTrack;

                % Increment the next id.
                nextId = nextId + 1;
            end
        end
        
    end

    function displayTrackingResults()
        % Convert the frame and the mask to uint8 RGB.
        frame = im2uint8(frame);

        minVisibleCount = 1;
        if ~isempty(tracks)
            % Noisy detections tend to result in short-lived tracks.
            % Only display tracks that have been visible for more than
            % a minimum number of frames.
            reliableTrackInds = ...
                [tracks(:).totalVisibleCount] > minVisibleCount;
            reliableTracks = tracks(reliableTrackInds);

            % Display the objects. 
            if ~isempty(reliableTracks)
                bboxes = cat(1, reliableTracks.bbox);% Get bounding boxes.

                ids = int32([reliableTracks(:).id]);% Get ids.

                % Create labels for objects indicating the ones for
                % which we display the predicted rather than the actual
                % location.
                labels = cellstr(int2str(ids'));
                
                % Draw the objects on the frame.
                frame = insertObjectAnnotation(frame, 'rectangle', bboxes, labels);
            end
        end
        
        if showTracking==1
            %display the tracking
            obj.videoPlayer.step(frame);
        end 
        
        %write new frame with the mask to the tracked video
        if saveTrackVideo==1
            writeVideo(writer,frame);
        end
    end
    
end