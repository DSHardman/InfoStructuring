% Figure 6 tactile localizations


%% Logistics: load in data for 1080 light touches
load("Data/ExtractedSingleTouches.mat"); % [x y side_boolean]

% Give back touch locations a negative y position
load("HandOutline.mat");
targetpositions(:, 2) = targetpositions(:, 2) - min(outline(:, 2));
outline(:,2) = outline(:,2)-min(outline(:,2));
idx = find(targetpositions(:,3) == 1);
targetpositions(idx, 2) = -targetpositions(idx, 2);

% Extract response magnitudes
responses = zeros([length(targetpositions), size(alldata, 2)]);
for i = 1:length(targetpositions)
    responses(i, :) = alldata(2*i, :) - alldata(2*i-1, :);
end

%% Perform F-Test ranking
ranking = franking(responses, targetpositions);

%% WAM localization using top N channels: plot 10 random predictions from test set
% Prediction in pink, ground truth in red
% Black shows prediction for other side, if this is predicted incorrectly
figure();
error = wamtesting(ranking(1:400), responses, targetpositions, 1);
sgtitle("Mean error over entire test set: "+ string(error) + " mm, ");

%% Plot sensitivity maps of top 10 configurations
figure();
for i = 1:10
    subplot(2,5,i);
    vals = abs(responses(:, ranking(i)));
    interpolant = scatteredInterpolant(targetpositions(:,1), targetpositions(:,2), vals);
    [xx,yy] = meshgrid(linspace(min(targetpositions(:,1)), max(targetpositions(:,1)),100),...
                        linspace(min(targetpositions(:,2)), max(targetpositions(:,2)),100));
    value_interp = interpolant(xx,yy); 
    value_interp = max(value_interp, 0); % Don't allow extrapolation below zero
    % Remove points from outside hand
    for k = 1:size(xx,1)
        for j = 1:size(xx,2)
            if ~inpolygon(xx(k,j),abs(yy(k,j)), outline(:,1), outline(:,2))
                value_interp(k,j) = nan;
            end
        end
    end
    contourf(xx,yy,value_interp, 100, 'LineStyle', 'none');
    axis off
    colormap hot
    title(string(i));
end
sgtitle("Sensitivity maps of top 10 configurations");


%% F-Test Ranking
function ranking = franking(responses, targetpositions)
    combs2_x= fsrftest(responses, targetpositions(:, 1)); % x direction
    combs2_y= fsrftest(responses, targetpositions(:, 2)); % y direction

    % Combine directions
    combinedweights = zeros(size(combs2_x));
    for i = 1:length(responses)
        combinedweights(i) = find(combs2_x==i)+find(combs2_y==i);
    end
    [~, ranking] = sort(combinedweights, "ascend");
end


%% Implement WAM method from Hardman et al., Tactile Perception in Hydrogel-based Robotic Skins, 2023
function error = wamtesting(combinations, responses, targetpositions, figs)
    load("HandOutline.mat");
    outline(:,2) = outline(:,2)-min(outline(:,2));

    responses = tanh(normalize(responses)); % Deal with outliers

    % % Generate test & train sets
    P = randperm(length(targetpositions));
    traininds = P(1:floor(0.9*length(targetpositions)));
    testinds = P(ceil(0.9*length(targetpositions)):end);
    testresponses = responses(testinds, :);
    testpositions = targetpositions(testinds, :);
    responses = responses(traininds, :);
    targetpositions = targetpositions(traininds, :);

    % WAM using training set to predict test set
    error = 0;
    % Loop through test set
    for i = 1:size(testresponses, 1)

        % Sum activation maps
        sum = zeros([size(responses, 1), 1]);
        for j = 1:length(combinations)
            newsum = testresponses(i, combinations(j))*responses(:, combinations(j));
            if isempty(find(isnan(newsum), 1))
                sum = sum + newsum;
            end
        end

        % Prediction is the average location of the n brightest pixels
        [~, ind] = sort(sum, 'descend');
        n = min(8, size(responses, 2));

        % Average over n brightest pixels on each side
        frontprediction = [0 0];
        backprediction = [0 0];
        frontcount = 0;
        frontsum = 0;
        backcount = 0;
        backsum = 0;
        k = 1;
        while 1
            if targetpositions(ind(k), 3) == 0 && frontcount < n
                frontprediction = frontprediction + targetpositions(ind(k), 1:2);
                frontcount = frontcount + 1;
                frontsum = frontsum + sum(ind(k));
            elseif targetpositions(ind(k), 3) == 1 && backcount < n
                backprediction = backprediction + targetpositions(ind(k), 1:2);
                backcount = backcount + 1;
                backsum = backsum + sum(ind(k));
            end
            k = k + 1;
            if frontcount == n && backcount == n
                break
            end

            % Deal with data from a single side
            if k > size(targetpositions, 1)
                break
            end
        end
        frontprediction = frontprediction./n;
        backprediction = backprediction./n;


        % Add localization error to running sum 
        error = error + min([rssq(abs(frontprediction)-abs(testpositions(i, 1:2))),...
            rssq(abs(backprediction)-abs(testpositions(i, 1:2)))]);

        % Plot prediction
        if figs && i <= 10
            subplot(2,5,i);

            vals = sum;
            interpolant = scatteredInterpolant(targetpositions(:,1), targetpositions(:,2), vals);
            [xx,yy] = meshgrid(linspace(min(targetpositions(:,1)), max(targetpositions(:,1)),100),...
                                linspace(min(targetpositions(:,2)), max(targetpositions(:,2)),100));
            value_interp = interpolant(xx,yy); 
            value_interp = max(value_interp, 0); % Don't allow extrapolation below zero

            % Remove points from outside hand
            for k = 1:size(xx,1)
                for j = 1:size(xx,2)
                    if ~inpolygon(xx(k,j),abs(yy(k,j)), outline(:,1), outline(:,2))
                        value_interp(k,j) = nan;
                    end
                end
            end
            contourf(xx,yy,value_interp, 100, 'LineStyle', 'none');
            
            hold on
            % Add ground truth and predicted touch locations
            scatter(testpositions(i, 1), testpositions(i, 2), 50, 'r', 'filled');

            if frontsum > backsum
                scatter(frontprediction(1), frontprediction(2), 50, 'm', 'filled');
                scatter(backprediction(1), backprediction(2), 30, 'k', 'filled');
            else
                scatter(backprediction(1), backprediction(2), 50, 'm', 'filled');
                scatter(frontprediction(1), frontprediction(2), 30, 'k', 'filled');
            end

            axis off
            set(gcf, 'color', 'w');

        end
    end
    error = error/size(testresponses, 1); % calculate mean
    error = error*3.32; % convert to mm
end
