%% Logistics: load in data and select variable to predict

load("Data/EnvironmentalData.mat");

predictionindex = 1; % Humidity
% predictionindex = 2; % Temperature

%% Rank channels and train network using top 50

ranking = fsrftest(alldata, conditionsync(:, predictionindex));
inputs = alldata(:, ranking(1:50)).';
outputs = conditionsync(:, predictionindex).';

net = fitnet(80);
[net,tr] = train(net,inputs,outputs);

%% Plot test set predictions
testX = inputs(:,tr.testInd);
testT = outputs(:,tr.testInd);
testY = net(testX);

plot(hours(times(tr.testInd)-times(1)), smooth(testY), 'linewidth', 2);
hold on
plot(hours(times(tr.testInd)-times(1)), testT, 'linewidth', 3);
legend({"Prediction"; "Ground Truth"});
xlabel("Time (h)");
ylabs = ["Humidity (%)"; "Temperature (^oC)"];
ylabel(ylabs(predictionindex));

box off
set(gca, 'linewidth', 2, 'FontSize', 15);
set(gcf, 'position', [246   456   914   300], 'color', 'w');