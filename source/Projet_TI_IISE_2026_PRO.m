function Projet_TI_IISE_2026_PRO()
% =========================================================================
%  IISE IMAGE ANALYZER PRO - ADVANCED EDITION
%  Version : 2.0
%  Authors : Hamza Labbaalli & Abdelouahed Id-Boubrik | IISE 2026
%  Compatibility : MATLAB R2013a and later
%  Architecture  : Procedural GUI + Nested Functions (GUIDE-free)
% =========================================================================
%
%  MODULE STRUCTURE:
%    [1] Color & Theme Definitions
%    [2] Shared Application State (imgData struct)
%    [3] UI Construction:
%          build_figure()         -> main window
%          build_header()         -> top banner
%          build_image_panel()    -> dual axes (original / processed)
%          build_analysis_panel() -> histogram + statistics
%          build_control_panel()  -> filters, sliders, buttons
%          build_footer()         -> status bar + credits
%    [4] Event Callbacks:
%          cb_load_image()
%          cb_save_image()
%          cb_save_histogram()
%          cb_apply_filter()
%          cb_slider_changed()
%          cb_roi_select()
%          cb_reset_image()
%          cb_noise_toggle()
%    [5] Image Processing Engine:
%          proc_apply()           -> dispatcher
%          proc_enhancement()     -> brightness/contrast/gamma etc.
%          proc_filter()          -> spatial filters
%          proc_edge()            -> edge detection
%          proc_morphology()      -> morph ops
%          proc_segment()         -> threshold / OTSU / multi-level
%    [6] Statistics Engine:
%          stats_compute()        -> full stat struct
%          stats_display()        -> format & render
%    [7] Utility Functions:
%          util_status()          -> update status bar
%          util_safe_gray()       -> ensure grayscale
%          util_clamp()           -> uint8 clamp
%          util_normalize()       -> [0,1] double
%          util_generate_icons()  -> matrix icons for buttons

% =========================================================================
% [1] THEME & COLORS
% =========================================================================
    C.mainBlue   = [0.05, 0.14, 0.26];
    C.accentBlue = [0.00, 0.47, 0.75];
    C.darkPanel  = [0.10, 0.20, 0.32];
    C.midPanel   = [0.18, 0.30, 0.44];
    C.bgLight    = [0.91, 0.93, 0.96];
    C.white      = [1.00, 1.00, 1.00];
    C.textGray   = [0.30, 0.30, 0.30];
    C.green      = [0.10, 0.52, 0.18];
    C.orange     = [0.85, 0.42, 0.00];
    C.red        = [0.75, 0.10, 0.10];
    C.statBg     = [0.96, 0.97, 0.98];
    C.borderGray = [0.75, 0.78, 0.82];

% =========================================================================
% [2] SHARED APPLICATION STATE
% =========================================================================
    S.original    = [];   % Original loaded image (RGB or gray)
    S.gray        = [];   % Grayscale version
    S.processed   = [];   % Current processed result
    S.roi_mask    = [];   % ROI binary mask
    S.has_roi     = false;
    S.last_filter = 1;
    S.filepath    = '';
    S.filename    = '';

% =========================================================================
% [3] UI CONSTRUCTION
% =========================================================================

    % -- MAIN FIGURE --
    fig = figure( ...
        'Name',        'IISE Image Analyzer PRO v2.0', ...
        'Units',       'normalized', ...
        'Position',    [0.04, 0.04, 0.92, 0.90], ...
        'Color',       C.bgLight, ...
        'MenuBar',     'none', ...
        'ToolBar',     'none', ...
        'NumberTitle', 'off', ...
        'Resize',      'on', ...
        'CloseRequestFcn', @cb_close);

    % -- HEADER BANNER --
    uipanel('Parent', fig, 'Units', 'normalized', ...
        'Position', [0 0.945 1 0.055], ...
        'BackgroundColor', C.mainBlue, 'BorderType', 'none');
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.01 0.952 0.55 0.038], ...
        'String', '  >> IISE IMAGE ANALYZER PRO  |  v2.0', ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ForegroundColor', C.white, 'BackgroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'left');
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.60 0.952 0.38 0.038], ...
        'String', 'Advanced Image Processing Suite  |  MATLAB 2013+', ...
        'FontSize', 9, 'FontWeight', 'normal', ...
        'ForegroundColor', [0.70 0.80 0.90], 'BackgroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'right');

    % ---------------------------------------------------------------
    % VISUALIZATION PANEL (left ~65%)
    % ---------------------------------------------------------------
    pnlImages = uipanel('Parent', fig, 'Title', ' VISUALISATION ', ...
        'Units', 'normalized', 'Position', [0.01 0.26 0.64 0.67], ...
        'BackgroundColor', C.white, 'FontWeight', 'bold', 'FontSize', 10, ...
        'ForegroundColor', C.accentBlue);

    axOrig = axes('Parent', pnlImages, 'Units', 'normalized', ...
        'Position', [0.03 0.10 0.44 0.82]);
    title(axOrig, 'IMAGE ORIGINALE', 'FontSize', 9, 'Color', C.mainBlue, 'FontWeight', 'bold');
    axis(axOrig, 'off');
    set(axOrig, 'Box', 'on', 'XColor', C.borderGray, 'YColor', C.borderGray);

    axProc = axes('Parent', pnlImages, 'Units', 'normalized', ...
        'Position', [0.53 0.10 0.44 0.82]);
    title(axProc, 'IMAGE TRAITEE', 'FontSize', 9, 'Color', C.mainBlue, 'FontWeight', 'bold');
    axis(axProc, 'off');
    set(axProc, 'Box', 'on', 'XColor', C.borderGray, 'YColor', C.borderGray);

    % image info labels under axes
    lblOrigInfo = uicontrol('Parent', pnlImages, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.03 0.02 0.44 0.06], ...
        'String', '[ Aucune image ]', 'FontSize', 8, ...
        'BackgroundColor', C.bgLight, 'ForegroundColor', C.textGray, ...
        'HorizontalAlignment', 'center');
    lblProcInfo = uicontrol('Parent', pnlImages, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.53 0.02 0.44 0.06], ...
        'String', '[ Aucun traitement ]', 'FontSize', 8, ...
        'BackgroundColor', C.bgLight, 'ForegroundColor', C.textGray, ...
        'HorizontalAlignment', 'center');

    % ---------------------------------------------------------------
    % ANALYSIS PANEL (right ~33%)
    % ---------------------------------------------------------------
    pnlAnalyse = uipanel('Parent', fig, 'Title', ' ANALYSE & STATISTIQUES ', ...
        'Units', 'normalized', 'Position', [0.66 0.26 0.33 0.67], ...
        'BackgroundColor', C.white, 'FontWeight', 'bold', 'FontSize', 10, ...
        'ForegroundColor', C.accentBlue);

    axHist = axes('Parent', pnlAnalyse, 'Units', 'normalized', ...
        'Position', [0.08 0.58 0.86 0.36]);
    title(axHist, 'Histogramme', 'FontSize', 8, 'Color', C.mainBlue);
    xlabel(axHist, 'Intensite', 'FontSize', 7);
    ylabel(axHist, 'Pixels', 'FontSize', 7);

    % Stats display
    lblStats = uicontrol('Parent', pnlAnalyse, 'Style', 'text', ...
        'String', '', 'Units', 'normalized', ...
        'Position', [0.04 0.04 0.92 0.50], ...
        'BackgroundColor', C.statBg, ...
        'FontSize', 9, 'FontName', 'Courier New', ...
        'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'left');
    stats_display([], lblStats, C); % Initialize with empty

    % ---------------------------------------------------------------
    % CONTROLS PANEL (bottom full-width)
    % ---------------------------------------------------------------
    pnlControl = uipanel('Parent', fig, 'Title', ' CONTROLES & TRAITEMENTS ', ...
        'Units', 'normalized', 'Position', [0.01 0.04 0.98 0.20], ...
        'BackgroundColor', C.white, 'FontWeight', 'bold', 'FontSize', 10, ...
        'ForegroundColor', C.accentBlue);

    % --- Column 1: File Operations ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- FICHIER --', 'Units', 'normalized', ...
        'Position', [0.005 0.72 0.09 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, ...
        'HorizontalAlignment', 'center');

    btnLoad = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', '  CHARGER', 'Units', 'normalized', ...
        'Position', [0.005 0.48 0.09 0.22], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'BackgroundColor', C.accentBlue, 'ForegroundColor', C.white, ...
        'TooltipString', 'Charger une image (JPG/PNG/BMP/TIF)', ...
        'Callback', @cb_load_image); %#ok<NASGU>

    btnReset = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', '  RESET', 'Units', 'normalized', ...
        'Position', [0.005 0.24 0.09 0.22], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'BackgroundColor', C.orange, 'ForegroundColor', C.white, ...
        'TooltipString', 'Reinitialiser le traitement', ...
        'Callback', @cb_reset_image); %#ok<NASGU>

    btnROI = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', '  ROI', 'Units', 'normalized', ...
        'Position', [0.005 0.02 0.09 0.20], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'BackgroundColor', C.midPanel, 'ForegroundColor', C.white, ...
        'TooltipString', 'Selectionner une region d''interet (rectangle)', ...
        'Callback', @cb_roi_select); %#ok<NASGU>

    % --- Column 2: Filter Selector ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- FILTRE / OPERATION --', 'Units', 'normalized', ...
        'Position', [0.10 0.72 0.17 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, ...
        'HorizontalAlignment', 'center');

    filterList = { ...
        '[ Originale ]', ...
        '-- AMELIORATION --', ...
        'Correction Gamma', ...
        'Luminosite', ...
        'Contrastage Lineaire', ...
        'Egalisation Histogramme', ...
        'Egalisation Adaptative (CLAHE)', ...
        '-- FILTRAGE --', ...
        'Filtre Median', ...
        'Flou Gaussien', ...
        'Filtre Nettete', ...
        'Filtre Laplacien', ...
        '-- BRUIT --', ...
        'Bruit Gaussien', ...
        'Bruit Poivre & Sel', ...
        '-- DETECTION CONTOURS --', ...
        'Sobel', ...
        'Prewitt', ...
        'Roberts', ...
        'Canny', ...
        '-- MORPHOLOGIE --', ...
        'Dilatation', ...
        'Erosion', ...
        'Ouverture', ...
        'Fermeture', ...
        '-- SEGMENTATION --', ...
        'Seuillage Manuel', ...
        'OTSU (Auto)', ...
        'Logarithmique', ...
        'Exponentielle', ...
    };

    dropdown = uicontrol('Parent', pnlControl, 'Style', 'popupmenu', ...
        'String', filterList, ...
        'Units', 'normalized', 'Position', [0.10 0.10 0.17 0.55], ...
        'FontSize', 9, 'BackgroundColor', C.white, ...
        'Callback', @cb_apply_filter);

    % --- Column 3: Gamma Slider ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- GAMMA --', 'Units', 'normalized', ...
        'Position', [0.29 0.72 0.10 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, 'HorizontalAlignment', 'center');

    lblGammaVal = uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Gamma: 1.0', 'Units', 'normalized', ...
        'Position', [0.29 0.52 0.10 0.16], 'FontSize', 8, ...
        'BackgroundColor', C.white, 'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'center');

    sliderGamma = uicontrol('Parent', pnlControl, 'Style', 'slider', ...
        'Min', 0.1, 'Max', 4.0, 'Value', 1.0, ...
        'Units', 'normalized', 'Position', [0.29 0.10 0.10 0.38], ...
        'TooltipString', 'Correction Gamma (0.1 - 4.0)', ...
        'Callback', @cb_slider_changed);

    % --- Column 4: Brightness Slider ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- LUMINOSITE --', 'Units', 'normalized', ...
        'Position', [0.40 0.72 0.10 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, 'HorizontalAlignment', 'center');

    lblBrightVal = uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Delta: 0', 'Units', 'normalized', ...
        'Position', [0.40 0.52 0.10 0.16], 'FontSize', 8, ...
        'BackgroundColor', C.white, 'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'center');

    sliderBright = uicontrol('Parent', pnlControl, 'Style', 'slider', ...
        'Min', -100, 'Max', 100, 'Value', 0, ...
        'Units', 'normalized', 'Position', [0.40 0.10 0.10 0.38], ...
        'TooltipString', 'Ajustement luminosite (-100 a +100)', ...
        'Callback', @cb_slider_changed);

    % --- Column 5: Contrast Slider ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- CONTRASTE --', 'Units', 'normalized', ...
        'Position', [0.51 0.72 0.10 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, 'HorizontalAlignment', 'center');

    lblContrastVal = uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Alpha: 1.0', 'Units', 'normalized', ...
        'Position', [0.51 0.52 0.10 0.16], 'FontSize', 8, ...
        'BackgroundColor', C.white, 'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'center');

    sliderContrast = uicontrol('Parent', pnlControl, 'Style', 'slider', ...
        'Min', 0.1, 'Max', 4.0, 'Value', 1.0, ...
        'Units', 'normalized', 'Position', [0.51 0.10 0.10 0.38], ...
        'TooltipString', 'Facteur de contraste (0.1 - 4.0)', ...
        'Callback', @cb_slider_changed);

    % --- Column 6: Threshold Slider ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- SEUIL --', 'Units', 'normalized', ...
        'Position', [0.62 0.72 0.10 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, 'HorizontalAlignment', 'center');

    lblThreshVal = uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Seuil: 128', 'Units', 'normalized', ...
        'Position', [0.62 0.52 0.10 0.16], 'FontSize', 8, ...
        'BackgroundColor', C.white, 'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'center');

    sliderThresh = uicontrol('Parent', pnlControl, 'Style', 'slider', ...
        'Min', 0, 'Max', 255, 'Value', 128, ...
        'Units', 'normalized', 'Position', [0.62 0.10 0.10 0.38], ...
        'TooltipString', 'Seuil de segmentation manuelle (0-255)', ...
        'Callback', @cb_slider_changed);

    % --- Column 7: Save Operations ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- SAUVEGARDE --', 'Units', 'normalized', ...
        'Position', [0.74 0.72 0.12 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, 'HorizontalAlignment', 'center');

    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Format:', 'Units', 'normalized', ...
        'Position', [0.74 0.52 0.05 0.16], 'FontSize', 8, ...
        'BackgroundColor', C.white, 'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'left');

    ddFormat = uicontrol('Parent', pnlControl, 'Style', 'popupmenu', ...
        'String', {'PNG', 'JPEG', 'BMP', 'TIFF'}, ...
        'Units', 'normalized', 'Position', [0.79 0.52 0.07 0.22], ...
        'FontSize', 8, 'BackgroundColor', C.white);

    btnSave = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', '  SAUVER IMAGE', 'Units', 'normalized', ...
        'Position', [0.74 0.28 0.12 0.22], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'BackgroundColor', C.green, 'ForegroundColor', C.white, ...
        'TooltipString', 'Sauvegarder l''image traitee', ...
        'Callback', @cb_save_image); %#ok<NASGU>

    btnSaveHist = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', '  SAUVER HIST.', 'Units', 'normalized', ...
        'Position', [0.74 0.04 0.12 0.22], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'BackgroundColor', C.midPanel, 'ForegroundColor', C.white, ...
        'TooltipString', 'Sauvegarder l''histogramme', ...
        'Callback', @cb_save_histogram); %#ok<NASGU>

    % ---------------------------------------------------------------
    % STATUS BAR (footer)
    % ---------------------------------------------------------------
    uipanel('Parent', fig, 'Units', 'normalized', ...
        'Position', [0 0 1 0.04], ...
        'BackgroundColor', C.mainBlue, 'BorderType', 'none');

    lblStatus = uicontrol('Style', 'text', 'Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [0.01 0.005 0.70 0.028], ...
        'String', '  >> Pret. Chargez une image pour commencer.', ...
        'FontSize', 9, 'ForegroundColor', [0.80 0.90 1.00], ...
        'BackgroundColor', C.mainBlue, 'HorizontalAlignment', 'left');

    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.72 0.005 0.27 0.028], ...
        'String', 'Hamza Labbaalli & Abdelouahed Id-Boubrik  |  IISE 2026', ...
        'FontSize', 8, 'ForegroundColor', [0.60 0.70 0.80], ...
        'BackgroundColor', C.mainBlue, 'HorizontalAlignment', 'right');

% =========================================================================
% [4] CALLBACK FUNCTIONS
% =========================================================================

    % ---------------------------------------------------------------
    function cb_load_image(~, ~)
        [file, path] = uigetfile( ...
            {'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff', ...
             'Images (*.jpg,*.png,*.bmp,*.tif)'}, ...
            'Ouvrir une image');
        if isequal(file, 0), return; end

        util_status(lblStatus, '  >> Chargement en cours...', C.orange);
        drawnow;

        try
            S.original  = imread(fullfile(path, file));
            S.gray      = util_safe_gray(S.original);
            S.processed = S.original;
            S.has_roi   = false;
            S.roi_mask  = [];
            S.filepath  = path;
            S.filename  = file;

            % Show original
            imshow(S.original, 'Parent', axOrig);
            title(axOrig, 'IMAGE ORIGINALE', 'FontSize', 9, 'Color', C.mainBlue, 'FontWeight', 'bold');
            axis(axOrig, 'off');

            % Update info label
            sz = size(S.original);
            if numel(sz) == 3
                info_str = sprintf('%d x %d x %d  |  %s', sz(1), sz(2), sz(3), file);
            else
                info_str = sprintf('%d x %d  (Niveaux de gris)  |  %s', sz(1), sz(2), file);
            end
            set(lblOrigInfo, 'String', info_str);

            % Reset dropdown to original
            set(dropdown, 'Value', 1);
            proc_apply(1);
            util_status(lblStatus, sprintf('  >> Image chargee : %s', file), C.green);

        catch err
            util_status(lblStatus, sprintf('  >> ERREUR chargement : %s', err.message), C.red);
            errordlg(sprintf('Impossible de charger l''image :\n%s', err.message), 'Erreur');
        end
    end

    % ---------------------------------------------------------------
    function cb_reset_image(~, ~)
        if isempty(S.original)
            util_status(lblStatus, '  >> Aucune image chargee.', C.orange);
            return;
        end
        S.has_roi  = false;
        S.roi_mask = [];
        set(dropdown, 'Value', 1);
        set(sliderGamma,    'Value', 1.0);
        set(sliderBright,   'Value', 0);
        set(sliderContrast, 'Value', 1.0);
        set(sliderThresh,   'Value', 128);
        set(lblGammaVal,    'String', 'Gamma: 1.0');
        set(lblBrightVal,   'String', 'Delta: 0');
        set(lblContrastVal, 'String', 'Alpha: 1.0');
        set(lblThreshVal,   'String', 'Seuil: 128');
        proc_apply(1);
        util_status(lblStatus, '  >> Image reinitialisee.', C.accentBlue);
    end

    % ---------------------------------------------------------------
    function cb_apply_filter(~, ~)
        if isempty(S.gray)
            util_status(lblStatus, '  >> Chargez une image d''abord.', C.orange);
            return;
        end
        val = get(dropdown, 'Value');
        proc_apply(val);
    end

    % ---------------------------------------------------------------
    function cb_slider_changed(~, ~)
        if isempty(S.gray), return; end

        g  = get(sliderGamma,    'Value');
        b  = get(sliderBright,   'Value');
        a  = get(sliderContrast, 'Value');
        th = get(sliderThresh,   'Value');

        set(lblGammaVal,    'String', sprintf('Gamma: %.2f', g));
        set(lblBrightVal,   'String', sprintf('Delta: %+.0f', b));
        set(lblContrastVal, 'String', sprintf('Alpha: %.2f', a));
        set(lblThreshVal,   'String', sprintf('Seuil: %.0f', th));

        % Re-apply currently selected filter
        val = get(dropdown, 'Value');
        proc_apply(val);
    end

    % ---------------------------------------------------------------
    function cb_roi_select(~, ~)
        if isempty(S.original)
            util_status(lblStatus, '  >> Chargez une image d''abord.', C.orange);
            return;
        end
        util_status(lblStatus, '  >> Cliquez-glissez un rectangle sur l''image originale...', C.orange);
        drawnow;

        try
            axes(axOrig); %#ok<MAXES>
            % Use ginput for 2 corner points (MATLAB 2013 compatible)
            [x, y] = ginput(2);
            if numel(x) < 2, util_status(lblStatus, '  >> ROI annulee.', C.textGray); return; end

            x1 = max(1, round(min(x)));
            x2 = min(size(S.gray, 2), round(max(x)));
            y1 = max(1, round(min(y)));
            y2 = min(size(S.gray, 1), round(max(y)));

            S.roi_mask = false(size(S.gray));
            S.roi_mask(y1:y2, x1:x2) = true;
            S.has_roi = true;

            % Draw ROI rectangle on original display
            imshow(S.original, 'Parent', axOrig);
            title(axOrig, 'IMAGE ORIGINALE', 'FontSize', 9, 'Color', C.mainBlue, 'FontWeight', 'bold');
            axis(axOrig, 'off');
            hold(axOrig, 'on');
            rectangle('Parent', axOrig, 'Position', [x1 y1 (x2-x1) (y2-y1)], ...
                'EdgeColor', 'yellow', 'LineWidth', 2, 'LineStyle', '--');
            hold(axOrig, 'off');

            util_status(lblStatus, sprintf('  >> ROI definie : [%d,%d] -> [%d,%d]', x1, y1, x2, y2), C.green);
            proc_apply(get(dropdown, 'Value'));

        catch err
            S.has_roi = false;
            util_status(lblStatus, sprintf('  >> Erreur ROI : %s', err.message), C.red);
        end
    end

    % ---------------------------------------------------------------
    function cb_save_image(~, ~)
        if isempty(S.processed)
            util_status(lblStatus, '  >> Aucune image traitee a sauvegarder.', C.orange);
            return;
        end

        fmtIdx   = get(ddFormat, 'Value');
        fmtList  = {'png', 'jpg', 'bmp', 'tif'};
        fmtExts  = {'*.png', '*.jpg', '*.bmp', '*.tif'};
        fmt      = fmtList{fmtIdx};
        ext      = fmtExts{fmtIdx};

        [file, path] = uiputfile(ext, 'Sauvegarder l''image traitee', ...
            ['resultat_traite.' fmt]);
        if isequal(file, 0), return; end

        try
            imwrite(S.processed, fullfile(path, file), fmt);
            util_status(lblStatus, sprintf('  >> Image sauvegardee : %s', file), C.green);
        catch err
            util_status(lblStatus, sprintf('  >> Erreur sauvegarde : %s', err.message), C.red);
            errordlg(err.message, 'Erreur sauvegarde');
        end
    end

    % ---------------------------------------------------------------
    function cb_save_histogram(~, ~)
        if isempty(S.processed)
            util_status(lblStatus, '  >> Aucun histogramme a sauvegarder.', C.orange);
            return;
        end

        [file, path] = uiputfile('*.png', 'Sauvegarder l''histogramme', 'histogramme.png');
        if isequal(file, 0), return; end

        try
            % Render histogram to a temporary figure
            tmpFig = figure('Visible', 'off', 'Color', C.white, ...
                'Position', [100 100 600 400]);
            tmpAx = axes('Parent', tmpFig);
            h_data = S.processed;
            if islogical(h_data), h_data = uint8(h_data) * 255; end
            if ~isa(h_data, 'uint8'), h_data = im2uint8(h_data); end
            imhist(h_data);
            title(tmpAx, 'Histogramme - Image Traitee', 'FontSize', 12);
            xlabel(tmpAx, 'Intensite (0-255)');
            ylabel(tmpAx, 'Nombre de Pixels');
            grid(tmpAx, 'on');
            saveas(tmpFig, fullfile(path, file));
            close(tmpFig);
            util_status(lblStatus, sprintf('  >> Histogramme sauvegarde : %s', file), C.green);
        catch err
            util_status(lblStatus, sprintf('  >> Erreur sauvegarde histogramme : %s', err.message), C.red);
        end
    end

    % ---------------------------------------------------------------
    function cb_close(~, ~)
        delete(fig);
    end

% =========================================================================
% [5] IMAGE PROCESSING ENGINE
% =========================================================================

    % ---------------------------------------------------------------
    % Main dispatcher
    % ---------------------------------------------------------------
    function proc_apply(val)
        if isempty(S.gray), return; end

        S.last_filter = val;
        gamma  = get(sliderGamma,    'Value');
        bright = get(sliderBright,   'Value');
        alpha  = get(sliderContrast, 'Value');
        thresh = get(sliderThresh,   'Value');

        util_status(lblStatus, '  >> Traitement en cours...', C.orange);
        drawnow;

        try
            src = S.gray; % work on grayscale by default

            switch val
                % ---- ORIGINALE ----
                case 1
                    result = S.original;

                % ---- AMELIORATION ----
                case 2
                    % section header - skip
                    result = S.original;
                case 3
                    result = proc_gamma(src, gamma);
                case 4
                    result = proc_brightness(src, bright, alpha);
                case 5
                    result = imadjust(src);
                case 6
                    result = histeq(src);
                case 7
                    result = proc_clahe(src);

                % ---- FILTRAGE ----
                case 8
                    % section header
                    result = S.original;
                case 9
                    result = medfilt2(src, [3 3]);
                case 10
                    result = proc_gaussian_blur(src);
                case 11
                    result = proc_sharpen(src);
                case 12
                    result = proc_laplacian(src);

                % ---- BRUIT ----
                case 13
                    % section header
                    result = S.original;
                case 14
                    result = proc_noise_gaussian(src);
                case 15
                    result = proc_noise_sp(src);

                % ---- CONTOURS ----
                case 16
                    % section header
                    result = S.original;
                case 17
                    result = uint8(255 * double(edge(src, 'sobel')));
                case 18
                    result = uint8(255 * double(edge(src, 'prewitt')));
                case 19
                    result = proc_roberts(src);
                case 20
                    result = proc_canny(src);

                % ---- MORPHOLOGIE ----
                case 21
                    % section header
                    result = S.original;
                case 22
                    result = proc_morphology(src, 'dilate');
                case 23
                    result = proc_morphology(src, 'erode');
                case 24
                    result = proc_morphology(src, 'open');
                case 25
                    result = proc_morphology(src, 'close');

                % ---- SEGMENTATION ----
                case 26
                    % section header
                    result = S.original;
                case 27
                    result = uint8(255 * double(src >= uint8(thresh)));
                case 28
                    level  = graythresh(src);
                    result = uint8(255 * double(im2bw(src, level)));
                case 29
                    d = im2double(src);
                    result = im2uint8(log(1 + d) / log(2));
                case 30
                    d = im2double(src);
                    result = im2uint8((exp(d) - 1) / (exp(1) - 1));

                otherwise
                    result = S.original;
            end

            % Apply ROI mask: blend processed only inside ROI if active
            if S.has_roi && ~isempty(S.roi_mask) && val ~= 1
                mask = S.roi_mask;
                if isa(result, 'logical')
                    result = uint8(result) * 255;
                end
                if ~isa(result, 'uint8')
                    result = im2uint8(result);
                end
                base = S.gray;
                out  = base;
                out(mask) = result(mask);
                result = out;
            end

            S.processed = result;

            % Display
            imshow(S.processed, 'Parent', axProc);
            fnames = get(dropdown, 'String');
            ftitle = strtrim(fnames{val});
            title(axProc, ftitle, 'FontSize', 9, 'Color', C.mainBlue, 'FontWeight', 'bold');
            axis(axProc, 'off');

            % Update proc info label
            if ~isempty(S.processed)
                sz2 = size(S.processed);
                if numel(sz2) >= 3
                    pinfo = sprintf('%d x %d x %d  |  %s', sz2(1), sz2(2), sz2(3), ftitle);
                else
                    pinfo = sprintf('%d x %d  |  %s', sz2(1), sz2(2), ftitle);
                end
                set(lblProcInfo, 'String', pinfo);
            end

            % Update histogram & stats
            h_data = S.processed;
            if islogical(h_data), h_data = uint8(h_data) * 255; end
            if ~isa(h_data, 'uint8')
                h_data = im2uint8(h_data);
            end
            if size(h_data, 3) == 3
                h_data = rgb2gray(h_data);
            end

            axes(axHist); %#ok<MAXES>
            imhist(h_data);
            title(axHist, sprintf('Histogramme - %s', ftitle), 'FontSize', 7, 'Color', C.mainBlue);
            xlabel(axHist, 'Intensite', 'FontSize', 7);
            ylabel(axHist, 'Pixels', 'FontSize', 7);

            st = stats_compute(h_data);
            stats_display(st, lblStats, C);

            util_status(lblStatus, sprintf('  >> Traitement applique : %s', ftitle), C.green);

        catch err
            util_status(lblStatus, sprintf('  >> Erreur : %s', err.message), C.red);
        end
    end

    % ---------------------------------------------------------------
    % Individual processing functions
    % ---------------------------------------------------------------

    function out = proc_gamma(img, g)
        d   = im2double(img);
        out = im2uint8(d .^ g);
    end

    function out = proc_brightness(img, delta, alpha)
        d   = double(img);
        d   = alpha * d + delta;
        out = util_clamp(d);
    end

    function out = proc_clahe(img)
        % Adaptive histogram equalization using local processing
        % MATLAB 2013 compatible (adapthisteq if IPT available, else histeq fallback)
        try
            out = adapthisteq(img, 'NumTiles', [8 8], 'ClipLimit', 0.02);
        catch %#ok<CTCH>
            % Fallback: tile-by-tile histeq
            out = img;
            [rows, cols] = size(img);
            tileR = max(1, floor(rows / 8));
            tileC = max(1, floor(cols / 8));
            for r = 1:tileR:rows
                for c = 1:tileC:cols
                    r2 = min(r + tileR - 1, rows);
                    c2 = min(c + tileC - 1, cols);
                    out(r:r2, c:c2) = histeq(img(r:r2, c:c2));
                end
            end
        end
    end

    function out = proc_gaussian_blur(img)
        % Gaussian blur using fspecial + imfilter
        h   = fspecial('gaussian', [5 5], 1.5);
        out = imfilter(img, h, 'replicate');
    end

    function out = proc_sharpen(img)
        % Unsharp masking sharpening
        h    = fspecial('unsharp', 0.5);
        out  = imfilter(img, h, 'replicate');
        out  = util_clamp(double(out));
    end

    function out = proc_laplacian(img)
        h    = fspecial('laplacian', 0.2);
        lap  = imfilter(double(img), h, 'replicate');
        d    = double(img) - lap;
        out  = util_clamp(d);
    end

    function out = proc_noise_gaussian(img)
        d   = im2double(img);
        d   = d + 0.05 * randn(size(d));
        out = util_clamp(d * 255);
    end

    function out = proc_noise_sp(img)
        d      = img;
        total  = numel(d);
        n_salt = round(0.02 * total);
        % Salt
        idx    = randperm(total, n_salt);
        d(idx) = 255;
        % Pepper
        idx    = randperm(total, n_salt);
        d(idx) = 0;
        out    = d;
    end

    function out = proc_roberts(img)
        Rx   = [1 0; 0 -1];
        Ry   = [0 1; -1 0];
        gx   = imfilter(double(img), Rx, 'replicate');
        gy   = imfilter(double(img), Ry, 'replicate');
        mag  = sqrt(gx.^2 + gy.^2);
        out  = util_clamp(mag);
    end

    function out = proc_canny(img)
        try
            bw  = edge(img, 'canny');
            out = uint8(255 * double(bw));
        catch %#ok<CTCH>
            % Fallback to sobel if canny unavailable
            bw  = edge(img, 'sobel');
            out = uint8(255 * double(bw));
        end
    end

    function out = proc_morphology(img, op)
        se = strel('disk', 3);
        bw = im2bw(img, graythresh(img));
        switch op
            case 'dilate', res = imdilate(bw, se);
            case 'erode',  res = imerode(bw, se);
            case 'open',   res = imopen(bw, se);
            case 'close',  res = imclose(bw, se);
            otherwise,     res = bw;
        end
        out = uint8(res) * 255;
    end

% =========================================================================
% [6] STATISTICS ENGINE
% =========================================================================

    function st = stats_compute(img)
        % img must be grayscale uint8
        st = struct();
        d  = double(img(:));

        st.mean    = mean(d);
        st.std     = std(d);
        st.mn      = min(d);
        st.mx      = max(d);
        st.median  = median(d);
        st.numel   = numel(d);
        sz         = size(img);
        st.rows    = sz(1);
        st.cols    = sz(2);

        % Histogram peak
        counts = histc(d, 0:255); %#ok<HISTC>
        [~, pk_idx] = max(counts);
        st.hist_peak = pk_idx - 1; % 0-based intensity

        % Entropy (manual, MATLAB 2013 compatible)
        p    = counts / sum(counts);
        p    = p(p > 0);
        st.entropy = -sum(p .* log2(p));

        % Dynamic range
        st.dyn_range = st.mx - st.mn;
    end

    function stats_display(st, lbl, colors) %#ok<INUSD>
        if isempty(st)
            set(lbl, 'String', ...
                sprintf(' STATISTIQUES\n ============\n\n Chargez une image\n pour voir les stats.'));
            return;
        end
        txt = sprintf( ...
            ' STATISTIQUES IMAGE\n ==================\n Taille    : %d x %d px\n Pixels    : %d\n\n Moyenne   : %.2f\n Ecart-typ : %.2f\n Mediane   : %.2f\n Min / Max : %d / %d\n Plage dyn : %d\n\n Pic Hist. : %d\n Entropie  : %.4f bits', ...
            st.rows, st.cols, st.numel, ...
            st.mean, st.std, st.median, ...
            st.mn, st.mx, st.dyn_range, ...
            st.hist_peak, st.entropy);
        set(lbl, 'String', txt);
    end

% =========================================================================
% [7] UTILITY FUNCTIONS
% =========================================================================

    function util_status(lbl, msg, color)
        set(lbl, 'String', msg, 'ForegroundColor', color);
        drawnow;
    end

    function g = util_safe_gray(img)
        if size(img, 3) == 3
            g = rgb2gray(img);
        else
            g = img;
        end
        if ~isa(g, 'uint8')
            g = im2uint8(g);
        end
    end

    function out = util_clamp(d)
        out = uint8(min(255, max(0, round(d))));
    end

end % END Projet_TI_IISE_2026_PRO
