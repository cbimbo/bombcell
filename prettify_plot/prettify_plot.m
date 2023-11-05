function prettify_plot(varargin)
% make current figure pretty
% ------
% Inputs: Name - Pair arguments
% ------
% - XLimits: string or number.
%   If a string, either:
%       - 'keep': don't change any of the xlimits
%       - 'same': set all xlimits to the same values
%       - 'row': set all xlimits to the same values for each subplot row
%       - 'col': set all xlimits to the same values for each subplot col
%   If a number, 1 * 2 double setting the minimum and maximum values
% - YLimits: string or number.
%   If a string, either:
%       - 'keep': don't change any of the ylimits
%       - 'same': set all ylimits to the same values
%       - 'row': set all ylimits to the same values for each subplot row
%       - 'col': set all ylimits to the same values for each subplot col
%   If a number, 1 * 2 double setting the minimum and maximum values
% - FigureColor: string (e.g. 'w', 'k', 'Black', ..) or RGB value defining the plots
%       background color.
% - TextColor: string (e.g. 'w', 'k', 'Black', ..) or RGB value defining the plots
%       text color.
% - LegendLocation: string determining where the legend is. Either:
%   'north'	Inside top of axes
%   'south'	Inside bottom of axes
%   'east'	Inside right of axes
%   'west'	Inside left of axes
%   'northeast'	Inside top-right of axes (default for 2-D axes)
%   'northwest'	Inside top-left of axes
%   'southeast'	Inside bottom-right of axes
%   'southwest'	Inside bottom-left of axes
%   'northoutside'	Above the axes
%   'southoutside'	Below the axes
%   'eastoutside'	To the right of the axes
%   'westoutside'	To the left of the axes
%   'northeastoutside'	Outside top-right corner of the axes (default for 3-D axes)
%   'northwestoutside'	Outside top-left corner of the axes
%   'southeastoutside'	Outside bottom-right corner of the axes
%   'southwestoutside'	Outside bottom-left corner of the axes
%   'best'	Inside axes where least conflict occurs with the plot data at the time that you create the legend. If the plot data changes, you might need to reset the location to 'best'.
%   'bestoutside'	Outside top-right corner of the axes (when the legend has a vertical orientation) or below the axes (when the legend has a horizontal orientation)
% - LegendReplace: ! buggy ! boolean, if you want the legend box to be replace by text
%       directly plotted on the figure, next to the each subplot's
%       line/point
% - titleFontSize: double
% - labelFontSize: double
% - generalFontSize: double
% - Font: string. See listfonts() for a list of all available fonts
% - pointSize: double
% - lineThickness: double
% - AxisTicks
% - AxisBox
% - AxisAspectRatio 'equal', 'square', 'image'
% - AxisTightness 'tickaligned' 'tight', 'padded'
% ------
% to do:
% - option to adjust vertical and horiz. lines
% - padding
% - fit data to plot (adjust lims)
% - padding / suptitles
% ------
% Julie M. J. Fabre

% Set default parameter values
options = struct('XLimits', 'keep', ... %set to 'keep' if you don't want any changes
    'YLimits', 'keep', ... %set to 'keep' if you don't want any changes
    'CLimits', 'all', ... %set to 'keep' if you don't want any changes
    'LimitsRound', 2, ... % set to NaN if you don't want any changes 
    'SymmetricalCLimits', true, ...
    'FigureColor', [1, 1, 1], ...
    'TextColor', [0, 0, 0], ...
    'LegendLocation', 'best', ...
    'LegendReplace', false, ... %BUGGY
    'LegendBox', 'off', ...
    'TitleFontSize', 15, ...
    'LabelFontSize', 15, ...
    'GeneralFontSize', 15, ...
    'Font', 'Arial', ...
    'BoldTitle', 'off', ...
    'WrapText', 'on', ...
    'PointSize', 15, ...
    'LineThickness', 2, ...
    'AxisTicks', 'out', ...
    'TickLength', 0.035, ...
    'TickWidth', 1.3, ...
    'AxisBox', 'off', ...
    'AxisGrid', 'off', ...
    'AxisAspectRatio', 'keep', ... %set to 'keep' if you don't want any changes
    'AxisTightness', 'keep', ... %BUGGY set to 'keep' if you don't want any changes %'AxisWidth', 'keep',... %BUGGY set to 'keep' if you don't want any changes %'AxisHeight', 'keep',...%BUGGY set to 'keep' if you don't want any changes
    'AxisUnits', 'points', ...
    'ChangeColormaps', true,... %set to false if you don't want any changes
    'DivergingColormap', '*RdBu', ... 
    'SequentialColormap', 'YlOrRd', ... 
    'PairedColormap', 'Paired', ... 
    'QualitativeColormap', 'Set1'); %

% read the acceptable names
optionNames = fieldnames(options);

% count arguments
nArgs = length(varargin);
if round(nArgs/2) ~= nArgs / 2
    error('prettify_plot() needs propertyName/propertyValue pairs')
end

for iPair = reshape(varargin, 2, []) % pair is {propName;propValue}
    %inputName = lower(iPair{1}); % make case insensitive
    inputName = iPair{1};

    if any(strcmp(inputName, optionNames))
        % overwrite options. If you want you can test for the right class here
        % Also, if you find out that there is an option you keep getting wrong,
        % you can use "if strcmp(inpName,'problemOption'),testMore,end"-statements
        options.(inputName) = iPair{2};
    else
        error('%s is not a recognized parameter name', inputName)
    end
end

% Check Name/Value pairs make sense
if ischar(options.FigureColor) || isstring(options.FigureColor) %convert to rgb
    options.FigureColor = rgb(options.FigureColor);
end
if ischar(options.TextColor) || isstring(options.TextColor) %convert to rgb
    options.TextColor = rgb(options.TextColor);
end
if sum(options.FigureColor-options.TextColor) <= 1.5 %check background and text and sufficiently different
    if sum(options.FigureColor) >= 1.5 % light
        options.TextColor = [0, 0, 0];
    else
        options.TextColor = [1, 1, 1]; 
    end
end
% Get handles for current figure and axis
currFig = gcf;


% Set color properties for figure and axis
set(currFig, 'color', options.FigureColor);

% get axes children
all_axes = find(arrayfun(@(x) contains(currFig.Children(x).Type, 'axes'), 1:size(currFig.Children, 1)));

% update font
fontname(options.Font)

% update (sub)plot properties
for iAx = 1:size(all_axes, 2)
    thisAx = all_axes(iAx);
    currAx = currFig.Children(thisAx);
    set(currAx, 'color', options.FigureColor);
    if ~isempty(currAx)

        % Set grid/box/tick options
        set(currAx, 'TickDir', options.AxisTicks)
        set(currAx, 'Box', options.AxisBox)
        set(currAx, 'TickLength', [options.TickLength, options.TickLength]); % Make tick marks longer.
        set(currAx, 'LineWidth', options.TickWidth); % Make tick marks and axis lines thicker.

        %set(currAx, 'Grid', options.AxisGrid)
        if strcmp(options.AxisAspectRatio, 'keep') == 0
            axis(currAx, options.AxisAspectRatio)
        end
        if strcmp(options.AxisTightness, 'keep') == 0
            axis(currAx, options.AxisTightness)
        end

        % Set text properties
        set(currAx.XLabel, 'FontSize', options.LabelFontSize, 'Color', options.TextColor);
        if strcmp(currAx.YAxisLocation, 'left') % if there is both a left and right yaxis, keep the colors
            set(currAx.YLabel, 'FontSize', options.LabelFontSize);
        else
            set(currAx.YLabel, 'FontSize', options.LabelFontSize, 'Color', options.TextColor);
        end
        if strcmp(options.BoldTitle, 'on')
            set(currAx.Title, 'FontSize', options.TitleFontSize, 'Color', options.TextColor, ...
                'FontWeight', 'Bold')
        else
            set(currAx.Title, 'FontSize', options.TitleFontSize, 'Color', options.TextColor, ...
                'FontWeight', 'Normal');
        end
        set(currAx, 'FontSize', options.GeneralFontSize, 'GridColor', options.TextColor, ...
            'YColor', options.TextColor, 'XColor', options.TextColor, ...
            'MinorGridColor', options.TextColor);
        if ~isempty(currAx.Legend)
            set(currAx.Legend, 'Color', options.FigureColor, 'TextColor', options.TextColor)
        end

        % Adjust properties of line children within the plot
        childLines = findall(currAx, 'Type', 'line');
        for thisLine = childLines'
            % if any lines/points become the same as background, change
            % these.
            if sum(thisLine.Color == options.FigureColor) == 3
                thisLine.Color = options.TextColor;
            end
            % adjust markersize
            if strcmp('.', get(thisLine, 'Marker'))
                set(thisLine, 'MarkerSize', options.PointSize);
            end
            % adjust line thickness
            if strcmp('-', get(thisLine, 'LineStyle'))
                set(thisLine, 'LineWidth', options.LineThickness);
            end
        end

        % Adjust properties of errorbars children within the plot
        childErrBars = findall(currAx, 'Type', 'ErrorBar');
        for thisErrBar = childErrBars'
            if strcmp('.', get(thisErrBar, 'Marker'))
                set(thisErrBar, 'MarkerSize', options.PointSize);
            end
            if strcmp('-', get(thisErrBar, 'LineStyle'))
                set(thisErrBar, 'LineWidth', options.LineThickness);
            end
        end

        ax_pos = get(currAx, 'Position');

        % Get x and y limits
        xlims_subplot(iAx, :) = currAx.XLim;
        ylims_subplot(iAx, :) = currAx.YLim;
        clims_subplot(iAx, :) = currAx.CLim;

        % adjust legend
        if ~isempty(currAx.Legend)
            if options.LegendReplace
                prettify_legend(currAx)
            else
                set(currAx.Legend, 'Location', options.LegendLocation)
                set(currAx.Legend, 'Box', options.LegendBox)
            end
        end


    end
end

prettify_axis_limits(all_axes, currFig, ...
    ax_pos, xlims_subplot, ylims_subplot, clims_subplot, ...
    options.XLimits, options.YLimits, options.CLimits, ...
    options.LimitsRound, options.SymmetricalCLimits, ...
    options.LegendReplace, options.LegendLocation);

colorbars = findobj(currFig, 'Type', 'colorbar');
prettify_colorbar(colorbars, options.ChangeColormaps, options.DivergingColormap,...
    options.SequentialColormap);


%prettify_axis_locations;


