function groupTracksPerVial()
%utilizes coord.mat cell matrix from function Fly_Tracking and creates
%individual matrices for each vial which includes all trials
    [fileName, filePath] = uigetfile('*.*','Select coord.mat Files for Given Experiment','MultiSelect','on');  
    if ~iscell(fileName)
        fileName=cellstr(fileName);
    end
    
    for gg=1:size(fileName,2)
        coordName=fullfile(filePath, fileName{gg});          
        expName=fullfile(filePath,strcat(strcat('exp',fileName{gg}(min(strfind(fileName{gg},'_'))-1)),'.mat'));

    
        %save experiment mat file 
        if isfile(expName)&& isfile(coordName)
            vidMatrix=struct2cell(load(coordName));
            vidMatrix=vidMatrix{1};
            expMatrix=struct2cell(load(expName));  
            expMatrix=expMatrix{1};
            for jj=1:size(expMatrix,2)
                ey=size(expMatrix{jj},2);
                vy=size(vidMatrix{jj},2);
                expMatrix{jj}(:,ey+1:ey+vy)=vidMatrix{jj};
            end
            save(expName,'expMatrix');
        elseif isfile(coordName)        
            vidMatrix=struct2cell(load(coordName));
            vidMatrix=vidMatrix{1};
            expMatrix=vidMatrix;
            save(expName,'expMatrix');
        end  
    end
    
    for pp=1:size(expMatrix,2)
        vial=expMatrix{1,pp};
        vialName=fullfile(filePath,strcat(strcat('vial',int2str(pp)),'.mat'));
        save(vialName,'vial');
    end


end