function kymographForTracking(vialNumbersArray)

    pixelTOdistance=4.243;%pixel to mm conversion
    duration=2; %number of seconds to plot
    fsp=30;%frames per second of video
    timeAnalyzed=duration*fsp;%number of x points for graph
    %color=[0,0,1;0,1,0;1,0,0;1,1,0;0,1,1;1,0,1;1,1,1;0,0,0];
    time=1:timeAnalyzed;
    time=reshape(time,[timeAnalyzed,1]);
    nanBuffer=NaN(timeAnalyzed,1);

    %load coord matrix
    [fileName, filePath] = uigetfile('*.*','Select singular .mat coordinate cell matrix','MultiSelect','off');  
    if ~iscell(fileName)
        fileName=cellstr(fileName);
    end
    coordName=fullfile(filePath, fileName);      
    coordMatrix=struct2cell(load(coordName{1}));
    coordMatrix=coordMatrix{1};
    
    %create figure
    %figure(1);
    
    colnames={'Time (frames)'};
    
    output=[time];
    
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
        end
    end
    
    userInput=inputdlg({'Kymograph Name'},'Select Perameters',[1,70],{'2023_08_28_exp1_v5and7_Kgraph'});
   
    
    writetable(array2table(output,'VariableNames',colnames),strcat(userInput{1},'.xls'))
        
 
        
%{
        %if you want to plot quickly 
        
        %plot each vial with single color
        for jj=1:(size(vialMat,2))
            if jj==size(vialMat,2)
                f1=plot(time,vialMat(:,jj),'Color',color(ii,:),'DisplayName',strcat('vial #',num2str(vialNumbersArray(ii))));
            else
                f1=plot(time,vialMat(:,jj),'Color',color(ii,:));
            end
            ylabel('Height (mm)');
            xlabel('Time (frame)');
            hold on
        end
        hold on 

    end
    legend

    userInput=inputdlg({'Kymograph Name'},'Select Perameters',[1,70],{'2023_08_28_exp1_v5and7_Kgraph'});
    saveas(f1,userInput{1},'jpeg');
%}

end