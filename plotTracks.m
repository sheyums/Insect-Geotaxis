function plotTracks(vialNumber, flyNumbers, onVideo, seperate, colored)
%vialNumber = specify the vial you are plotting from the experiment (1-10)
%flyNumbers = the fly corresponding track numbers user wishes to plot (1-7)
%   ex: [1,3,7]
%onVideo = if the user wants to plot the coordinates of the flies on the
%video
%seperate = if you want the plotted lines to be on the same vidoe/graph or
%seperately 
%colored = rainbow color points or solid colors

        
    colorMap = jet(300);
    pointColors={'m.','c.','g.','r.','b.','y.','k.'};
    
    %get matrix file
    [fileNameCoord, filePathCoord] = uigetfile('*.*' , 'Select Coordinate Cell Matrix .mat File','MultiSelect','off');
    coordinates=load(fullfile(filePathCoord,fileNameCoord)); 
    if ~iscell(coordinates) 
        coordinates=struct2cell(coordinates);
        coordinates=coordinates{1};
    end
    
    coord=coordinates{vialNumber};
    coordSize=size(coord,1);
    
    if onVideo==1
        %get video file
        [fileName, filePath] = uigetfile('*.*' , 'Select video file','MultiSelect','off');
        if ~iscell(fileName), fileName=cellstr(fileName); end
        
        videoName=fullfile(filePath, char(fileName(1,1)));
        vidObj=VideoReader(videoName);
        vidObj.CurrentTime=0;
        
        if seperate==0
            newfilename=strcat(videoName(1:end-4),'_plotted_all'); %append 'track' to file name
            writer = VideoWriter(newfilename, 'MPEG-4');%create a video writer
            %match new video file framerate to original video file frame rate
            writer.FrameRate = vidObj.FrameRate;
            open(writer);%prepare it to start writing
           
                counter=1;
                while counter<coordSize                
                    vidObj.CurrentTime=counter/30;
                    frame=readFrame(vidObj);        
                    imshow(frame)
                    hold on 
                    for ii=1:counter
                        if colored==1
                            color = colorMap(ii,:);
                            for jj=1:size(flyNumbers,2)
                                plot(coord(ii,(flyNumbers(jj)*2)-1),coord(ii,(flyNumbers(jj)*2)),'.-','Color',color);
                            end
                        else
                            for jj=1:size(flyNumbers,2)
                                color=pointColors{jj};
                                plot(coord(ii,(flyNumbers(jj)*2)-1),coord(ii,(flyNumbers(jj)*2)),color);
                            end
                        end
                    end
                    newFrame=getframe();
                    writeVideo(writer,newFrame);

                    counter=counter+1;

                    if counter==4 || counter==60 || counter==120 || counter==180 || counter==240 || counter==300
                        disp('here')
                    end
                end
            
        else            
            for jj=1:size(flyNumbers,2)
                newfilename=strcat(strcat(videoName(1:end-4),'_plotted'),num2str(jj)); %append 'track' to file name
                writer = VideoWriter(newfilename, 'MPEG-4');%create a video writer
                %match new video file framerate to original video file frame rate
                writer.FrameRate = vidObj.FrameRate;
                open(writer);%prepare it to start writing
                counter=1;
                while counter<coordSize                
                    vidObj.CurrentTime=counter/30;
                    frame=readFrame(vidObj);        
                    imshow(frame)
                    hold on 
                    for ii=1:counter
                        if colored==1
                            color = colorMap(ii,:);
                            plot(coord(ii,(flyNumbers(jj)*2)-1),coord(ii,(flyNumbers(jj)*2)),'.-','Color',color);
                        else
                            color=pointColors{jj};
                            plot(coord(ii,(flyNumbers(jj)*2)-1),coord(ii,(flyNumbers(jj)*2)),color);
                        end
                    end
                    newFrame=getframe();
                    writeVideo(writer,newFrame);

                    counter=counter+1;

                    if counter==4 || counter==60 || counter==120 || counter==180 || counter==240 || counter==300
                        disp('here')
                    end
                end
                close(writer);
            end
        end
    else
        coord(:,2:2:end)=(coord(:,2:2:end)*-1)+max(max(coord));
        if seperate==1
            for jj=1:size(flyNumbers,2)
                figure
                if colored==1
                    for ii=1:size(coord,1)
                        color = colorMap(ii,:);
                        plot(coord(ii,(flyNumbers(jj)*2)-1),coord(ii,(flyNumbers(jj)*2)),'.-','Color',color);
                        hold on
                    end
                else
                    color=pointColors{jj};
                    plot(coord(:,(flyNumbers(jj)*2)-1),coord(:,(flyNumbers(jj)*2)),color);
                end
            end

        else
            figure
            for jj=1:size(flyNumbers,2)
                if colored==1
                    for ii=1:size(coord,1)
                        color = colorMap(ii,:);
                        plot(coord(ii,(flyNumbers(jj)*2)-1),coord(ii,(flyNumbers(jj)*2)),'.-','Color',color);
                        hold on
                    end
                    
                else
                    color=pointColors{jj};
                    plot(coord(:,(flyNumbers(jj)*2)-1),coord(:,(flyNumbers(jj)*2)),color);
                end
                hold on
            end
        end

    end
end