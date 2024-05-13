function kymographForTracking_graph(vialNumbersArray,duration)
%first input the vial numbers you wish to plot on the same graph. NOTE: each
%TRIAL is plotted seperatly, so you should have up to 7 flies per group per
%graph. 
%example, [3,7]  would indicate you wish to plot all flies from vials 3 and
%7
%second input indicatds the duration in seconds to plot on the graph. This
%number will automatically be converted to frames according to the fsp
%(frames per second) which is defined by the video frame used for the
%tracking.
    if nargin<2
        duration=2;% number of seconds desired to view
    end

    pixelTOdistance=4.243;%pixel to mm conversion
    fsp=30;%frames per second of video
    timeAnalyzed=duration*fsp;%number of x points for graph
    color=[0,0,1;1,0,0;0,1,0;1,1,0;0,1,1;1,0,1;1,1,1;0,0,0];
    time=1:timeAnalyzed;
    time=reshape(time,[timeAnalyzed,1]);

    %load coord matrix
    [fileName, filePath] = uigetfile('*.*','Select singular .mat coordinate cell matrix','MultiSelect','off');  
    if ~iscell(fileName)
        fileName=cellstr(fileName);
    end
    coordName=fullfile(filePath, fileName);      
    coordMatrix=struct2cell(load(coordName{1}));
    coordMatrix=coordMatrix{1};
    
    %create figure
    figure(1);
    
    colnames={'Time (frames)'};
    
    output=(time);
    
    %invert matlab image and convert distance from pix to mm 
    for ii=1:size(vialNumbersArray,2)
        vialMatrix=coordMatrix{vialNumbersArray(ii)};
        topofvial=max(max(vialMatrix));%find bottom of the vial
        vialMat=vialMatrix(1:timeAnalyzed,2:2:end); %cut down to desired analysis time
        vialMat=(vialMat-topofvial)*-1; %convert pixel numbers to correct orientation
        vialMat=vialMat./pixelTOdistance;%convert from pix to mm
        
        output=[output,vialMat];
        
        for kk=1:size(vialMat,2)
            colnames{end+1}=strcat(strcat(strcat('vial',num2str(vialNumbersArray(ii)),'_'),num2str(kk)));
            
            %plot
            f1=plot(time,vialMat(:,kk),'Color',color(ii,:),'DisplayName',colnames{end});
            hold on
        end
        ylabel('Height (mm)');
        xlabel('Time (frame)');
        hold on
    end
    legend
    
    %name files
    userInput=inputdlg({'Kymograph Name'},'Select Perameters',[1,70],{'2023_08_28_exp1_v5and7_Kgraph'});
   
    %save file
    writetable(array2table(output,'VariableNames',colnames),strcat(userInput{1},'.xls'))
    %save graph
    saveas(f1,userInput{1},'jpeg');
 

end