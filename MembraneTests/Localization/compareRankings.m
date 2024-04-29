% Create data used for Figure 4's comparison of 4 rankings
% Note that this script takes a long time to run

%% Setup
% Bolt positions and responses loaded from file
load("Data/positions.mat");
load("Data/responses.mat");

% PCA and analytic rankings loaded from file
load("../Data/rankings.mat");

%% Train neural networks

quantities = [1:150];
errors = zeros([length(quantities), 3]); % In order analytic, PCA, F-Test, environmental

for j=1:length(quantities)
    P = quantities(j)
    Y = positions';

    % Standard
    X=deltaresponses(:,standard(1:P))';
    net = fitnet(80);
    [net,tr] = train(net,X,Y,'useParallel','yes');
    testX = X(:,tr.testInd);
    testT = Y(:,tr.testInd);
    testY = net(testX);
    errors(j, 1) = mean(rssq(testT-testY));

    % PCA
    X=deltaresponses(:,pca(1:P))';
    net = fitnet(80);
    [net,tr] = train(net,X,Y,'useParallel','yes');
    testX = X(:,tr.testInd);
    testT = Y(:,tr.testInd);
    testY = net(testX);
    errors(j, 2) = mean(rssq(testT-testY));

    % F-Test
    X=deltaresponses(:,ftest(1:P))';
    net = fitnet(80);
    [net,tr] = train(net,X,Y,'useParallel','yes');
    testX = X(:,tr.testInd);
    testT = Y(:,tr.testInd);
    testY = net(testX);
    errors(j, 3) = mean(rssq(testT-testY));

    % Environment
    X=deltaresponses(:,environmental(1:P))';
    net = fitnet(80);
    [net,tr] = train(net,X,Y,'useParallel','yes');
    testX = X(:,tr.testInd);
    testT = Y(:,tr.testInd);
    testY = net(testX);
    errors(j, 4) = mean(rssq(testT-testY));


end