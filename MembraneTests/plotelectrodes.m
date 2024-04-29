function plotelectrodes(ranking)
    % Plot corrresponding 8-electrode configuration for a number between 1 & 1680

    load("Data/electrodes.mat");
    electrodes = electrodes(ranking, :);

    viscircles([0 0], 1, 'color', 'k');
    hold on

    % Plot current-injection electrodes in red
    for i = 1:2
        plotnumber(electrodes(i), 'r');
    end

    % Plot voltage-measurement electrodes in blue
    for i = 3:4
        plotnumber(electrodes(i), 'b');
    end
end

function plotnumber(number, color)
    theta = 3*pi/2 - pi/8 - (number-1)*pi/4;
    hold on

    [x, y] = pol2cart(theta, 1);
    scatter(x, y, 50, color, 'filled');
    xlim([-1.1 1.1]);
    ylim([-1.1 1.1]);
    axis square
end