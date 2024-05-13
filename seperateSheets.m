function seperateSheets()
%seperates each coordinate cell matrix output from function
%'Fly_tracking'into vials then into trials within the same experiment.
    [fileName, filePath] = uigetfile('*.*','Select coord.mat Files for Given Experiment','MultiSelect','on');  
    if ~iscell(fileName)
        fileName=cellstr(fileName);
    end
    
    for gg=1:size(fileName,2)
        coordName=fullfile(filePath, fileName{gg});          
        trialName=fullfile(filePath,'trial_');

    
        %save experiment mat file 
        if isfile(coordName)
            vidMatrix=struct2cell(load(coordName));
            vidMatrix=vidMatrix{1};
            for jj=1:size(vidMatrix,2)
                trialName=strcat(strcat(strcat(trialName,strcat(num2str(jj),'_')),fileName{gg}(min(strfind(fileName{gg},'_'))+1:end)),'.mat');
                trial=vidMatrix{1,jj};
                save(trialName,'trial');
                trialName=fullfile(filePath,'trial_');
            end
        end
        
    end


end