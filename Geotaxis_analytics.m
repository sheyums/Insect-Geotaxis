
function datastr= Geotaxis_analytics(distTOpixel,framerate,maxYpixel,group)

%%%%%% Wrote this function to compare fly geotaxis results from multiple
%%%%%% trials. The function will prompt user to pick one or more .mat files
%%%%%% containing fly x-y location data from multiple trials. The .mat
%%%%%% files are expected to be in one folder.

%   Example use:
%   y=Geotaxis_analytics(pixelTOdistance,framerate,maxYpixel,genotype)
%
%   y=Geotaxis_analytics(4.243,30,4,{'fic0female','csmale','yw'});
%
%
%
% INPUTS: distTOpixel     = number of pixels representing 1 millimeter.
%                           e.g.: 4.243
%         framerate       = number of video frames captured per second.
%                           e.g.: 30
%         maxYpixel       = position of the highest y pixel in camera
%                           frame. Note: Matlab assigns (0,0) to top left
%                           of image, near the highest position reached by
%                           flies. So, maxYpixel is paradoxically a small
%                           number. e.g.: 4.
%         group           = not a required input. The only non-numeric
%                           input variable, it is used to label figure
%                           window which shows results from all groups.
%                           e.g.: {'DEMO 1','CS','YW'}

%
%

% OUTPUTS: [1] datastr=> a structure with nested structure 'Group', which
%                        has 3 fields: Names (character strings), 
%                                      ClimbCurves (matrices), 
%                                      Fly_no (structure)
%
%         datastr.Group.Names         = user-provided names of groups
%                                      (INPUT: group)
%                                      of genotypes, trials, strain names, etc. 
%                                      corresponding to the datafiles
%                                      selected upon prompt. e.g: for the
%                                      first group name, type
%                                      datastr.Group(1).Name
% 
%
%         datastr.Group.ClimbCurves   = matrices containing climbing rate
%                                       data of each group or the percentage 
%                                       of flies in a group that are at a given 
%                                       height at a given time. Number of
%                                       matrices is equal to the number of
%                                       groups or input files. Each matrix
%                                       is of size #rows x 4.
%                                       The 1st column is time, 2nd column
%                                       is climbing rate for max height,
%                                       3rd column is climbing rate for
%                                       half max height and 4th column is
%                                       climbing rate for third of max
%                                       height. e.g: To output the climbing
%                                       data for group#3, type
%                                       datastr.Group(3).ClimbCurves.
%
%
%          datastr.Group.Fly_no       = a structure with 5 fields:
%                                       SpdAngle, NRMSE, AveSpeed, Slips,
%                                       Falls. 'SpdAngle' contains
%                                       frame-by-frame speed (col 1) and
%                                       angular (column 2)
%                                       movement data of individuals;
%                                       'NRMSE' contains normalized RMSE of
%                                       fitting fly (x,y) coordinates to a
%                                       straight line, as a crude measure
%                                       of the type of individual
%                                       trajectory;
%                                       'AveSpeed' is the average speed of
%                                       an individual fly. It can differ
%                                       from the average of all the
%                                       frame-by-frame speed measurements
%                                       when a fly was undetectable for
%                                       several frames because it was
%                                       immobile. So for any fly
%                                       Avespeed<=mean(SpdAngle(:,1));
%                                       'Slips' contains list of sudden
%                                       drops in height, more than ~ 4mm
%                                       but less than ~11.5mm. Slips(i,1) is
%                                       the time when the event happened,
%                                       Slips(i,2) is the height from which
%                                       the drop happened, Slips(i,3) is
%                                       the size of the drop;
%                                       'Falls' is similar to 'Slips' but
%                                       for drops > 11.5 mm.
%                                       e.g: To output the slips data for
%                                       fly# 31 in group# 2, type
%                                       datastr.Group(2).Fly_no(31).Slips
%
%
%
%
%          [2] Excel workbook containing results from each group in a
%           different sheet. Last sheet contains collated data from all
%           groups being compared. The workbook is saved in the same folder
%           as the .mat files that were fed to this function. The name of
%           the Excel file bears the name of the first input file that was
%           read.

% *************Written by Sheyum, February 2022. 
% *******Modified August 2022. February 2023. May 2023. September 2023. March 2024.
% 


close all   %%% close any open windows

% initialize output structure
datastr=struct('Group',struct('Names',[],'ClimbCurves',[],'Fly_no',struct(...
    'SpdAngle',[],'NRMSE',[], 'AveSpeed',[],'Slips',[],'Falls',[])));


if nargin<4 || ~iscell(group), group=[]; end
if nargin<3 || isempty(maxYpixel), maxYpixel=4; end  %%%
if nargin<2 || isempty(framerate), framerate=30;end   %%%number of CCD frames per second
if nargin<1 || isempty(distTOpixel),  distTOpixel=4.243;end   %%% conversion factor to go between
%%% pixels and mm.  Default: 42.43 pix= 1 cm


%%% Ask user to pick files
[file,path] = uigetfile('*.mat','MultiSelect','on');

n_groups=size(file,2);

%if a single file is loaded, adjust parameters
if (iscell(file)==0) && isempty(file)==0
    n_groups=1; file=cellstr(file);
end

%%% Show user what file path was picked, in case wrong one was selected!
fprintf('File Pathname: %s\n',path)

%%%% create name of the output Excel workbook. Names of individual sheets
%%%% are created inside for-loop below
[~,~,ext] = fileparts(file{1});
fname=erase(file{1},ext);
outfilename=[fullfile(path,fname),'.xlsx'];

% define 'customXlabels', used to label boxplots
customXlabels=group;
if isempty(customXlabels)|| size(customXlabels,2)~=n_groups
    customXlabels=num2cell(1:n_groups);
end

%%%%% for-loop calculates metrics and saves them in worksheets for each
%%%%% trial of the given genotype
climbtime=[];climbing=[];  %%% initialize variables

colnames={'NormRMSE', 'Movement direction', 'Speed(mm/s)', 'Time(s)', 'Percent@Max', ...
    'Percent@HalfofMax', 'Percent@ThirdofMax'};  %%% column names in saved worksheets

%%% initialize min/max angles, speeds to be displayed in boxplots
maxangle=5; minangle=-5; maxspeed=10; minspeed=0;

%%% Defining unusually large frame-to-frame movements as 100 mm/s or more.
%%% Under the default framerate of 30 Hz and default pixel-to-mm coversion
%%% of 4.243 pixels=1mm, move_too_big=3.3 mm/frame=14.1 pixels/frame
move_too_big=100*distTOpixel/framerate;

%%% Defining "falls" and "slips"---vertical drops while flies are walking,
%%% due to them losing traction. Working definitions for fall and slip are
%%% delta y>50 pixels and 20<delta y<50 pixels, respectively, within two
%%% consecutive frames. Below they are defined:
fall_Npixels=11.79*distTOpixel;   %greater than
slips_Npixels=4.72*distTOpixel;   %greater than and less than falls_nooframes

movdirect=[]; speeds=[]; Rsq=[]; Climbrates=[];  %%%initialize outputs
mistrial=0; %% number of skipped trial data sets

for q=1:n_groups
    
    filename=fullfile(path,file{q});
    fprintf('File name: %s\n',file{q})  %% print each file name being read
    matinput=cell2mat(struct2cell(load(filename)));

    datastr.Group(q).Names=customXlabels{q};

    moveon=0;  % if this is any number other than zero, the input data file/location matrix is skipped

    if isempty(matinput(:,~all(isnan(matinput)))) || ~isnumeric(matinput)
        fprintf('***Warning: Invalid position data in file %g. Moving to next input data.***\n',q)
        moveon=1; mistrial=mistrial+1;
    end

    if rem(size(matinput,2),2)~=0
        fprintf('***Warning: Location data in file %g must have even number of columns.*** \n',q);
        fprintf('Moving on to next group. \n');
        moveon=1; mistrial=mistrial+1;
    end

    if moveon>0
        datastr.Group(q).Fly_no.SpdAngle=NaN;
        datastr.Group(q).Fly_no.NRMSE=NaN;
        datastr.Group(q).Fly_no.AveSpeed=NaN;
        datastr.Group(q).Fly_no.Slips=NaN;
        datastr.Group(q).Fly_no.Falls=NaN;
        continue
    end


    [spds, movdir, LinRsq, climbs]=Geotaxis_stats_single(matinput,distTOpixel,framerate,maxYpixel);

    %%% look at all the output arrays of Geotaxis_stats and determine the
    %%% max number of rows found.
    maxrows=max(max(size(movdir,1),size(spds,1)),max(size(LinRsq,1),size(climbs,1)));

    %%update max/min angle, speed,  to be displayed on box plots
    maxangle=max(max(movdir,[],'all'),maxangle);
    minangle=min(min(movdir,[],'all'),minangle);
    maxspeed=max(max(spds,[],'all'),maxspeed);
    minspeed=min(min(spds,[],'all'),minspeed);

    %%%% Adjust each new array size so that they all have same number of
    %%%% rows. They are going to be written to a single spreadsheet
    movdir=[movdir; NaN(maxrows-size(movdir,1),size(movdir,2))];
    spds=[spds; NaN(maxrows-size(spds,1),size(spds,2))];
    LinRsq=[LinRsq; NaN(maxrows-size(LinRsq,1),size(LinRsq,2))];
    climbs=[climbs; NaN(maxrows-size(climbs,1),size(climbs,2))];

    %%%%% Appending new group results as new columns, to be used for
    %%%%% plotting and saving as output. ["Assuming every trial yielded
    %%%%% same number of outputs, otherwise the concatenation will fail.
    %%%%% So, this is a potential bug." FIXED ON 3/21/2024]
    movdirect=[movdirect, movdir];
    speeds=[speeds, spds];
    Rsq=[Rsq, LinRsq];
    Climbrates=[Climbrates, climbs];

    %%% Add climbing curve data of current group of flies to output structure
    datastr.Group(q).ClimbCurves=[climbs(:,1), climbs(:,2),...
        climbs(:,3), climbs(:,4)];

    %%% Write data to Excel file
    metrictable=table(LinRsq, movdir, spds, climbs(:,1), climbs(:,2),...
        climbs(:,3), climbs(:,4), 'VariableNames', colnames);
    [~,~,ext] = fileparts(file{q});
    sheetname=erase(file{q},ext);

    writetable(metrictable,outfilename,'Sheet',sheetname);

    %%%% this array will be used for plotting purposes only. it separates
    %%%% out each column of the time points and the 3 columns of climbing
    %%%% rates returned in 'climbs' from Geotaxis_stats.
    climbtime=[climbtime,climbs(:,1)];
    climbing=[climbing, climbs(:,2:end)];

end


%%%%% Plot the data.

subplot(2,3,1)
boxplot(movdirect,'Symbol', 'v', 'PlotStyle','compact','Labels',customXlabels(1:q));
ylim([minangle-3,maxangle+3]);
hold on

subplot(2,3,2)
boxplot(Rsq,'Symbol', 'x', 'PlotStyle','compact','Labels',customXlabels(1:q));
hold on


subplot(2,3,3)
boxplot(speeds,'Symbol', 'o', 'PlotStyle','compact','Labels',customXlabels(1:q));
hold on


subplot(2,3,4); %%% plot showing climbing to max height
h1=stairs(climbtime,climbing(:,1:3:end),'linewidth',1);
hold on

subplot(2,3,5)  %%% plot climbing to half of max height
h2=stairs(climbtime,climbing(:,2:3:end),'linewidth',1);
hold on

subplot(2,3,6)  %%% plot climbing to one-third of max height
h3=stairs(climbtime,climbing(:,3:3:end),'linewidth',1);
hold on




%%%% Individual plots done. Now, save all metrics to a final spreadsheet in
%%%% the same workbook where the individual trials have been saved. For the
%%%% climbing rates, the average rates are saved.

movdirect(isnan(movdirect))=[]; movdirect=movdirect(:);
speeds(isnan(speeds))=[]; speeds=speeds(:);
Rsq(isnan(Rsq))=[]; Rsq=Rsq(:);
%%%%% average columns of each array and put the averaged quants together
climbtime=mean(climbtime,2);
maxheightrate=mean(climbing(:,1:3:end),2);
halfmaxrate=mean(climbing(:,2:3:end),2);
thirdmaxrate=mean(climbing(:,3:3:end),2);
Climbrates=[climbtime, maxheightrate, halfmaxrate, thirdmaxrate];

%%% determine which array has the most number of rows and then
%%%% adjust each array size so that they all have same number of rows.
maxrows=max(max(size(movdirect,1),size(speeds,1)),max(size(Rsq,1),size(Climbrates,1)));

movdirect=[movdirect; NaN(maxrows-size(movdirect,1),size(movdirect,2))];
speeds=[speeds; NaN(maxrows-size(speeds,1),size(speeds,2))];
Rsq=[Rsq; NaN(maxrows-size(Rsq,1),size(Rsq,2))];
Climbrates=[Climbrates; NaN(maxrows-size(Climbrates,1),size(Climbrates,2))];


colnames={'NormRMSE', 'Movement direction', 'Speed(mm/s)', 'Time(s)', 'Ave Frac@Max', ...
    'Ave Frac@HalfofMax', 'Ave Frac@ThirdofMax'};

%%%% Finally, write the combined data to last worksheet in .xlsx file
metrictable=table(Rsq, movdirect, speeds,...
    Climbrates(:,1),Climbrates(:,2),Climbrates(:,3), Climbrates(:,4), ...
    'VariableNames', colnames);
writetable(metrictable,outfilename,'Sheet','allTrials');


%%%% Finally, adjust axis limits, put titles on the subplots, and add
%%%% average metrics to existing plots, as  appropriate


subplot(2,3,1)
ylim([minangle-3,maxangle+3]);
title('movement direct(-90:+90)')


subplot(2,3,2)
%ylim([-1.1,1.1]);
title('Linfit RMSE')

subplot(2,3,3)
ylim([minspeed-1,maxspeed+1]);
title('speed (mm/s)')

subplot(2,3,4)
stairs(climbtime,maxheightrate,'linewidth',2, 'Color',[0,0,0]);
ylim([-1,105]);
legendtext=group;  %%% determine climbing rate figure legend
if isempty(legendtext)|| size(legendtext,2)~=n_groups
    legendtext=sprintfc('gentype%d',1:n_groups);
end
legend(legendtext,'Location','best','NumColumns',2)
title('max height')
xlabel('Time(sec)')
ylabel('Percent of flies')

subplot(2,3,5)
stairs(climbtime,halfmaxrate,'linewidth',2, 'Color',[0,0,0]);
ylim([-1,105]);
title('max/2 height')

subplot(2,3,6)
stairs(climbtime,thirdmaxrate,'linewidth',2, 'Color',[0,0,0]);
ylim([-1,105]);
title('max/3 height')


ColorSet=varycolor(n_groups-mistrial);   %%% give specific colors to staircase lines
set(h1, {'Color'}, mat2cell(ColorSet,ones(n_groups-mistrial,1),3));
set(h2, {'Color'}, mat2cell(ColorSet,ones(n_groups-mistrial,1),3));
set(h3, {'Color'}, mat2cell(ColorSet,ones(n_groups-mistrial,1),3));


    function [speeds, movdirection, wRMSE, Max_Half_Thirdclimbs] = ...
            Geotaxis_stats_single(locmatrix,disTOpix,framerate,maxYpixel)

        %%%%%% Function written to quantify geotactic behavior of flies.
        %%%%%% This function takes in a 2D numerical array "locmatrix" with
        %%%%%% x and y positions of flies (2 columns per fly) and
        %%%%%% calculates a few metrics to quantify fly movements. So, if
        %%%%%% there are 5 flies in the input then there should be 10
        %%%%%% columns. Each row is a different time point, with time
        %%%%%% increasing with row number.


        %%% Similar to "Geotaxis_stats", Written by Sheyum in December
        %%% 2021.


        %%% take out columns that have all NaN
        positions=locmatrix(:,~all(isnan(locmatrix)));

        n_flies=size(positions,2)/2;  %%% number of flies
        positions(positions<=0)=0;  %%% if somehow negative numbers crept in

        %%% calculate maximum y-pixel (height), if not provided. NOTE: to
        %%% calculate the max height, we calculate the 'min' because of the
        %%% way the pixels are numbered: (0,0) is top left of the frame
        ypixels=positions(:,2:2:end);

        if isempty(maxYpixel), maxYpixel=min(min(ypixels)); end

        %%%% typical length of fly (~ 3.5 mm) in pixel#s
        flybodylength=disTOpix*3.5;
        maxYpixel=maxYpixel+1*flybodylength; %%% give a little flexiblity to max height to reach
        minYpixel=max(max(ypixels))-maxYpixel;

        % Used inside indiv fly loop below. This global max should be the
        % bottom of a vial. Not calculating this individually since not all
        % flies are first located at the bottom of their vial. Hopefully,
        % there is at least one that is tracked all the way from the bottom!
        lowestYpixel=max(max(ypixels));

        %%% define a height above which metrics like 'move direction',
        %%% 'speed', 'R^2' are NOT to be calculated.
        ycensor=max(10,maxYpixel); %% the '10' indicates y pixel value
        % for the bottom of the vial's cap. The cap distorts movement.

        %%%initialize new arrays for use in the following for loop
        speeds=NaN(n_flies,1);
        wRMSE=NaN(n_flies,1);
        movdirection=NaN(n_flies,1); 
        Maxrows=zeros(n_flies,1); HalfMaxrows=zeros(n_flies,1); ThirdMaxrows=zeros(n_flies,1);

        j=1;  %%% starting fly x-column number.
        %%% This is incremented by 2 for every iteration of the forloop
        %%% below to go to next x-column.

        %%%For every fly, calculate center of mass displacement of each
        %%%fly. Also determine first instances of when flies cross the max
        %%%height,
        %%% 1/2 max height and 1/3 max height

        for i=1:n_flies

            % fprintf('Fly # %g\n',i)

            %%% fill Maxrows with detected rows. If none detected,
            %%% Maxrows(i)=0
            [rows,~]=find(ypixels(:,i)<=maxYpixel,1,'first');
            if ~isempty(rows)
                Maxrows(i)=rows;
            end

            % this is temporary... 10 cm mark
            % [rows,~]=find(ypixels(:,i)<minYpixel*3/10,1,'first'); if
            % ~isempty(rows)
            %     HalfMaxrows(i)=rows;
            % end

            %%% same with HalfMaxrows  and ThirdMaxrows
            [rows,~]=find(ypixels(:,i)<minYpixel/2,1,'first');
            if ~isempty(rows)
                HalfMaxrows(i)=rows;
            end
            [rows,~]=find(ypixels(:,i)<(minYpixel/3)*2,1,'first');
            if ~isempty(rows)
                ThirdMaxrows(i)=rows;
            end


            x=positions(:,j); y=positions(:,j+1);

            %%% remove coordinates above censored y pixel. This is
            %%% important because close to the top of the vial, fly
            %%% movement is restricted.
            x(y<ycensor)=NaN; y(y<ycensor)=NaN;


            %%% change the origin of the coordinate system from top left to
            %%% bottom left corner
            xnew=x; ynew=-(y-lowestYpixel);



            %%% find the slips and falls, defined near the top of main
            %%% function. Information is saved in structure. The
            %%% "sliparray" or "fallarray" has three columns: time (in sec)
            %%% of event, y location (in mm) of event and size (in mm) of
            %%% event.
            sliparray=[]; fallarray=[];
            [sliparray,fallarray]=find_slips_falls(ynew,slips_Npixels,fall_Npixels);

            % finally, fill in the structure fields with slips and fallss
            datastr.Group(q).Fly_no(i).Slips=NaN(1,3);
            datastr.Group(q).Fly_no(i).Falls=NaN(1,3);

            if ~isempty(sliparray(:,1))
                datastr.Group(q).Fly_no(i).Slips=[sliparray(:,1)./framerate,...
                    sliparray(:,2:3)./disTOpix];
            end
            if ~isempty(fallarray(:,1))
                datastr.Group(q).Fly_no(i).Falls=[fallarray(:,1)./framerate,...
                    fallarray(:,2:3)./disTOpix];
            end


            % find the frame-frame angle (w.r.t horizontal) and speed of
            % movement. Also the average angle and average speed of
            % movement  for this fly.
            [ang,spdss,avspeed]=find_moveangle_speed([xnew(:),ynew(:)],move_too_big);
            datastr.Group(q).Fly_no(i).SpdAngle=[spdss,ang];% store frame-frame data in structure
            movdirection(i)=mean(ang, 'omitnan');  % average angle

            datastr.Group(q).Fly_no(i).AveSpeed=NaN;
            speeds(i)=avspeed; % average speed
            datastr.Group(q).Fly_no(i).AveSpeed=avspeed;



            %%% fit walking trajectory to a straight line and note measure
            %%% of deviation from a linear trajectory, the normalized RMSE.
            datastr.Group(q).Fly_no(i).NRMSE=NaN;

            norm_RMSE=fit_line([xnew(:),ynew(:)],move_too_big);
            datastr.Group(q).Fly_no(i).NRMSE=norm_RMSE;
            wRMSE(i)=mean(norm_RMSE,'omitnan');


            %%% calculate mean sq. displacement in x and y, separately.
            %%% First column of returned array contains time. Second and
            %%% third columns contain MSD in x and MSD in y directions.
            %%% As of March 2024, MSD data are not saved in output
            %%% structure.
            MSDxy= MSD([xnew(:),ynew(:)]);

            % All calculations done with this fly
            j=j+2; %% increment position column counter!

        end      %%%% end of fly loops


        %%%% Calculate empirical CDFs for time taken to reach max height,
        %%%% 1/2 max and 1/3 max

        trow=(1:size(locmatrix,1))';

        frac=zeros(numel(trow),1);
        nozeros=sort(Maxrows(Maxrows~=0));
        nozeros=nozeros(:)';
        if ~isempty(nozeros)
            [N,~]=histcounts(nozeros,[unique(nozeros),max(nozeros)+1]);
            frac(unique(nozeros))=N;
        end
        MaxYclimb=100*cumsum(frac)./n_flies;


        %%%% 1/2 of max height climb
        frac=zeros(numel(trow),1);
        nozeros=sort(HalfMaxrows(HalfMaxrows~=0));
        nozeros=nozeros(:)';
        if ~isempty(nozeros)
            [N,~]=histcounts(nozeros,[unique(nozeros),max(nozeros)+1]);
            frac(unique(nozeros))=N;
        end
        HalfmaxYclimb=100*cumsum(frac)./n_flies;



        %%%% 1/3 of max height climb
        frac=zeros(numel(trow),1);
        nozeros=sort(ThirdMaxrows(ThirdMaxrows~=0));
        nozeros=nozeros(:)';
        if ~isempty(nozeros)
            [N,~]=histcounts(nozeros,[unique(nozeros),max(nozeros)+1]);
            frac(unique(nozeros))=N;
        end
        ThirdmaxYclimb=100*cumsum(frac)./n_flies;


        %%%%%% save output variable
        Max_Half_Thirdclimbs=[trow./framerate,MaxYclimb,HalfmaxYclimb,ThirdmaxYclimb];

    end

    function MSDxy= MSD(locs)

        MSDxy=[NaN, NaN, NaN];
        xpos=locs(~isnan(locs(:,1)),1); x0=xpos(1);
        ypos=locs(~isnan(locs(:,1)),2); y0=ypos(1);
        timepoints=[0:sum(~isnan(locs(:,1)))-1]./framerate;

        MSDxy=[timepoints', (xpos-x0).^2, (ypos-y0).^2];

        % figure(2) subplot(2,2,[1,3]) plot(xpos, ypos,'r--o')
        % xlabel('Pixel position in X') ylabel('Pixel position in Y')
        % subplot(2,2,2) scatter(MSDxy(:,1), MSDxy(:,2)) ylabel('MSD in
        % x-direction') set(gca,'XTickLabel',[]) subplot(2,2,4)
        % scatter(MSDxy(:,1), MSDxy(:,3)) ylabel('MSD in y-direction')
        % xlabel('Time (seconds)')

    end

    function T_RMSE = fit_line(locs,toobig)
        if isempty(toobig), toobig=100*distTOpixel/framerate; end
        % calculate Euclidean distances between frames
        c=[0;sqrt(sum(diff(locs).^2,2))];
        c(c>=toobig)=NaN; % define big jumps as new NaNs
        % construct vector containing row#s that mark beginning/end of
        % non-jumpy movements. Adjust vector elements in if/then for easy
        % use in for loop.

        secoff=[0;find(isnan(c))]; % find all NaN rows
        if secoff(end)<length(locs(:,1))
            secoff=[secoff; length(locs)];
        end

        T_RMSE=NaN(length(secoff)-1,1); % initialize
        for k=1:length(secoff)-1
            a=locs(secoff(k)+1:secoff(k+1)-1,:);
            d=sum(sqrt(sum(diff(a).^2,2)));

            if length(a(~isnan(a(:,1)),1))<2 || d==0
                continue  %% skip if fewer than two locations, all NaN, or
            end           %%% no movement

            % ready to do fit. Assume movement mostly in x-direction
            xdata=a(:,1); ydata=a(:,2); normfactor=-(max(xdata)-min(xdata));%std(xdata);
            if std(ydata)>std(xdata)  % flip x-y and normalization factor
                % if movement mostly in y
                xdata=a(:,2); ydata=a(:,1); normfactor=max(xdata)-min(xdata);%std(xdata);
            end
            linfitmodel = fitlm(xdata,ydata);  % fitlm ignores 'nan'

            %%% record root mean sq. of error in fit and normalize with std
            %%% of x or y data. If the fly moved mostly in the x direction,
            %%% T_RMSE is negative but if fly moved mostly in y direction
            %%% then T_RMSE is positive.
            T_RMSE(k)=(linfitmodel.RMSE)/normfactor;
        end
    end %%% end of 'fit_line'

    function [slips,falls]=find_slips_falls(ydata,slNpixels,flNpixels)

        %%% The function returns info on slips and falls for a fly. Sheyum
        %%% October 2023.


        Dy=diff(ydata);
        [slindx]=find(slNpixels<=-Dy & -Dy<flNpixels);
        [faindx]=find(-Dy>=flNpixels);
        slips=[slindx,ydata(slindx),-Dy(slindx)];
        if isempty(slips)
            slips=NaN(1,3);
        end

        falls=[faindx, ydata(faindx),-Dy(faindx)];
        if isempty(falls)
            falls=NaN(1,3);
        end

        %%% if a fly is free-falling in successive frames, these can appear
        %%% as smaller "slides" (in terms of size) though in reality they
        %%% were a "fall" in progress. Below, such slides are checked if
        %%% they add up to a fall and then saved as such.
        Slstarts=find(diff(diff([0;slips(:,1);0])==1)==1,1);
        Slends=find(diff(diff([0;slips(:,1);0])==1)==-1,1);
        nloops=length(Slstarts);
        if nloops~=0
            for n=1:nloops
                slips(Slstarts(n),3)=sum(slips(Slstarts(n):Slends(n),3));
                slips(Slstarts(n)+1:Slends(n),:)=NaN(Slends(n)-Slstarts(n),3);
            end
        end
        % by consolidating consecutive slips, did we end up with a slip
        % that now qualifies as a fall? Move such large slips to fall
        % array.
        moverows=find(slips(:,3)>=flNpixels);
        if ~isempty(moverows)
            falls=[falls; slips(moverows,:)];
            slips(moverows,:)=NaN(length(moverows),3);
            [~,soindx]=sort(falls(:,1),'ascend');
            falls=falls(soindx,:);
        end
        slips=slips(~isnan(slips(:,1)),:); %remove nan rows

        %%% apparently, such "free-fall" is more common among the falling
        %%% events. Below, successive falls are collapsed into single a
        %%% fall of larger size, since successive falls are quite likely
        %%% just fly free-falling.

        % start and end of successive fall frames
        Fstarts=find(diff(diff([0;falls(:,1);0])==1)==1,1);
        Fends=find(diff(diff([0;falls(:,1);0])==1)==-1,1);
        nloops=length(Fstarts);
        if nloops~=0
            for n=1:nloops
                falls(Fstarts(n),3)=sum(falls(Fstarts(n):Fends(n),3));
                falls(Fstarts(n)+1:Fends(n),:)=NaN(Fends(n)-Fstarts(n),3);
            end
        end
        falls=falls(~isnan(falls(:,1)),:); %remove nan rows

    end %%% end of find_slips_falls


    
    function [thetas, speeeds, avspd] = find_moveangle_speed(xylocations,toobig)
        %%% This function takes in an array of x,y coordinates and
        %%% calculates angular displacements (in degrees, -90 to +90) with
        %%% respect to the horizontal. The input is assumed to have two
        %%% columns, first column are x coordinates and secodn column
        %%% contain y coordinates

        %%% Sheyum. January 2023. June 2023. Modified September 2023.

        %% example
        %%% r=[1,1; 0.7,2; 0.7,4; 2,4; 2.5,5; 3.5, 4.5; 2.9, 4; 2.9, 1.5;
        %%% 1, 1.5]; plot(r(:,1),r(:,2), 'o-') [thetas, speeeds]
        %%% =find_move_angle(r)
        thetas=NaN; speeeds=NaN; avspd=NaN;

        if isempty(toobig), toobig=100*distTOpixel/framerate;end  

        first_found_height=5; % height (in mm) from vial bottom where fly is first located.
        % This is about two body lengths. If a fly is *first* located at
        % this height or lower after a string of NaNs (couldn't be located)
        % then re-evaluate average speed

        dr=diff(xylocations);  % calculate displacements in x and y directions

        dis=sqrt(sum(dr.^2,2)); % calculate Euclidean distance
        dr(dis>toobig,:)=NaN; %NaN those deltaX and deltaY that produce large Euclidean displacement
        dis(dis>toobig)=NaN; %turn into NaN overly large Euclidean displacements


        %%% instantaneous or frame-frame speeds in mm/sec
        speeeds=dis.*framerate./distTOpixel;
        

        %%% average speed
        avspd=mean(speeeds,'omitnan');  % average speed

        %%% ALternative calculation of average speed, applicable for a fly
        %%% that was sitting at the bottom and so could not be tracked.
        % Calculate average speed for this fly. Not doing a simple
        %mean(speeeds) because the "speeeds" instantaneous speeds are
        %calculated after ignoring NaNs, particularly NaNs during the first
        %few frames. These initial NaNs result from failed tracking because
        %the fly was sitting still at the bottom.
        lastnanrow=find(~isnan(xylocations(:,2)),1,'first')-1;
        firstlocat=xylocations(max(1,lastnanrow+1),2); % first non-NaN y pixel location


        if (lastnanrow>2) && (firstlocat < first_found_height*distTOpixel)
            losttime=numel(xylocations(1:lastnanrow,2));  %%% number of rows of NaN
            totaldistance=sum(dis,'omitnan')/distTOpixel;
            totaltime=(numel(dis(~isnan(dis)))+losttime)/framerate;
            avspd=totaldistance/totaltime;  % new average speed
        end

        %%% Finally, calculate angle of movement, in theta, with respect to
        %%% horizontal

        dr(:,1)=abs(dr(:,1));  %%%% this makes sure there is no difference in
        %%% left turn vs right turn angle. We only care whether movement is
        %%% 'upward' or 'downward' or 'horizontal' and not whether it is
        %%% 'right' or 'left'. Theta in degrees.
        thetas=atand(dr(:,2)./dr(:,1));

    end  %%% end of 'find_moveangle_speed'

    function ColorSet=varycolor(NumberOfPlots)
        % VARYCOLOR Produces colors with maximum variation on plots with
        % multiple lines.
        %
        %     VARYCOLOR(X) returns a matrix of dimension X by 3.  The
        %     matrix may be used in conjunction with the plot command
        %     option 'color' to vary the color of lines.
        %
        %     Yellow and White colors were not used because of their poor
        %     translation to presentations.
        %
        %     Example Usage:
        %         NumberOfPlots=50;
        %
        %         ColorSet=varycolor(NumberOfPlots);
        %
        %         figure hold on;
        %
        %         for m=1:NumberOfPlots
        %             plot(ones(20,1)*m,'Color',ColorSet(m,:))
        %         end

        %Created by Daniel Helmick 8/12/2008

        error(nargchk(1,1,nargin))%correct number of input arguements??
        error(nargoutchk(0, 1, nargout))%correct number of output arguements??

        %Take care of the anomolies
        if NumberOfPlots<1
            ColorSet=[];
        elseif NumberOfPlots==1
            ColorSet=[0 1 0];
        elseif NumberOfPlots==2
            ColorSet=[0 1 0; 0 1 1];
        elseif NumberOfPlots==3
            ColorSet=[0 1 0; 0 1 1; 0 0 1];
        elseif NumberOfPlots==4
            ColorSet=[0 1 0; 0 1 1; 0 0 1; 1 0 1];
        elseif NumberOfPlots==5
            ColorSet=[0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0];
        elseif NumberOfPlots==6
            ColorSet=[0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0; 0 0 0];

        else %default and where this function has an actual advantage

            %we have 5 segments to distribute the plots
            EachSec=floor(NumberOfPlots/5);

            %how many extra lines are there?
            ExtraPlots=mod(NumberOfPlots,5);

            %initialize our vector
            ColorSet=zeros(NumberOfPlots,3);

            %This is to deal with the extra plots that don't fit nicely
            %into the segments
            Adjust=zeros(1,5);
            for m=1:ExtraPlots
                Adjust(m)=1;
            end

            SecOne   =EachSec+Adjust(1);
            SecTwo   =EachSec+Adjust(2);
            SecThree =EachSec+Adjust(3);
            SecFour  =EachSec+Adjust(4);
            SecFive  =EachSec;

            for m=1:SecOne
                ColorSet(m,:)=[0 1 (m-1)/(SecOne-1)];
            end

            for m=1:SecTwo
                ColorSet(m+SecOne,:)=[0 (SecTwo-m)/(SecTwo) 1];
            end

            for m=1:SecThree
                ColorSet(m+SecOne+SecTwo,:)=[(m)/(SecThree) 0 1];
            end

            for m=1:SecFour
                ColorSet(m+SecOne+SecTwo+SecThree,:)=[1 0 (SecFour-m)/(SecFour)];
            end

            for m=1:SecFive
                ColorSet(m+SecOne+SecTwo+SecThree+SecFour,:)=[(SecFive-m)/(SecFive) 0 0];
            end

        end

    end

end
