load("Data/TwoSideData.mat");

% Extract responses and remove those which were incorrectly measured by
% electronics
responses = alldata(4:4:end, :) - alldata(2:4:end, :);
keepers = find(abs(mean(responses, 2) - mean(mean(responses, 2), 1))<1.5);
responses = responses(keepers, :);
targetpositions = targetpositions(keepers, :);

% Give back touch locations a negative y position
load("HandOutline.mat");
targetpositions(:, 2) = targetpositions(:, 2) - min(outline(:, 2));
targetpositions(:, 4) = targetpositions(:, 4) - min(outline(:, 2));
outline(:,2) = outline(:,2)-min(outline(:,2));
targetpositions(:, 4) = -targetpositions(:, 4);


%% Perform F-Test ranking for x & y on front & back
 ranking1 = fsrftest(responses, targetpositions(:, 1));
 ranking2 = fsrftest(responses, targetpositions(:, 2));
 ranking3 = fsrftest(responses, targetpositions(:, 3));
 ranking4 = fsrftest(responses, targetpositions(:, 4));


%% Combine into global rankings
combinedranking = zeros([4*size(responses, 2), 1]);
frontranking = zeros([2*size(responses, 2), 1]);
backranking = zeros([2*size(responses, 2), 1]);
for i = 1:size(responses, 2)
    combinedranking(4*i-3:4*i) = [ranking1(i); ranking2(i);...
                                    ranking3(i); ranking4(i)];
    frontranking(2*i-1:2*i) = [ranking1(i); ranking2(i)];
    backranking(2*i-1:2*i) = [ranking3(i); ranking4(i)];
end
combinedranking = unique(combinedranking, 'stable');
frontranking = unique(frontranking, 'stable');
backranking = unique(backranking, 'stable');

differences = zeros([size(responses, 2), 1]);
for i = 1:size(responses, 2)
    differences(i) = find(backranking==i) - find(frontranking==i);
end
[~, backunique] = sort(differences, 'ascend');
[~, frontunique] = sort(differences, 'descend');

%% WAM localization using top N channels
% Plots results of filmed test set
num_configs=5000;
start = 401; % Index filming started
stop = 425; % Index filming ended
trainers = [1:length(find(keepers<start)) length(find(keepers<stop)):length(keepers)];
testers = length(find(keepers<=start)):length(find(keepers<=stop));

% Plot predictions in pink, ground truth in red
figure();
% First figure should give better front predictions
wamtesting(frontranking(1:num_configs), responses, targetpositions, 1, trainers(randperm(length(trainers))), testers(randperm(length(testers))));
sgtitle("Using Front Ranking");

figure();
% Second figure should give better back predictions
wamtesting(backranking(1:num_configs), responses, targetpositions, 1, trainers(randperm(length(trainers))), testers(randperm(length(testers))));
sgtitle("Using Back Ranking");


%% Implement WAM method from Hardman et al., Tactile Perception in Hydrogel-based Robotic Skins, 2023
function wamtesting(combinations, responses, targetpositions, figs, traininds, testinds)
    load("HandOutline.mat");
    outline(:,2) = outline(:,2)-min(outline(:,2));

    responses = tanh(normalize(responses)); % Deal with outliers

    % Generate test & train sets, if not explicitly input
    if nargin == 4
        P = randperm(length(targetpositions));
        traininds = P(1:floor(0.9*length(targetpositions)));
        testinds = P(ceil(0.9*length(targetpositions)):end);
    end

    testresponses = responses(testinds, :);
    testpositions = targetpositions(testinds, :);
    responses = responses(traininds, :);
    targetpositions = targetpositions(traininds, :);

    % WAM using training set to predict test set

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

        for j = 1:n
            frontprediction = frontprediction + targetpositions(ind(j), 1:2);
            backprediction = backprediction + targetpositions(ind(j), 3:4);
        end
        frontprediction = frontprediction./n;
        backprediction = backprediction./n;

        % Plot prediction
        if figs && i <= 10
            subplot(2,5,i);
            vals = sum;
            
            % Visualise WAMs distribution
            scatter(targetpositions(:,1), targetpositions(:,2), 20, sum, 'filled');
            hold on
            scatter(targetpositions(:,3), targetpositions(:,4), 20, sum, 'filled');

            % Add ground truth and predicted touch locations
            scatter(testpositions(i, 1), testpositions(i, 2), 30, 'r', 'filled');
            scatter(testpositions(i, 3), testpositions(i, 4), 30, 'r', 'filled');
            scatter(frontprediction(1), frontprediction(2), 30, 'm', 'filled');
            scatter(backprediction(1), backprediction(2), 30, 'm', 'filled');

            axis off
            set(gcf, 'color', 'w');

        end
    end

end