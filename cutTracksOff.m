function cutTracksOff()

    [fileName, filePath] = uigetfile('*.*','Select coord.mat Files for Given Experiment','MultiSelect','on');  
    if ~iscell(fileName)
        fileName=cellstr(fileName);
    end
    
    
    for gg=1:size(fileName,2)
        coordName=fullfile(filePath, fileName{gg});    
        newCoordName=strcat(coordName(1:end-4),'_cut');
        
        vidMatrixCut=[];
        
        vidMatrix=struct2cell(load(coordName));
        vidMatrix=vidMatrix{1}; 
        
        for ii=1:size(vidMatrix,2)
            vialMatrix=vidMatrix{ii};
                        
            minimums=15;
    
            for jj=1:(size(vialMatrix,2)/2)
                loc=find(vialMatrix(:,jj*2)<=minimums,1,'first');
                vialMatrix(loc:end,jj*2-1:jj*2)=NaN;
            end
            
            vidMatrixCut{1,ii}=vialMatrix;
        end        
        
        save(strcat(newCoordName,'.mat'),'vidMatrixCut');
    end

end