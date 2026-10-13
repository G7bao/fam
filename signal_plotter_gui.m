function signal_plotter_gui
%SIGNAL_PLOTTER_GUI  Programmatic GUI example: an interactive signal plotter.
%
%   Run it by typing  signal_plotter_gui  at the MATLAB command prompt.
%
%   The GUI demonstrates the standard building blocks of a MATLAB GUI:
%     - figure, axes and uipanel containers
%     - uicontrol styles: text, edit, popupmenu, slider, checkbox,
%       radiobutton (inside a uibuttongroup) and pushbutton
%     - uimenu menu bar items
%     - callbacks, input validation and sharing data with guidata
%
%   The user picks a waveform, types its amplitude, frequency and duration,
%   sets the phase with a slider, chooses a line color and presses "Plot".

    % ---------------- Main window ----------------
    hFig = figure( ...
        'Name',          'Signal Plotter', ...
        'NumberTitle',   'off', ...
        'MenuBar',       'none', ...
        'ToolBar',       'figure', ...
        'Units',         'pixels', ...
        'Position',      [200 150 900 550], ...
        'Color',         [0.94 0.94 0.94], ...
        'Resize',        'on', ...
        'CloseRequestFcn', @onClose);

    % ---------------- Menu bar ----------------
    mFile = uimenu(hFig, 'Label', 'File');
    uimenu(mFile, 'Label', 'Save Plot as PNG...', 'Callback', @onSave);
    uimenu(mFile, 'Label', 'Export Data to Workspace', 'Callback', @onExport);
    uimenu(mFile, 'Label', 'Exit', 'Separator', 'on', 'Callback', @onClose);
    mHelp = uimenu(hFig, 'Label', 'Help');
    uimenu(mHelp, 'Label', 'About', 'Callback', @onAbout);

    % ---------------- Axes (plot area) ----------------
    h.ax = axes('Parent', hFig, ...
        'Units', 'normalized', ...
        'Position', [0.07 0.12 0.58 0.80]);
    xlabel(h.ax, 'Time (s)');
    ylabel(h.ax, 'Amplitude');
    title(h.ax, 'Press "Plot" to draw a signal');
    grid(h.ax, 'on');

    % ---------------- Control panel ----------------
    pnl = uipanel('Parent', hFig, ...
        'Title', 'Signal Settings', ...
        'FontWeight', 'bold', ...
        'Units', 'normalized', ...
        'Position', [0.70 0.03 0.28 0.94]);

    % Helper sizes (normalized units inside the panel)
    lx = 0.05;  lw = 0.42;      % label column
    ex = 0.52;  ew = 0.43;      % edit column
    rh = 0.055;                 % row height

    % Waveform type (popup menu)
    uicontrol(pnl, 'Style', 'text', 'String', 'Waveform:', ...
        'Units', 'normalized', 'Position', [lx 0.90 lw rh], ...
        'HorizontalAlignment', 'left');
    h.popWave = uicontrol(pnl, 'Style', 'popupmenu', ...
        'String', {'Sine', 'Cosine', 'Square', 'Sawtooth', 'Damped Sine'}, ...
        'Units', 'normalized', 'Position', [ex 0.905 ew rh], ...
        'BackgroundColor', 'w', ...
        'TooltipString', 'Choose the waveform to plot');

    % Amplitude (edit box)
    uicontrol(pnl, 'Style', 'text', 'String', 'Amplitude:', ...
        'Units', 'normalized', 'Position', [lx 0.82 lw rh], ...
        'HorizontalAlignment', 'left');
    h.edAmp = uicontrol(pnl, 'Style', 'edit', 'String', '1', ...
        'Units', 'normalized', 'Position', [ex 0.825 ew rh], ...
        'BackgroundColor', 'w', ...
        'TooltipString', 'Peak amplitude (any real number)');

    % Frequency (edit box)
    uicontrol(pnl, 'Style', 'text', 'String', 'Frequency (Hz):', ...
        'Units', 'normalized', 'Position', [lx 0.74 lw rh], ...
        'HorizontalAlignment', 'left');
    h.edFreq = uicontrol(pnl, 'Style', 'edit', 'String', '2', ...
        'Units', 'normalized', 'Position', [ex 0.745 ew rh], ...
        'BackgroundColor', 'w', ...
        'TooltipString', 'Frequency in hertz (must be > 0)');

    % Duration (edit box)
    uicontrol(pnl, 'Style', 'text', 'String', 'Duration (s):', ...
        'Units', 'normalized', 'Position', [lx 0.66 lw rh], ...
        'HorizontalAlignment', 'left');
    h.edDur = uicontrol(pnl, 'Style', 'edit', 'String', '2', ...
        'Units', 'normalized', 'Position', [ex 0.665 ew rh], ...
        'BackgroundColor', 'w', ...
        'TooltipString', 'Length of the time axis in seconds (must be > 0)');

    % Phase (slider + live readout)
    h.txtPhase = uicontrol(pnl, 'Style', 'text', 'String', 'Phase: 0 deg', ...
        'Units', 'normalized', 'Position', [lx 0.58 0.90 rh], ...
        'HorizontalAlignment', 'left');
    h.sldPhase = uicontrol(pnl, 'Style', 'slider', ...
        'Min', 0, 'Max', 360, 'Value', 0, ...
        'SliderStep', [1/360 15/360], ...
        'Units', 'normalized', 'Position', [lx 0.535 0.90 0.045], ...
        'TooltipString', 'Phase shift in degrees', ...
        'Callback', @onPhaseSlider);

    % Line color (radio buttons in a button group)
    h.bgColor = uibuttongroup('Parent', pnl, ...
        'Title', 'Line Color', ...
        'Units', 'normalized', 'Position', [lx 0.37 0.90 0.14]);
    h.rbBlue  = uicontrol(h.bgColor, 'Style', 'radiobutton', 'String', 'Blue', ...
        'Units', 'normalized', 'Position', [0.04 0.25 0.30 0.5]);
    h.rbRed   = uicontrol(h.bgColor, 'Style', 'radiobutton', 'String', 'Red', ...
        'Units', 'normalized', 'Position', [0.36 0.25 0.30 0.5]);
    h.rbGreen = uicontrol(h.bgColor, 'Style', 'radiobutton', 'String', 'Green', ...
        'Units', 'normalized', 'Position', [0.66 0.25 0.32 0.5]);
    set(h.bgColor, 'SelectedObject', h.rbBlue);

    % Options (check boxes)
    h.chkGrid = uicontrol(pnl, 'Style', 'checkbox', 'String', 'Show grid', ...
        'Value', 1, ...
        'Units', 'normalized', 'Position', [lx 0.30 0.90 rh], ...
        'Callback', @onGridToggle);
    h.chkHold = uicontrol(pnl, 'Style', 'checkbox', ...
        'String', 'Overlay (hold on)', 'Value', 0, ...
        'Units', 'normalized', 'Position', [lx 0.245 0.90 rh]);

    % Push buttons
    uicontrol(pnl, 'Style', 'pushbutton', 'String', 'Plot', ...
        'FontWeight', 'bold', ...
        'Units', 'normalized', 'Position', [lx 0.15 0.42 0.07], ...
        'Callback', @onPlot);
    uicontrol(pnl, 'Style', 'pushbutton', 'String', 'Clear', ...
        'Units', 'normalized', 'Position', [ex 0.15 ew 0.07], ...
        'Callback', @onClear);
    uicontrol(pnl, 'Style', 'pushbutton', 'String', 'Close', ...
        'Units', 'normalized', 'Position', [lx 0.07 0.90 0.06], ...
        'Callback', @onClose);

    % Status bar
    h.txtStatus = uicontrol(pnl, 'Style', 'text', 'String', 'Ready.', ...
        'Units', 'normalized', 'Position', [lx 0.005 0.90 0.05], ...
        'HorizontalAlignment', 'left', ...
        'ForegroundColor', [0 0.45 0]);

    % Data from the last plot (for File > Export)
    h.t = [];
    h.y = [];

    % Store all handles in the figure so every callback can reach them
    guidata(hFig, h);
end

% ======================================================================
%                              Callbacks
% ======================================================================

function onPlot(src, ~)
    h = guidata(src);

    % ---- Read and validate inputs ----
    A   = str2double(get(h.edAmp,  'String'));
    f   = str2double(get(h.edFreq, 'String'));
    dur = str2double(get(h.edDur,  'String'));

    if isnan(A)
        showError(h, 'Amplitude must be a number.', h.edAmp);  return;
    end
    if isnan(f) || f <= 0
        showError(h, 'Frequency must be a positive number.', h.edFreq);  return;
    end
    if isnan(dur) || dur <= 0
        showError(h, 'Duration must be a positive number.', h.edDur);  return;
    end

    phaseDeg = get(h.sldPhase, 'Value');
    phi      = phaseDeg * pi / 180;

    % ---- Build the signal ----
    nPts = max(500, ceil(200 * f * dur));   % enough samples per cycle
    t    = linspace(0, dur, nPts);
    arg  = 2*pi*f*t + phi;

    waves    = get(h.popWave, 'String');
    waveName = waves{get(h.popWave, 'Value')};
    switch waveName
        case 'Sine'
            y = A * sin(arg);
        case 'Cosine'
            y = A * cos(arg);
        case 'Square'
            y = A * sign(sin(arg));
        case 'Sawtooth'
            % Rises from -A to +A once per period (no toolbox needed)
            y = A * (2 * mod(arg / (2*pi), 1) - 1);
        case 'Damped Sine'
            y = A * exp(-t / (dur/3)) .* sin(arg);
    end

    % ---- Pick the line color from the radio buttons ----
    switch get(get(h.bgColor, 'SelectedObject'), 'String')
        case 'Blue',  c = [0.00 0.45 0.74];
        case 'Red',   c = [0.85 0.10 0.10];
        case 'Green', c = [0.20 0.60 0.20];
    end

    % ---- Plot ----
    if get(h.chkHold, 'Value')
        hold(h.ax, 'on');
    else
        hold(h.ax, 'off');
    end
    plot(h.ax, t, y, 'Color', c, 'LineWidth', 1.5, ...
        'DisplayName', sprintf('%s, %g Hz', waveName, f));
    hold(h.ax, 'off');

    xlabel(h.ax, 'Time (s)');
    ylabel(h.ax, 'Amplitude');
    title(h.ax, sprintf('%s wave: A = %g, f = %g Hz, \\phi = %d^\\circ', ...
        waveName, A, f, round(phaseDeg)));
    applyGrid(h);
    if get(h.chkHold, 'Value')
        legend(h.ax, 'Location', 'best');
    else
        legend(h.ax, 'off');
    end

    h.t = t;
    h.y = y;
    guidata(src, h);
    setStatus(h, sprintf('Plotted %s (%d pts).', lower(waveName), nPts), false);
end

function onClear(src, ~)
    h = guidata(src);
    cla(h.ax, 'reset');
    xlabel(h.ax, 'Time (s)');
    ylabel(h.ax, 'Amplitude');
    title(h.ax, 'Press "Plot" to draw a signal');
    applyGrid(h);
    h.t = [];
    h.y = [];
    guidata(src, h);
    setStatus(h, 'Plot cleared.', false);
end

function onPhaseSlider(src, ~)
    h = guidata(src);
    val = round(get(src, 'Value'));
    set(src, 'Value', val);
    set(h.txtPhase, 'String', sprintf('Phase: %d deg', val));
end

function onGridToggle(src, ~)
    applyGrid(guidata(src));
end

function onSave(src, ~)
    h = guidata(src);
    [file, path] = uiputfile({'*.png', 'PNG image (*.png)'}, ...
        'Save plot as', 'signal_plot.png');
    if isequal(file, 0)
        return;     % user pressed Cancel
    end
    % Copy the axes into an invisible figure so only the plot is saved
    tmp = figure('Visible', 'off');
    newAx = copyobj(h.ax, tmp);
    set(newAx, 'Units', 'normalized', 'Position', [0.13 0.11 0.775 0.815]);
    print(tmp, fullfile(path, file), '-dpng', '-r150');
    close(tmp);
    setStatus(h, ['Saved ' file], false);
end

function onExport(src, ~)
    h = guidata(src);
    if isempty(h.t)
        showError(h, 'Nothing to export yet - press "Plot" first.', []);
        return;
    end
    assignin('base', 'sig_t', h.t);
    assignin('base', 'sig_y', h.y);
    setStatus(h, 'Exported sig_t and sig_y to the workspace.', false);
end

function onAbout(~, ~)
    msgbox({'Signal Plotter', '', ...
        'Example programmatic MATLAB GUI built with', ...
        'figure, axes, uipanel, uibuttongroup,', ...
        'uicontrol, uimenu and guidata.'}, ...
        'About', 'help');
end

function onClose(src, ~)
    hFig = ancestor(src, 'figure');
    answer = questdlg('Close the Signal Plotter?', 'Confirm', ...
        'Yes', 'No', 'Yes');
    if strcmp(answer, 'Yes')
        delete(hFig);
    end
end

% ======================================================================
%                              Helpers
% ======================================================================

function applyGrid(h)
    if get(h.chkGrid, 'Value')
        grid(h.ax, 'on');
    else
        grid(h.ax, 'off');
    end
end

function setStatus(h, msg, isError)
    if isError
        set(h.txtStatus, 'String', msg, 'ForegroundColor', [0.8 0 0]);
    else
        set(h.txtStatus, 'String', msg, 'ForegroundColor', [0 0.45 0]);
    end
end

function showError(h, msg, hEdit)
    setStatus(h, msg, true);
    errordlg(msg, 'Invalid Input', 'modal');
    if ~isempty(hEdit)
        uicontrol(hEdit);   % give keyboard focus back to the bad field
    end
end
