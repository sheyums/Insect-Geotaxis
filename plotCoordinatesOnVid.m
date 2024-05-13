function plotCoordinatesOnVid(flyNumber)
    
    colorMap = jet(300);

    %get video file
    [fileName, filePath] = uigetfile('*.*' , 'Select video file','MultiSelect','off');
    if ~iscell(fileName), fileName=cellstr(fileName); end

    videoName=fullfile(filePath, char(fileName(1,1)));
    vidObj=VideoReader(videoName);
    vidObj.CurrentTime=0;
    
    currVideoFile=fileName{1,1};
    videoNumber=str2double(currVideoFile(max(strfind(currVideoFile,'_'))-1));
    
    newfilename=strcat(videoName(1:end-4),'_plotted'); %append 'track' to file name
    writer = VideoWriter(newfilename, 'MPEG-4');%create a video writer
    %match new video file framerate to original video file frame rate
    writer.FrameRate = vidObj.FrameRate;
    open(writer);%prepare it to start writing
    
    %get matrix file
    [fileNameCoord, filePathCoord] = uigetfile('*.*' , 'Select Coordinate Cell Matrix .mat File','MultiSelect','off');
    coordinates=load(fullfile(filePathCoord,fileNameCoord)); 
    if ~iscell(coordinates) 
        coordinates=struct2cell(coordinates);
        coordinates=coordinates{1};
    end
    
    coord=coordinates{videoNumber};
    coordSize=size(coord,1);
    
    
    counter=1;
    while counter<coordSize
        vidObj.CurrentTime=counter/30;
        frame=readFrame(vidObj);        
        imshow(frame)
        hold on 
        for ii=1:counter
            color = colorMap(ii,:);
            plot(coord(ii,(flyNumber*2)-1),coord(ii,(flyNumber*2)),'*-','Color',color);
        end
        newFrame=getframe();
        writeVideo(writer,newFrame);
        
        counter=counter+1;
    end


end