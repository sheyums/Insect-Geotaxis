function combinedMatrix=combineVials()

    [fileName, filePath] = uigetfile('*.*','Select coord.mat Files to combine','MultiSelect','on');  
    if ~iscell(fileName)
        fileName=cellstr(fileName);
    end
    
    combinedMatrix=[];
    
    for gg=1:size(fileName,2)
        coordName=fullfile(filePath, fileName{gg});
        
        coordMatrix=struct2cell(load(coordName));
        coordMatrix=coordMatrix{1};
        
        combinedMatrix=[combinedMatrix,coordMatrix];
    end
    
    userInput=inputdlg({'Fly Name'},'Select Perameters',[1,40],{'cs_f_27DAE_2023_04_04'});
    
    save(strcat(userInput{1},".mat"),'combinedMatrix');
   
end