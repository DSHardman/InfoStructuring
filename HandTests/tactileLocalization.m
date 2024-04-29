% Figure 6b & c tactile localizations

%% Logistics: load in data for 399 light touches
load("Data/Touch399Data.mat");
load("Data/HandOutline.mat");

responses = responses(1:399, :); % If disregarding final 100
targetpositions = targetpositions(1:399, :); % If disregarding final 100

%% Perform F-Test ranking
ranking = franking(responses, targetpositions);

%% WAM localization using top 100 channels: plot 10 random predictions from test set
% Prediction in pink, ground truth in red
figure();
error = wamtesting(ranking(1:100), responses, targetpositions, 1);
sgtitle("Mean error over entire test set: "+ string(error) + " mm");

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
            if ~inpolygon(xx(k,j),yy(k,j), outline(:,1), outline(:,2))
                value_interp(k,j) = nan;
            end
        end
    end
    contourf(xx,yy,value_interp, 100, 'LineStyle', 'none');
    axis off
    colormap hot
end


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
    load("Data/HandOutline.mat");
        
    responses = tanh(normalize(responses)); % Deal with outliers

    % Generate test & train sets
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

        % Prediction is the average location of the 10 brightest pixels
        [~, ind] = sort(sum, 'descend');
        n = min(10, size(responses, 2));
        prediction = [mean(targetpositions(ind(1:n), 1)),...
                        mean(targetpositions(ind(1:n), 2))];

        % Add localization error to running sum 
        error = error + rssq(prediction-testpositions(i,:));

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
                    if ~inpolygon(xx(k,j),yy(k,j), outline(:,1), outline(:,2))
                        value_interp(k,j) = nan;
                    end
                end
            end
            contourf(xx,yy,value_interp, 100, 'LineStyle', 'none');
            
            hold on
            % Add ground truth and predicted touch locations
            scatter(testpositions(i, 1), testpositions(i, 2), 50, 'r', 'filled');
            scatter(prediction(1), prediction(2), 50, 'm', 'filled');
            axis off
            set(gcf, 'color', 'w');
        end
    end
    error = error/size(testresponses, 1); % calculate mean
    error = error*3.32; % convert to mm
end