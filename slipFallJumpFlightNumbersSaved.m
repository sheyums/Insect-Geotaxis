function slipFallJumpFlightNumbersSaved()
%This function is used in tandum with the fly slammer coordinate
%information. Should be used after the groupTracksPerVial function
    %select desired vials from experiment folder
    [fileName, filePath] = uigetfile('*.*','Select vial# .mat files  for Given Experiment corresponding to the same genotype','MultiSelect','on');  
    if ~iscell(fileName)
        fileName=cellstr(fileName);
    end
    
    %label the vials with the fly name
    userInput = inputdlg({'Name of mutant'},'Select Perameters' ,[1 40],{'wildtype'});
    
    %initiate variables
    slips=0;
    falls=0;
    jumps=0;
    flights=0;
    slipMatrix=[];
    fallMatrix=[];
    jumpMatrix=[];
    flightMatrix=[];
    numtracks=0;
    instances=0;
    
    %go through each vial matrix and extract info
    %slips defines as -20>x>-50 between consecutive y coordinates
    %falls defined as x<-50 between consecutive y coordinates
    %numTracks = #flies * #trials
    %total moves = assessed data points for the input information
    for gg=1:size(fileName,2)
        vialName=fullfile(filePath, fileName{gg});   
        
        %load matrix
        vialMatrix=cell2mat(struct2cell(load(vialName)));
        maxCoord=max(max(vialMatrix(:,2:2:end))); %find max coordinate
        %convert the y coordinate movement to the correct direction since
        %matlab images have the 0,0 coordinate at the top right so we must
        %invert the data
        vialyMatrix=vialMatrix(:,2:2:end)*-1;
        vialyMatrix=vialyMatrix+maxCoord;
        
        %distance traveled in the y coordinate
        subyMatrix=vialyMatrix(2:end,:)-vialyMatrix(1:end-1,:);
        
        %count up all the slips and falls
        slips=slips+numel(find(subyMatrix<-20&subyMatrix>-50));
        slipMatrix=[slipMatrix;subyMatrix(subyMatrix<-20&subyMatrix>-50)];
        
        falls=falls+numel(find(subyMatrix<=-50));
        fallMatrix=[fallMatrix;subyMatrix(subyMatrix<=-50)];
        
        jumps=jumps+numel(find(subyMatrix>=20&subyMatrix<50)); 
        jumpMatrix=[jumpMatrix;subyMatrix(subyMatrix>=20&subyMatrix<50)];
        
        flights=flights+numel(find(subyMatrix>=50)); 
        flightMatrix=[flightMatrix;subyMatrix(subyMatrix>=50)];
        
        numtracks=numtracks+size(subyMatrix,2);
        instances=instances+size(subyMatrix,1)*size(subyMatrix,2);
        
    end

    %put all information in a cell to save into excel file
    slipsFallsJumpsFlights={'# slips', '# falls','# jumps','# flights','# tracks','total moves';slips,falls,jumps, flights,numtracks,instances};
    
    %save
    fileNameMutant=strcat('\',userInput{1},'.xlsx');
    writecell(slipsFallsJumpsFlights, strcat(filePath,fileNameMutant),'Sheet',1);
    writematrix(slipMatrix, strcat(filePath,fileNameMutant),'Sheet','slips');
    writematrix(fallMatrix, strcat(filePath,fileNameMutant),'Sheet','falls');
    writematrix(jumpMatrix, strcat(filePath,fileNameMutant),'Sheet','jumps');
    writematrix(flightMatrix, strcat(filePath,fileNameMutant),'Sheet','flights');


end