function plotFlySpeedByFlyFalls(flies)
%From the structure output from Geotaxis_genotypecompare_V5 extract speed,
%slipes, and falls. Average the speed and use it as the x coordinate for
%each fly. Count the number of slips and falls and on two seperate graphs
%use that number for the y coordinate. Each track will corispond to a dot
%on the graph. 

    %for each genotype
    for q=1:size(flies.Genotype,2)
        speedToSlipsandFalls=zeros(size(flies.Genotype(q).Fly_no,2),3);
        %for each fly in the genotype
        for i=1:size(flies.Genotype(q).Fly_no,2)
            %find the average speed of the fly
            avgSpeed=sum(flies.Genotype(q).Fly_no(i).SpdAngle(:,2),'omitnan')/size(flies.Genotype(q).Fly_no(i).SpdAngle(:,2),1);
            
            %find the number of slips for that fly. If none, set to 0
            if isnan(flies.Genotype(q).Fly_no(i).Slips)
                numSlips=0;
            else
                numSlips=size(flies.Genotype(q).Fly_no(i).Slips,1);
            end

            %find the number of falls for that fly. If none, set to 0
            if isnan(flies.Genotype(q).Fly_no(i).Falls)
                numFalls=0;
            else
                numFalls=size(flies.Genotype(q).Fly_no(i).Falls,1);
            end
            
            % create a matrix to hold the information for all the flies in
            % the genotype 
            speedToSlipsandFalls(i,:)=[avgSpeed,numSlips,numFalls];
        end
        %plot the number of slips first in blue
        figure;
        scatter(speedToSlipsandFalls(:,1),speedToSlipsandFalls(:,2),"*","blue");
        ylabel("Number of Slips")
        xlabel("Average Fly Speed (mm/s)")
        title("Slips")

        %plot the number of falls second in red
        figure;
        scatter(speedToSlipsandFalls(:,1),speedToSlipsandFalls(:,3),"*","red");
        ylabel("Number of Falls")
        xlabel("Average Fly Speed (mm/s)")
        title("Falls")
    end
end


