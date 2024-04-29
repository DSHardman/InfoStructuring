% Figure 6a
% Load ground truth data and responses from all 1.7M channels over 81 hours
% load("Data/Weekend.mat"); 

%% Plot response to environment: each line is the average of multiple channels so this is possible
averages = zeros([size(alldata, 1), 870]);
for i = 1:2:1740
    reading = smooth(mean(alldata(1:end,i+[1:1984:1725211]).'), 10)*22/1024;
    averages(:, (i+1)/2) = reading-reading(1);
    plot(seconds(times(1:end)-times(1))/3600, reading-reading(1), 'color', 'k', 'LineStyle', '-', 'marker', 'none');
    hold on
end
ylim([-0.8 1]);

%% Neural network predictions of a randomly extracted test set

% F-Test ranking of these based on humidity
ranking = fsrftest(averages, conditionsync(:, 1));

% Extract top 50 channels from F-Test
inputs = averages(:, ranking(1:50)).';

% Train feedforward network to predict humidities
outputs = conditionsync(:, 1).';
net = fitnet(80);
[net,tr] = train(net,inputs,outputs);

% Plot predictions of test set
testX = inputs(:,tr.testInd);
testT = outputs(:,tr.testInd);
testY = net(testX);
my_colors
plot(hours(conditiontimessync(tr.testInd)-conditiontimessync(1)), testY, 'linewidth', 2, 'Color', colors(3, :));
hold on
plot(hours(conditiontimessync(tr.testInd)-conditiontimessync(1)), testT, 'linewidth', 3, 'Color', colors(2, :));
box off
set(gca, 'linewidth', 2, 'FontSize', 15);

%% Rank all 1.7M channels based on correlation with environmental humidity
coefficients = zeros([size(alldata, 2), 1]);
for i = 1:size(alldata, 2)
    R = corrcoef(conditionsync(:, 1), alldata(:,i));
    if ~isnan(R(1,2))
        coefficients(i) = abs(R(1,2));
    end
end
[~, ranking] = sort(coefficients, "descend");