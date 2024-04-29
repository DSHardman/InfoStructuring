load("Data/membraneEnvironment.mat");

% Rank channels based on their absolute correlation to humidity over a 62 hour period
coefficients = zeros([size(responses, 2), 1]);
for i = 1:size(responses, 2)
    R = corrcoef(conditions(:, 2), responses(:,i));
    if ~isnan(R(1,2))
        coefficients(i) = abs(R(1,2));
    end
end
[~, environmental] = sort(coefficients, "descend");