% Create conductive touch's F-Test ranking based on data from 1000
% randomized touches

%% Setup
load("Data/responses.mat");
load("Data/positions.mat");

%% Use inbuilt function to give F-test ranking for x & y predictions
x_ranking= fsrftest(deltaresponses,positions(:, 1));
y_ranking= fsrftest(deltaresponses,positions(:, 2));

%% Combine two rankings to give localization ftest ranking
combinedweights = zeros(size(x_ranking));
for i = 1:3358
    combinedweights(i) = find(x_ranking==i)+find(y_ranking==i);
end
[~, ftest] = sort(combinedweights, "ascend");