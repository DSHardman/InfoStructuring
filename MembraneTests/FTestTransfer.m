% Transfer plots from Figure 4

%% Setup
load("Data/Recordings2D.mat");
load("Data/rankings.mat");

%% Perform Transfer

% Plot insulatedpress using conductivetouch's top 50 F-Test configurations
% Input objects can be changed to generate different transfer plots 
figure();
transferFTest({conductivetouch insulatedpress}, ftest, 50);
axis equal

%%

function transferFTest(s, ranking, n)

    % Ranking of configurations, rather than separately treating RMS &
    % phase channels
    ranking = mod(ranking(1:n)-1, 1679)+1;

    % Use first n rankings to get conductivetouch's PCA coefficients
    allevents = s{1,1}.rms10k;
    [coeff, ~, ~, ~, ~, mu] = pca(allevents(:, ranking));
        
    my_colors;
    scatter(nan, nan, 30, "k", "filled");
    hold on

    % Map insulatedpress into 2D using these coefficients
    for i=2:length(s)
        allevents = [allevents;(s{1,i}.rms10k)];
    end
    Y = (allevents(:, ranking)-mu)*coeff(:,1:2);
    
    % Plot insulatedpress, coloring based on known timings of each event
    j = size((s{1, 1}.rms10k),1);
    for i=2:length(s)
        pcaevents(Y, s{1, i}, j, colors(i,:));
        j = j + size((s{1, i}.rms10k),1);
        hold on
    end
    set(gcf, "color", "w");
    xlabel("PCA 1");
    ylabel("PCA 2");
    set(gca, 'linewidth', 2, 'fontsize', 18);
    box off
    axis square
    set(gca,'XColor','k','YColor','k');
end

function pcaevents(Y, recordingobject, startingindex, col)

    % If no events are defined, plot path over time then exit
    if isempty(recordingobject.eventboundaries)
        plot(Y(startingindex+1:startingindex+size(recordingobject.rms10k, 1), 1),...
            Y(startingindex+1:startingindex+size(recordingobject.rms10k, 1), 2),...
            "Color", col, "linewidth", 2);
        
        % scatter(Y(startingindex+1, 1), Y(startingindex+1, 2), 20, col, "filled"); % blob at start
        return
    end

    my_colors;
    start = startingindex+1;
    for i = 1:size(recordingobject.eventboundaries, 1)
        % Black scatter those before each event
        scatter(Y(start:startingindex+recordingobject.eventboundaries(i,1)-5, 1),...
            Y(start:startingindex+recordingobject.eventboundaries(i,1)-5, 2),...
            50, "k", "filled");

        % Scatter each event with a different marker in the color defined
        scatter(Y(startingindex+recordingobject.eventboundaries(i,1)+2:...
            startingindex+recordingobject.eventboundaries(i,2)-2, 1),...
            Y(startingindex+recordingobject.eventboundaries(i,1)+2:...
            startingindex+recordingobject.eventboundaries(i,2)-2, 2),...
            50, colors(i,:), "filled");

        % Add text labels offset from cluster centroid
        xloc = mean(Y(startingindex+recordingobject.eventboundaries(i,1):...
            startingindex+recordingobject.eventboundaries(i,2), 1));
        yloc = mean(Y(startingindex+recordingobject.eventboundaries(i,1):...
            startingindex+recordingobject.eventboundaries(i,2), 2));
        text(xloc+0.002, yloc, recordingobject.eventlabels(i), "color", colors(i,:));

        start = startingindex + recordingobject.eventboundaries(i,2) + 5;
    end

    % Black scatter those after the final event
    scatter(Y(start:startingindex+size(recordingobject.rms10k, 1), 1),...
        Y(start:startingindex+size(recordingobject.rms10k, 1), 2),...
            50, "k", "filled");

end