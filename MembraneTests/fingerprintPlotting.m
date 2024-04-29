% Code used to create various fingerprints in Figure 3

%% Setup
load("Data/Recordings2D.mat");
s={humantouch humanpress conductivetouch melting damage insulatedpress insulatedtouch};
titles = {"Human Touch"; "Human Press"; "Conductive Touch"; "Melting";...
    "Damage"; "Insulated Press"; "Insulated Touch"};

%% Plot fingerprints using Recording8 object method

colors = (1/255)*[222 34 129];
figure();
for i = 1:length(s)
    subplot(1,length(s), i);
    s{1,i}.plotfingerprint();
    grid off
    colorbar off
    title(titles(i));
    map = [(colors(1):(1-colors(1))/1680:1).',...
        (colors(2):(1-colors(2))/1680:1).',...
        (colors(3):(1-colors(3))/1680:1).'];
    colormap(map);
end
sgtitle("Fingerprints");

%% Best general configurations

% Take average fingerprint of the 5 selected modalities
modalities = {damage melting humantouch conductivetouch insulatedpress};
totalfingerprint = zeros([1679, 1]);
for i = 1:5
    totalfingerprint = totalfingerprint + modalities{1,i}.fingerprint();
end
totalfingerprint = totalfingerprint./5;

figure();
% Visualize general fingerprint
colors = (1/255)*[38 34 222];
heatmap(reshape([totalfingerprint; NaN], [30, 56]).',...
    'XDisplayLabels',NaN*ones(30,1), 'YDisplayLabels',NaN*ones(56,1));
grid off
colorbar off
map = [(colors(1):(1-colors(1))/1680:1).',...
    (colors(2):(1-colors(2))/1680:1).',...
    (colors(3):(1-colors(3))/1680:1).'];
colormap(map);
title("General Fingerprint");

%% Unique fingerprints

colors = (1/255)*[34 150 20];

figure();
for i = 1:length(s)
    subplot(1,length(s), i);
    uniquefingerprint = totalfingerprint-s{1,i}.fingerprint();
    heatmap(reshape([uniquefingerprint; NaN], [30, 56]).',...
        'XDisplayLabels',NaN*ones(30,1), 'YDisplayLabels',NaN*ones(56,1));
    grid off
    colorbar off
    title(titles(i));
    map = [(colors(1):(1-colors(1))/1680:1).',...
        (colors(2):(1-colors(2))/1680:1).',...
        (colors(3):(1-colors(3))/1680:1).'];
    colormap(flipud(map));
    clim([-1500 1500]);
end
sgtitle("Unique Fingerprints");
