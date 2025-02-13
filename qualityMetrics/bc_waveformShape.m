function [nPeaks, nTroughs, isSomatic, peakLocs, troughLocs, waveformDuration_peakTrough, ...
    spatialDecayPoints, spatialDecaySlope, waveformBaseline, thisWaveform] = bc_waveformShape(templateWaveforms, ...
    thisUnit, maxChannel, ephys_sample_rate, channelPositions, baselineThresh, ...
    waveformBaselineWindow, minThreshDetectPeaksTroughs, firstPeakRatio, plotThis)
% JF
% Get the number of troughs and peaks for each waveform,
% determine whether waveform is likely axonal/dendritic (biggest peak before
% biggest trough - cf: Deligkaris, K., Bullmann, T. & Frey, U.
%   Extracellularly recorded somatic and neuritic signal shapes and classification
%   algorithms for high-density microelectrode array electrophysiology. Front. Neurosci. 10, 421 (2016),
% get waveform duration,
% get waveform baseline maximum absolute value (high
% values are usually indicative of noise units),
% evaluate waveform spatial decay.
% ------
% Inputs
% ------
% templateWaveforms: nTemplates × nTimePoints × nChannels single matrix of
%   template waveforms for each template and channel
% thisUnit: 1 x 1 double vector, current unit number
% maxChannel:  1 x 1 double vector, channel with maximum template waveform current unit number
% ephys_sample_rate: recording sampling rate, in samples per second (eg 30 000)
% channelPositions: [nChannels, 2] double matrix with each row giving the x
%   and y coordinates of that channel, only needed if plotThis is set to true
% baselineThresh: 1 x 1 double vector, minimum baseline value over which
%   units are classified as noise, only needed if plotThis is set to true
% waveformBaselineWindow: QQ describe
% minThreshDetectPeaksTroughs:  QQ describe
% firstPeakRatio: 1 x 1 double. if units have an initial peak before the trough,
%   it must be at least firstPeakRatio times larger than the peak after the trough to qualify as a non-somatic unit. 
% plotThis: boolean, whether to plot waveform and detected peaks or not
% ------
% Outputs
% ------
% nPeaks: number of detected peaks
% nTroughs: number of detected troughs
% isSomatic: boolean, is largest detected peak after the largest detected
%   trough (indicative of a somatic spike).)
% peakLocs: location of detected peaks, used in the GUI
% troughLocs: location of detected troughs, used in the GUI
% waveformDuration_minMax: estimated waveform duration, from detected peak
%   to trough, in us
% waveformDuration_peakTrough: estimated waveform duration, from detected peak
%   to trough, in us
% spatialDecayPoints QQ describe
% spatialDecaySlope QQ describe
% waveformBaselineFlatness
% thisWaveform: this unit's template waveforms at and around the peak
%   channel, used in the GUI
%
% Centroid-based 'real' unit location calculation: Enny van Beest


% (find peaks and troughs using MATLAB's built-in function)
thisWaveform = templateWaveforms(thisUnit, :, maxChannel);
minProminence = minThreshDetectPeaksTroughs * max(abs(squeeze(thisWaveform))); % minimum threshold to detect peaks/troughs

[PKS, peakLocs] = findpeaks(squeeze(thisWaveform), 'MinPeakProminence', minProminence); % get peaks

[TRS, troughLocs] = findpeaks(squeeze(thisWaveform)*-1, 'MinPeakProminence', minProminence); % get troughs

% (check and sanitize the trough output)
% if there is no detected trough, just take minimum value as trough
if isempty(TRS) %
    TRS = min(squeeze(thisWaveform));
    nTroughs = numel(TRS);
    if numel(TRS) > 1 % if more than one trough, take the first (usually the correct one) %QQ should change to better:
        % by looking for location where the data is most tightly distributed
        TRS = TRS(1);
    end
    troughLocs = find(squeeze(thisWaveform) == TRS);
else
    nTroughs = numel(TRS);
end

% (check and sanitize the peak output)
% if there is no detected peak, just take maximum value as peak
if isempty(PKS)
    PKS = max(squeeze(thisWaveform));
    nPeaks = numel(PKS);
    if numel(PKS) > 1 % if more than one peak, take the first (usually the correct one) %QQ should change to better:
        % by looking for location where the data is most tightly distributed
        PKS = PKS(1);
    end
    peakLocs = find(squeeze(thisWaveform) == PKS);
else
    nPeaks = numel(PKS);
end


% (get the peak and trough locations)
troughLoc = troughLocs(TRS == max(TRS)); %QQ could change to better:
% by looking for location where the data is most tightly distributed
if numel(troughLoc) > 1
    troughLoc = troughLoc(1);
end


peakLoc = peakLocs(PKS == max(PKS)); %QQ could change to better:
% by looking for location where the data is most tightly distributed

% check if this is the correct peak
maxPK = max(PKS);
if peakLoc < troughLoc
    if sum(any(peakLocs) > troughLocs) > 0
        possible_realPeak = PKS(peakLocs > troughLocs);
    else
        [possible_realPeak, possible_peakLoc] = max(thisWaveform(troughLoc:end));
    end
    if maxPK < (possible_realPeak * firstPeakRatio) 
        if sum(any(peakLocs) > troughLocs) == 0
            PKS = [PKS, possible_realPeak];
            peakLocs = [peakLocs, possible_peakLoc + troughLoc - 1];
        end
        peakLoc = peakLocs(PKS == possible_realPeak);
    end
end
if numel(peakLoc) > 1
    peakLoc = peakLoc(1);
end

% (assess whether waveform comes from a non-somatic unit or not)
% if maximum peak is after trough and maximum absolute peak value is smaller than trough
if peakLoc > troughLoc && max(TRS) > max(PKS)
    isSomatic = 1; % is a somatic spike
else
    isSomatic = 0;
end

% (get waveform peak to trough duration)
% first assess which peak loc to use
max_waveform_abs_value = max(abs(thisWaveform));
max_waveform_location = abs(thisWaveform) == max_waveform_abs_value;
max_waveform_value = thisWaveform(max_waveform_location);
if max_waveform_value(end) > 0
    peakLoc_forDuration = peakLoc;
    [~, troughLoc_forDuration] = min(thisWaveform(peakLoc_forDuration:end)); % to calculate waveform duration
    troughLoc_forDuration = troughLoc_forDuration + peakLoc_forDuration - 1;
else
    troughLoc_forDuration = troughLoc;
    [~, peakLoc_forDuration] = max(thisWaveform(troughLoc_forDuration:end)); % to calculate waveform duration
    peakLoc_forDuration = peakLoc_forDuration + troughLoc_forDuration - 1;
end

% waveform duration in microseconds
if ~isempty(troughLoc) && ~isempty(peakLoc_forDuration)
    waveformDuration_peakTrough = 1e6 * abs(troughLoc_forDuration-peakLoc_forDuration) / ephys_sample_rate; %in us
else
    waveformDuration_peakTrough = NaN;
end

% (get waveform spatial decay accross channels)
channels_withSameX = find(channelPositions(:, 1) <= channelPositions(maxChannel, 1)+33 & ...
    channelPositions(:, 1) >= channelPositions(maxChannel, 1)-33); % for 4 shank probes
if numel(channels_withSameX) >= 5
    if find(channels_withSameX == maxChannel) > 5
        channels_forSpatialDecayFit = channels_withSameX( ...
            find(channels_withSameX == maxChannel):-1:find(channels_withSameX == maxChannel)-5);
    else
        channels_forSpatialDecayFit = channels_withSameX( ...
            find(channels_withSameX == maxChannel):1:find(channels_withSameX == maxChannel)+5);
    end

    % get maximum value %QQ could we do value at detected trough is peak
    % waveform?
    spatialDecayPoints = max(abs(squeeze(templateWaveforms(thisUnit, :, channels_forSpatialDecayFit))));
    estimatedUnitXY = channelPositions(maxChannel, :);
    relativePositionsXY = channelPositions(channels_forSpatialDecayFit, :) - estimatedUnitXY;
    channelPositions_relative = sqrt(nansum(relativePositionsXY.^2, 2));

    [~, sortexChanPosIdx] = sort(channelPositions_relative);
    spatialDecayPoints_norm = spatialDecayPoints(sortexChanPosIdx);
    spatialDecayFit = polyfit(channelPositions_relative(sortexChanPosIdx), spatialDecayPoints_norm', 1); % fit first order polynomial to data. first output is slope of polynomial, second is a constant
    spatialDecaySlope = spatialDecayFit(1);
else
    warning('No other good channels with same x location')
    spatialDecayFit = NaN;
    spatialDecaySlope = NaN;
    spatialDecayPoints = nan(1, 6);

end

% (get waveform baseline fraction)
if ~isnan(waveformBaselineWindow(1))
    waveformBaseline = max(abs(thisWaveform(waveformBaselineWindow(1): ...
        waveformBaselineWindow(2)))) / max(abs(thisWaveform));
else
    waveformBaseline = NaN;
end

% (plot waveform)
if plotThis

    colorMtx = bc_colors(8);


    figure();

    subplot(4, 2, 7:8)
    pt1 = scatter(channelPositions_relative(sortexChanPosIdx), spatialDecayPoints_norm, [], colorMtx(1, :, :), 'filled');
    hold on;
    lf = plot(channelPositions_relative(sortexChanPosIdx), channelPositions_relative(sortexChanPosIdx)*spatialDecayFit(1)+spatialDecayFit(2), '-', 'Color', colorMtx(2, :, :));

    ylabel('trough size (a.u.)')
    xlabel('distance from peak channel (um)')
    legend(lf, {['linear fit, slope = ', num2str(spatialDecaySlope)]}, 'TextColor', [0.7, 0.7, 0.7], 'Color', 'none')

    subplot(4, 2, 1:6)
    set(gca, 'YDir', 'reverse');
    hold on;
    set(gca, 'XColor', 'w', 'YColor', 'w')
    maxChan = maxChannel;
    maxXC = channelPositions(maxChan, 1);
    maxYC = channelPositions(maxChan, 2);
    chanDistances = ((channelPositions(:, 1) - maxXC).^2 ...
        +(channelPositions(:, 2) - maxYC).^2).^0.5;
    chansToPlot = find(chanDistances < 70);
    wvTime = 1e3 * ((0:size(thisWaveform, 2) - 1) / ephys_sample_rate);
    max_value = max(max(abs(squeeze(templateWaveforms(thisUnit, :, chansToPlot))))) * 5;
    for iChanToPlot = 1:min(20, size(chansToPlot, 1))

        if maxChan == chansToPlot(iChanToPlot) % max channel
            % plot waveform line
            p1 = plot((wvTime + (channelPositions(chansToPlot(iChanToPlot), 1) - 11) / 10), ...
                -squeeze(templateWaveforms(thisUnit, :, chansToPlot(iChanToPlot)))'+ ...
                (channelPositions(chansToPlot(iChanToPlot), 2) ./ 100 * max_value), 'Color', colorMtx(1, :, :));
            hold on;
            % plot peak(s)
            peak = scatter((wvTime(peakLocs) ...
                +(channelPositions(chansToPlot(iChanToPlot), 1) - 11) / 10), ...
                -squeeze(templateWaveforms(thisUnit, peakLocs, chansToPlot(iChanToPlot)))'+ ...
                (channelPositions(chansToPlot(iChanToPlot), 2) ./ 100 * max_value), [], colorMtx(2, :, :), 'v', 'filled');
            % plot trough(s)
            trough = scatter((wvTime(troughLocs) ...
                +(channelPositions(chansToPlot(iChanToPlot), 1) - 11) / 10), ...
                -squeeze(templateWaveforms(thisUnit, troughLocs, chansToPlot(iChanToPlot)))'+ ...
                (channelPositions(chansToPlot(iChanToPlot), 2) ./ 100 * max_value), [], colorMtx(3, :, :), 'v', 'filled');
            % plot baseline lines
            l1 = line([(wvTime(waveformBaselineWindow(1)) + (channelPositions(chansToPlot(iChanToPlot), 1) - 11) / 10), ...
                (wvTime(waveformBaselineWindow(2)) + (channelPositions(chansToPlot(iChanToPlot), 1) - 11) / 10)], ...
                [baselineThresh * -max(abs(thisWaveform))' + ...
                (channelPositions(chansToPlot(iChanToPlot), 2) ./ 100 * max_value), baselineThresh * -max(abs(thisWaveform))' + ...
                (channelPositions(chansToPlot(iChanToPlot), 2) ./ 100 * max_value)], 'Color', colorMtx(4, :, :));

            line([(wvTime(waveformBaselineWindow(1)) + (channelPositions(chansToPlot(iChanToPlot), 1) - 11) / 10), ...
                (wvTime(waveformBaselineWindow(2)) + (channelPositions(chansToPlot(iChanToPlot), 1) - 11) / 10)], ...
                [-baselineThresh * -max(abs(thisWaveform))' + ...
                (channelPositions(chansToPlot(iChanToPlot), 2) ./ 100 * max_value), -baselineThresh * -max(abs(thisWaveform))' + ...
                (channelPositions(chansToPlot(iChanToPlot), 2) ./ 100 * max_value)], 'Color', colorMtx(4, :, :));

            % plot waveform duration
            pT_locs = [troughLoc_forDuration, peakLoc_forDuration];
            dur = plot([(wvTime(min(pT_locs)) ...
                +(channelPositions(chansToPlot(iChanToPlot), 1) - 11) / 10), ...
                (wvTime(max(pT_locs)) ...
                +(channelPositions(chansToPlot(iChanToPlot), 1) - 11) / 10)], ...
                [(squeeze(templateWaveforms(thisUnit, 1, chansToPlot(iChanToPlot))))' + ...
                (channelPositions(chansToPlot(iChanToPlot), 2) ./ 100 * max_value), (squeeze(templateWaveforms(thisUnit, 1, chansToPlot(iChanToPlot))))' + ...
                (channelPositions(chansToPlot(iChanToPlot), 2) ./ 100 * max_value)], '->', 'Color', colorMtx(6, :, :));


        else
            % plot waveform
            plot((wvTime + (channelPositions(chansToPlot(iChanToPlot), 1) - 11) / 10), ...
                -squeeze(templateWaveforms(thisUnit, :, chansToPlot(iChanToPlot)))'+ ...
                (channelPositions(chansToPlot(iChanToPlot), 2) ./ 100 * max_value), 'Color', [0.7, 0.7, 0.7]);
            hold on;
        end
    end

    celLoc = scatter((estimatedUnitXY(1) + -11)/10+wvTime(42), estimatedUnitXY(2)/100*max_value, 50, 'x', 'MarkerEdgeColor', colorMtx(5, :, :), ...
        'MarkerFaceColor', colorMtx(5, :, :));

    legend([p1, peak, trough, dur, l1], {['is somatic =', num2str(isSomatic), newline], ...
        [num2str(nPeaks), ' peak(s)'], [num2str(nTroughs), ...
        ' trough(s)'], 'duration', 'baseline line'}, ...
        'TextColor', [0.7, 0.7, 0.7], 'Color', 'none')
    box off;
    set(gca, 'YTick', []);
    set(gca, 'XTick', []);
    set(gca, 'Visible', 'off')
    if exist('prettify_plot', 'file')
        prettify_plot('FigureColor', 'w')
    else
        warning('https://github.com/Julie-Fabre/prettify-matlab repo missing - download it and add it to your matlab path to make plots pretty')
        makepretty('none')
    end


end
end
