function [slipSpeed, fallSpeed]=plotFiveFrameSpeedSlipsFalls(flies)
%From the structure output from Geotaxis_genotypecompare_V5 extract speed,
%slipes, and falls. Average the speed and use it as the x coordinate for
%each fly. Count the number of slips and falls and on two seperate graphs
%use that number for the y coordinate. Each track will corispond to a dot
%on the graph. 

frameRate=30; %all our experiments are recorded at 30Hz so the time in seconds corresponds to time * 30. 
nbins=15;%number of desired bins

    %for each genotype
    for q=1:size(flies.Genotype,2)
        fallSpeed=[];
        slipSpeed=[];
        %for each fly in the genotype
        for i=1:size(flies.Genotype(q).Fly_no,2)

            %find the number of slips for that fly. If none, set to 0
            if ~isnan(flies.Genotype(q).Fly_no(i).Slips)
                timeOfSlips=flies.Genotype(q).Fly_no(i).Slips(:,1)*frameRate;
                for jj=1:size(timeOfSlips,1)
                    %find the average speed of 5 frames preceeding event
                    %if the event does not have 5 frames of speed, use all
                    %speed information that applies UP TO 5 frames for
                    %average. 
                    if timeOfSlips(jj)>5
                        slipSpeed(end+1,1)=mean(flies.Genotype(q).Fly_no(i).SpdAngle(timeOfSlips(jj,1)-5:timeOfSlips(jj,1)-1,2),"omitnan");
                    else
                        slipSpeed(end+1,1)=mean(flies.Genotype(q).Fly_no(i).SpdAngle(1:timeOfSlips(jj,1)-1,2),"omitnan");
                    end
                    slipSpeed(end,2)=i;
                end
            end

            %find the number of falls for that fly. If none, set to 0
            if ~isnan(flies.Genotype(q).Fly_no(i).Falls)
                timeOfFalls=flies.Genotype(q).Fly_no(i).Falls(:,1)*frameRate;
                for jj=1:size(timeOfFalls,1)
                     %find the average speed of 5 frames preceeding event
                    %if the event does not have 5 frames of speed, use all
                    %speed information that applies UP TO 5 frames for
                    %average. 
                    if timeOfFalls(jj)>6
                        fallSpeed(end+1,1)=mean(flies.Genotype(q).Fly_no(i).SpdAngle(timeOfFalls(jj,1)-5:timeOfFalls(jj,1)-1,2),"omitnan");
                    else
                        fallSpeed(end+1,1)=mean(flies.Genotype(q).Fly_no(i).SpdAngle(1:timeOfFalls(jj,1)-1,2),"omitnan");
                    end
                    fallSpeed(end,2)=i;
                end
            end
        end

        %plot the number of slips first in blue
        figure;
        histogram(slipSpeed(:,1),nbins,"FaceColor","blue");
        ylabel("Number of Slip Instances")
        xlabel("Fly Speed 5 frames prior to event (mm/s)")
        title("Slips")

        %plot the number of falls second in red
        figure;
        histogram(fallSpeed(:,1),nbins,"FaceColor","red");
        ylabel("Number of Fall Instances")
        xlabel("Fly Speed 5 frames prior to event (mm/s)")
        title("Falls")
    end
end


