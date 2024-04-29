classdef Recording8
    % These objects store experimental recordings from all permutations of 8 electrodes
    % at 3 frequencies (10kHz, 50kHz, 100kHz), from Figures 3 & 4

    properties
        times % in seconds
        data % raw data - matrix with width 10080
        eventboundaries % start and stop indicies of each event
        eventlabels % Text descriptions of events
        coeffs % PCA coefficients of 10kHz RMS time series
        fingerprint % Ranked absolute coeffs
    end

    methods
        function obj = Recording8(filename)
            % Constructor - extract files from timestamped teraterm logs

            lines = readlines(filename);
            lines = lines(3:end-2);
        
            timestamps = zeros([length(lines), 1]);
            data = zeros([length(lines), 10074]);
            for i = 1:length(lines)
                line = char(lines(i));
                if i == 1
                    t0 = datetime(line(2:24));
                else
                    timestamps(i) = seconds(datetime(line(2:24)) - t0);
                end
                linedata = str2double(split(line(27:end-2), ', '));
                data(i, :) = linedata([2:1680 1682:3360 3362:5040 5042:6720 6722:8400 8402:10080]);
            end
            
            obj.times = timestamps;
            obj.data = data;
        end

        function dataout = rms10k(obj)
            % Return timeseries data from 10kHz RMS measurements
            dataout = obj.data(:, 1:1679);
        end

        function dataout = phase10k(obj)
            % Return timeseries data from 10kHz phase measurements
            dataout = obj.data(:, 1680:3358);
        end

        function dataout = rms50k(obj)
            % Return timeseries data from 50kHz RMS measurements
            dataout = obj.data(:, 3359:5037);
        end

        function dataout = phase50k(obj)
            % Return timeseries data from 50kHz phase measurements
            dataout = obj.data(:, 5038:6716);
        end

        function dataout = rms100k(obj)
            % Return timeseries data from 100kHz RMS measurements
            dataout = obj.data(:, 6717:8395);
        end

        function dataout = phase100k(obj)
            % Return timeseries data from 100kHz phase measurements
            dataout = obj.data(:, 8396:10074);
        end

        function outobj = calculatefingerprint(obj)
            % Create fingerprint from PCA coefficients
            outobj = obj;
            [coeff,~,~,~,~,~] = pca(outobj.rms10k());
            outobj.coeffs = coeff(:, 1);
            outobj.fingerprint = zeros([1679, 1]);
            [~, ranking] = sort(abs(obj.coeffs), 'descend');
            for i = 1:1679
                outobj.fingerprint(i) = find(ranking==i);
            end
        end

        function plotfingerprint(obj)
            % Plot object's fingerprint: called extensively by
            % FingerprintPlotting.m
            heatmap(reshape([obj.fingerprint; NaN], [30, 56]).',...
            'XDisplayLabels',NaN*ones(30,1), 'YDisplayLabels',NaN*ones(56,1));
        end
    end
end