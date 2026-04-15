function Projet_TI_IISE_2026_PRO()
% =========================================================================
%  IISE IMAGE ANALYZER PRO - ADVANCED EDITION
%  Version : 3.0  (TP7 OTSU + K-Means Complete)
%  Authors : Hamza Labbaalli & Abdelouahed Id-Boubrik | IISE 2026
%  Supervised by : Pr. Y. AIT LAHCEN
%  Compatibility : MATLAB R2013a and later
%  Architecture  : Procedural GUI + Nested Functions (GUIDE-free)
% =========================================================================
%
%  TP7 - Segmentation d'image (OTSU) - Additions:
%    [A] proc_otsu()         -> Full OTSU implementation (steps 1-4 of TP7)
%    [B] proc_kmeans()       -> K-Means clustering (K configurable)
%    [C] cb_otsu_analyse()   -> Dedicated OTSU analysis window
%    [D] stats_display_otsu()-> Stats panel updated with OTSU details
%    [E] K slider added      -> Control number of clusters for K-Means
%
%  MODULE STRUCTURE:
%    [1] Color & Theme Definitions
%    [2] Shared Application State (S struct)
%    [3] UI Construction
%    [4] Event Callbacks
%    [5] Image Processing Engine
%    [6] Statistics Engine
%    [7] Utility Functions

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
    C.purple     = [0.40, 0.10, 0.60];

% =========================================================================
% [2] SHARED APPLICATION STATE
% =========================================================================
    S.original    = [];
    S.gray        = [];
    S.processed   = [];
    S.roi_mask    = [];
    S.has_roi     = false;
    S.last_filter = 1;
    S.filepath    = '';
    S.filename    = '';
    % OTSU results stored for analysis window
    S.otsu        = struct('T', 0, 'T_matlab', 0, 'mu_T', 0, ...
                           'wB', 0, 'wF', 0, 'mB', 0, 'mF', 0, ...
                           'sigma2_max', 0, 'sigma2_curve', [], ...
                           'hist_counts', [], 'probs', []);
    % K-Means results
    S.kmeans      = struct('K', 3, 'centers', [], 'iters', 0, 'labels', []);

% =========================================================================
% [3] UI CONSTRUCTION
% =========================================================================

    % -- MAIN FIGURE --
    fig = figure( ...
        'Name',        'IISE Image Analyzer PRO v3.0', ...
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
        'Position', [0.01 0.952 0.60 0.038], ...
        'String', '  IISE IMAGE ANALYZER PRO  |  v3.0  ', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'ForegroundColor', C.white, 'BackgroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'left');
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.62 0.952 0.37 0.038], ...
        'String', 'Pr. Y. AIT LAHCEN  |  TRAITEMENT D''IMAGE  |  MATLAB 2013+', ...
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

    lblStats = uicontrol('Parent', pnlAnalyse, 'Style', 'text', ...
        'String', '', 'Units', 'normalized', ...
        'Position', [0.04 0.04 0.92 0.50], ...
        'BackgroundColor', C.statBg, ...
        'FontSize', 8, 'FontName', 'Courier New', ...
        'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'left');
    stats_display([], lblStats, C);

    % ---------------------------------------------------------------
    % CONTROLS PANEL (bottom full-width)  -- TP7 extended layout
    % ---------------------------------------------------------------
    pnlControl = uipanel('Parent', fig, 'Title', ' CONTROLES & TRAITEMENTS ', ...
        'Units', 'normalized', 'Position', [0.01 0.04 0.98 0.20], ...
        'BackgroundColor', C.white, 'FontWeight', 'bold', 'FontSize', 10, ...
        'ForegroundColor', C.accentBlue);

    % --- Column 1: File Operations ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- FICHIER --', 'Units', 'normalized', ...
        'Position', [0.005 0.72 0.075 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, ...
        'HorizontalAlignment', 'center');

    btnLoad = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', '  CHARGER', 'Units', 'normalized', ...
        'Position', [0.005 0.50 0.075 0.22], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'BackgroundColor', C.accentBlue, 'ForegroundColor', C.white, ...
        'TooltipString', 'Charger une image (JPG/PNG/BMP/TIF)', ...
        'Callback', @cb_load_image); %#ok<NASGU>

    btnReset = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', '  RESET', 'Units', 'normalized', ...
        'Position', [0.005 0.26 0.075 0.22], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'BackgroundColor', C.orange, 'ForegroundColor', C.white, ...
        'TooltipString', 'Reinitialiser le traitement', ...
        'Callback', @cb_reset_image); %#ok<NASGU>

    btnROI = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', '  ROI', 'Units', 'normalized', ...
        'Position', [0.005 0.02 0.075 0.22], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'BackgroundColor', C.midPanel, 'ForegroundColor', C.white, ...
        'TooltipString', 'Selectionner une region d''interet', ...
        'Callback', @cb_roi_select); %#ok<NASGU>

    % --- Column 2: Filter Selector ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- FILTRE / OPERATION --', 'Units', 'normalized', ...
        'Position', [0.088 0.72 0.16 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
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
        'K-Means (K=2)', ...
        'K-Means (K=3)', ...
        'K-Means (K=4)', ...
        'Logarithmique', ...
        'Exponentielle', ...
    };

    dropdown = uicontrol('Parent', pnlControl, 'Style', 'popupmenu', ...
        'String', filterList, ...
        'Units', 'normalized', 'Position', [0.088 0.08 0.16 0.55], ...
        'FontSize', 8, 'BackgroundColor', C.white, ...
        'Callback', @cb_apply_filter);

    % --- Column 3: TP7 OTSU Analyse Button ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- OTSU Adv --', 'Units', 'normalized', ...
        'Position', [0.258 0.72 0.10 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.purple, ...
        'HorizontalAlignment', 'center');

    btnOtsuAnalyse = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', 'ANALYSER OTSU', 'Units', 'normalized', ...
        'Position', [0.258 0.50 0.10 0.22], ...
        'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.purple, 'ForegroundColor', C.white, ...
        'TooltipString', 'Ouvre la fenetre d''analyse OTSU complete (TP7)', ...
        'Callback', @cb_otsu_analyse); %#ok<NASGU>

    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Histogramme | Variance | Comparaison graythresh', ...
        'Units', 'normalized', ...
        'Position', [0.258 0.28 0.10 0.20], ...
        'FontSize', 7, 'BackgroundColor', C.white, ...
        'ForegroundColor', C.textGray, 'HorizontalAlignment', 'center');

    % --- Column 4: Gamma Slider ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- GAMMA --', 'Units', 'normalized', ...
        'Position', [0.370 0.72 0.09 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, ...
        'HorizontalAlignment', 'center');

    lblGammaVal = uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Gamma: 1.0', 'Units', 'normalized', ...
        'Position', [0.370 0.52 0.09 0.16], 'FontSize', 8, ...
        'BackgroundColor', C.white, 'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'center');

    sliderGamma = uicontrol('Parent', pnlControl, 'Style', 'slider', ...
        'Min', 0.1, 'Max', 4.0, 'Value', 1.0, ...
        'Units', 'normalized', 'Position', [0.370 0.10 0.09 0.38], ...
        'TooltipString', 'Correction Gamma (0.1 - 4.0)', ...
        'Callback', @cb_slider_changed);

    % --- Column 5: Brightness Slider ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- LUMINOSITE --', 'Units', 'normalized', ...
        'Position', [0.468 0.72 0.09 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, ...
        'HorizontalAlignment', 'center');

    lblBrightVal = uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Delta: 0', 'Units', 'normalized', ...
        'Position', [0.468 0.52 0.09 0.16], 'FontSize', 8, ...
        'BackgroundColor', C.white, 'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'center');

    sliderBright = uicontrol('Parent', pnlControl, 'Style', 'slider', ...
        'Min', -100, 'Max', 100, 'Value', 0, ...
        'Units', 'normalized', 'Position', [0.468 0.10 0.09 0.38], ...
        'TooltipString', 'Ajustement luminosite (-100 a +100)', ...
        'Callback', @cb_slider_changed);

    % --- Column 6: Contrast Slider ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- CONTRASTE --', 'Units', 'normalized', ...
        'Position', [0.566 0.72 0.09 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, ...
        'HorizontalAlignment', 'center');

    lblContrastVal = uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Alpha: 1.0', 'Units', 'normalized', ...
        'Position', [0.566 0.52 0.09 0.16], 'FontSize', 8, ...
        'BackgroundColor', C.white, 'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'center');

    sliderContrast = uicontrol('Parent', pnlControl, 'Style', 'slider', ...
        'Min', 0.1, 'Max', 4.0, 'Value', 1.0, ...
        'Units', 'normalized', 'Position', [0.566 0.10 0.09 0.38], ...
        'TooltipString', 'Facteur de contraste (0.1 - 4.0)', ...
        'Callback', @cb_slider_changed);

    % --- Column 7: Threshold Slider ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- SEUIL --', 'Units', 'normalized', ...
        'Position', [0.664 0.72 0.09 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, ...
        'HorizontalAlignment', 'center');

    lblThreshVal = uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Seuil: 128', 'Units', 'normalized', ...
        'Position', [0.664 0.52 0.09 0.16], 'FontSize', 8, ...
        'BackgroundColor', C.white, 'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'center');

    sliderThresh = uicontrol('Parent', pnlControl, 'Style', 'slider', ...
        'Min', 0, 'Max', 255, 'Value', 128, ...
        'Units', 'normalized', 'Position', [0.664 0.10 0.09 0.38], ...
        'TooltipString', 'Seuil de segmentation manuelle (0-255)', ...
        'Callback', @cb_slider_changed);

    % --- Column 8: Save Operations ---
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', '-- SAUVEGARDE --', 'Units', 'normalized', ...
        'Position', [0.762 0.72 0.115 0.18], 'FontSize', 8, 'FontWeight', 'bold', ...
        'BackgroundColor', C.white, 'ForegroundColor', C.accentBlue, ...
        'HorizontalAlignment', 'center');

    uicontrol('Parent', pnlControl, 'Style', 'text', ...
        'String', 'Format:', 'Units', 'normalized', ...
        'Position', [0.762 0.52 0.05 0.16], 'FontSize', 8, ...
        'BackgroundColor', C.white, 'ForegroundColor', C.mainBlue, ...
        'HorizontalAlignment', 'left');

    ddFormat = uicontrol('Parent', pnlControl, 'Style', 'popupmenu', ...
        'String', {'PNG', 'JPEG', 'BMP', 'TIFF'}, ...
        'Units', 'normalized', 'Position', [0.812 0.52 0.065 0.22], ...
        'FontSize', 8, 'BackgroundColor', C.white);

    btnSave = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', '  SAUVER IMAGE', 'Units', 'normalized', ...
        'Position', [0.762 0.28 0.115 0.22], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'BackgroundColor', C.green, 'ForegroundColor', C.white, ...
        'TooltipString', 'Sauvegarder l''image traitee', ...
        'Callback', @cb_save_image); %#ok<NASGU>

    btnSaveHist = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'String', '  SAUVER HIST.', 'Units', 'normalized', ...
        'Position', [0.762 0.04 0.115 0.22], ...
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

            imshow(S.original, 'Parent', axOrig);
            title(axOrig, 'IMAGE ORIGINALE', 'FontSize', 9, 'Color', C.mainBlue, 'FontWeight', 'bold');
            axis(axOrig, 'off');

            sz = size(S.original);
            if numel(sz) == 3
                info_str = sprintf('%d x %d x %d  |  %s', sz(1), sz(2), sz(3), file);
            else
                info_str = sprintf('%d x %d  (Gris)  |  %s', sz(1), sz(2), file);
            end
            set(lblOrigInfo, 'String', info_str);

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
            [x, y] = ginput(2);
            if numel(x) < 2
                util_status(lblStatus, '  >> ROI annulee.', C.textGray);
                return;
            end

            x1 = max(1, round(min(x)));
            x2 = min(size(S.gray, 2), round(max(x)));
            y1 = max(1, round(min(y)));
            y2 = min(size(S.gray, 1), round(max(y)));

            S.roi_mask = false(size(S.gray));
            S.roi_mask(y1:y2, x1:x2) = true;
            S.has_roi = true;

            imshow(S.original, 'Parent', axOrig);
            title(axOrig, 'IMAGE ORIGINALE', 'FontSize', 9, 'Color', C.mainBlue, 'FontWeight', 'bold');
            axis(axOrig, 'off');
            hold(axOrig, 'on');
            rectangle('Parent', axOrig, 'Position', [x1 y1 (x2-x1) (y2-y1)], ...
                'EdgeColor', 'yellow', 'LineWidth', 2, 'LineStyle', '--');
            hold(axOrig, 'off');

            util_status(lblStatus, sprintf('  >> ROI definie : [%d,%d]->[%d,%d]', x1, y1, x2, y2), C.green);
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

        fmtIdx  = get(ddFormat, 'Value');
        fmtList = {'png', 'jpg', 'bmp', 'tif'};
        fmtExts = {'*.png', '*.jpg', '*.bmp', '*.tif'};
        fmt     = fmtList{fmtIdx};
        ext     = fmtExts{fmtIdx};

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
            tmpFig = figure('Visible', 'off', 'Color', C.white, 'Position', [100 100 600 400]);
            tmpAx  = axes('Parent', tmpFig);
            h_data = S.processed;
            if islogical(h_data), h_data = uint8(h_data) * 255; end
            if ~isa(h_data, 'uint8'), h_data = im2uint8(h_data); end
            if size(h_data,3) == 3, h_data = rgb2gray(h_data); end
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
    % TP7: OTSU ANALYSIS WINDOW
    % Opens a dedicated figure showing:
    %   - Original image
    %   - Segmented image (OTSU result)
    %   - Histogram with threshold line
    %   - Inter-class variance curve sigma^2(T)
    %   - Comparison with MATLAB graythresh
    % ---------------------------------------------------------------
    function cb_otsu_analyse(~, ~)
        if isempty(S.gray)
            util_status(lblStatus, '  >> Chargez une image d''abord.', C.orange);
            return;
        end

        util_status(lblStatus, '  >> Calcul OTSU en cours...', C.orange);
        drawnow;

        % Run full OTSU to ensure S.otsu is populated
        [seg_result, otsu_data] = proc_otsu(S.gray);
        S.otsu = otsu_data;

        % ---- Build analysis figure ----
        aFig = figure('Name', 'OTSU Complete', ...
            'Color', C.bgLight, ...
            'Position', [80, 60, 1100, 700], ...
            'MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off');

        % Title banner
        uicontrol('Style', 'text', 'Parent', aFig, ...
            'Units', 'normalized', 'Position', [0 0.94 1 0.06], ...
            'String', '  OTSU  |  Analyse Complete', ...
            'FontSize', 12, 'FontWeight', 'bold', ...
            'ForegroundColor', C.white, 'BackgroundColor', C.mainBlue, ...
            'HorizontalAlignment', 'left');

        % -- Axes 1: Original image --
        ax1 = axes('Parent', aFig, 'Units', 'normalized', 'Position', [0.03 0.52 0.21 0.38]);
        imshow(S.gray, 'Parent', ax1);
        title(ax1, sprintf('Image Segmentee (T=%d)', S.otsu.T), ...
            'FontSize', 9, 'Color', C.purple, 'FontWeight', 'bold');
        axis(ax1, 'off');

        % -- Axes 3: Histogram with threshold line --
        ax3 = axes('Parent', aFig, 'Units', 'normalized', 'Position', [0.03 0.08 0.28 0.36]);
        bar(ax3, 0:255, S.otsu.hist_counts, 'FaceColor', [0.3 0.6 0.9], 'EdgeColor', 'none');
        hold(ax3, 'on');
        ymax = max(S.otsu.hist_counts) * 1.05;
        plot(ax3, [S.otsu.T S.otsu.T], [0 ymax], 'r-', 'LineWidth', 2);
        hold(ax3, 'off');
        title(ax3, sprintf('Histogramme  (T_{OTSU}=%d  |  T_{graythresh}=%d)', ...
            S.otsu.T, S.otsu.T_matlab), 'FontSize', 8, 'Color', C.mainBlue);
        xlabel(ax3, 'Niveau de gris', 'FontSize', 8);
        ylabel(ax3, 'Nombre de pixels', 'FontSize', 8);
        legend(ax3, 'Histogramme', sprintf('Seuil T=%d', S.otsu.T), ...
            'Location', 'NorthEast', 'FontSize', 7);
        grid(ax3, 'on');

        % -- Axes 4: Inter-class variance curve --
        ax4 = axes('Parent', aFig, 'Units', 'normalized', 'Position', [0.37 0.08 0.28 0.36]);
        plot(ax4, 0:255, S.otsu.sigma2_curve, 'b-', 'LineWidth', 1.5);
        hold(ax4, 'on');
        plot(ax4, S.otsu.T, S.otsu.sigma2_max, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        hold(ax4, 'off');
        title(ax4, 'Variance inter-classes \sigma^2(T)', 'FontSize', 9, 'Color', C.mainBlue);
        xlabel(ax4, 'Seuil T', 'FontSize', 8);
        ylabel(ax4, '\sigma^2', 'FontSize', 8);
        legend(ax4, '\sigma^2(T)', sprintf('Max: T=%d', S.otsu.T), ...
            'Location', 'NorthEast', 'FontSize', 7);
        grid(ax4, 'on');

        % -- Statistics text box --
        match_str = 'NON';
        if S.otsu.T == S.otsu.T_matlab
            match_str = 'OUI';
        end

        stat_txt = sprintf( ...
            ['  ALGORITHME OTSU - RESULTATS\n'...
             '  ==============================\n'...
             '  Etape 1 : Histogramme calcule\n'...
             '  Etape 2 : Probabilites p(i) calculees\n'...
             '  Etape 3 : Variance inter-classes sigma2(T)\n\n'...
             '  Moyenne globale mu_T  : %.4f\n'...
             '  Seuil optimal T*      : %d\n'...
             '  Poids fond    wB      : %.4f\n'...
             '  Poids objet   wF      : %.4f\n'...
             '  Moyenne fond  mB      : %.4f\n'...
             '  Moyenne objet mF      : %.4f\n'...
             '  sigma2 max            : %.2f\n\n'...
             '  --- Comparaison TP7 ---\n'...
             '  Notre OTSU     T*     : %d\n'...
             '  MATLAB graythresh T   : %d\n'...
             '  Correspondance        : %s\n'...
             '  Difference            : %d niveaux'], ...
            S.otsu.mu_T, S.otsu.T, ...
            S.otsu.wB, S.otsu.wF, ...
            S.otsu.mB, S.otsu.mF, ...
            S.otsu.sigma2_max, ...
            S.otsu.T, S.otsu.T_matlab, match_str, ...
            abs(S.otsu.T - S.otsu.T_matlab));

        uicontrol('Style', 'text', 'Parent', aFig, ...
            'Units', 'normalized', 'Position', [0.68 0.08 0.30 0.84], ...
            'String', stat_txt, ...
            'FontSize', 9, 'FontName', 'Courier New', ...
            'BackgroundColor', C.statBg, ...
            'ForegroundColor', C.mainBlue, ...
            'HorizontalAlignment', 'left');

        % -- Axes 5: Probability distribution p(i) --
        ax5 = axes('Parent', aFig, 'Units', 'normalized', 'Position', [0.37 0.52 0.28 0.38]);
        stem(ax5, 0:255, S.otsu.probs, 'Marker', 'none', 'Color', [0.1 0.5 0.2]);
        hold(ax5, 'on');
        plot(ax5, [S.otsu.T S.otsu.T], [0 max(S.otsu.probs)*1.05], 'r-', 'LineWidth', 2);
        hold(ax5, 'off');
        title(ax5, 'Probabilites p(i) par niveau de gris', 'FontSize', 9, 'Color', C.mainBlue);
        xlabel(ax5, 'Niveau de gris i', 'FontSize', 8);
        ylabel(ax5, 'p(i)', 'FontSize', 8);
        grid(ax5, 'on');

        util_status(lblStatus, sprintf('  >> Analyse OTSU complete. T*=%d, graythresh=%d', ...
            S.otsu.T, S.otsu.T_matlab), C.purple);
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
            src = S.gray;

            switch val
                % ---- ORIGINALE ----
                case 1
                    result = S.original;

                % ---- AMELIORATION ----
                case 2
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
                    result = S.original;
                case 14
                    result = proc_noise_gaussian(src);
                case 15
                    result = proc_noise_sp(src);

                % ---- CONTOURS ----
                case 16
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
                    result = S.original;

                case 27  % Seuillage Manuel
                    result = uint8(255 * double(src >= uint8(thresh)));

                case 28  % OTSU (Auto) - Full TP7 implementation
                    [result, otsu_data] = proc_otsu(src);
                    S.otsu = otsu_data;

                case 29  % K-Means K=2
                    [result, km_data] = proc_kmeans(src, 2);
                    S.kmeans = km_data;

                case 30  % K-Means K=3
                    [result, km_data] = proc_kmeans(src, 3);
                    S.kmeans = km_data;

                case 31  % K-Means K=4
                    [result, km_data] = proc_kmeans(src, 4);
                    S.kmeans = km_data;

                case 32  % Logarithmique
                    d = im2double(src);
                    result = im2uint8(log(1 + d) / log(2));

                case 33  % Exponentielle
                    d = im2double(src);
                    result = im2uint8((exp(d) - 1) / (exp(1) - 1));

                otherwise
                    result = S.original;
            end

            % Apply ROI mask if active
            if S.has_roi && ~isempty(S.roi_mask) && val ~= 1
                if isa(result, 'logical')
                    result = uint8(result) * 255;
                end
                if ~isa(result, 'uint8')
                    result = im2uint8(result);
                end
                base     = S.gray;
                out      = base;
                out(S.roi_mask) = result(S.roi_mask);
                result = out;
            end

            S.processed = result;

            % Display processed image
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
            if ~isa(h_data, 'uint8'), h_data = im2uint8(h_data); end
            if size(h_data, 3) == 3, h_data = rgb2gray(h_data); end

            axes(axHist); %#ok<MAXES>
            imhist(h_data);
            title(axHist, sprintf('Histogramme - %s', ftitle), 'FontSize', 7, 'Color', C.mainBlue);
            xlabel(axHist, 'Intensite', 'FontSize', 7);
            ylabel(axHist, 'Pixels', 'FontSize', 7);

            % Draw threshold line on histogram for OTSU
            if val == 28
                hold(axHist, 'on');
                yl = get(axHist, 'YLim');
                plot(axHist, [S.otsu.T S.otsu.T], yl, 'r-', 'LineWidth', 1.5);
                hold(axHist, 'off');
            end

            % Compute and display stats
            st = stats_compute(h_data);

            % Augment stats with OTSU info if applicable
            if val == 28
                stats_display_otsu(st, S.otsu, lblStats);
            elseif val == 29 || val == 30 || val == 31
                stats_display_kmeans(st, S.kmeans, lblStats);
            else
                stats_display(st, lblStats, C);
            end

            util_status(lblStatus, sprintf('  >> Traitement applique : %s', ftitle), C.green);

        catch err
            util_status(lblStatus, sprintf('  >> Erreur : %s', err.message), C.red);
        end
    end

    % ---------------------------------------------------------------
    % TP7 - OTSU Algorithm (Full implementation, Steps 1-4)
    %
    %  Step 1: Compute histogram -> hist_counts(i), i=0..255
    %  Step 2: Compute probabilities p(i) = hist_counts(i) / N
    %          Compute global mean mu_T = sum(i * p(i))
    %  Step 3: For each T in [0,255]:
    %            wB(T) = sum(p(i), i=0..T)        -- background weight
    %            wF(T) = sum(p(i), i=T+1..255)    -- foreground weight
    %            mB(T) = sum(i*p(i), i=0..T)/wB   -- background mean
    %            mF(T) = sum(i*p(i), i=T+1..255)/wF
    %            sigma2(T) = wB * wF * (mB - mF)^2
    %  Step 4: T* = argmax sigma2(T)
    %          Apply binary segmentation: result(x,y) = 255 if I>=T*, else 0
    %          Compare with MATLAB graythresh
    % ---------------------------------------------------------------
    function [result, od] = proc_otsu(img)
        % img: uint8 grayscale
        N = numel(img);
        d = double(img(:));

        % Step 1: Histogram (256 bins, values 0-255)
        hist_counts = histc(d, 0:255); %#ok<HISTC>
        hist_counts = hist_counts(:)';  % row vector, length 256

        % Step 2: Probabilities and global mean
        p    = hist_counts / N;         % p(i), i=0..255
        i_vec = 0:255;
        mu_T = sum(i_vec .* p);         % global mean

        % Step 3: Inter-class variance for each T
        sigma2 = zeros(1, 256);

        for T = 0:255
            idx_B = 1:(T+1);      % indices for i=0..T  (1-based)
            idx_F = (T+2):256;    % indices for i=T+1..255

            wB = sum(p(idx_B));
            wF = sum(p(idx_F));

            if wB < 1e-10 || wF < 1e-10
                sigma2(T+1) = 0;
                continue;
            end

            mB = sum(i_vec(idx_B) .* p(idx_B)) / wB;
            mF = sum(i_vec(idx_F) .* p(idx_F)) / wF;

            sigma2(T+1) = wB * wF * (mB - mF)^2;
        end

        % Step 4: Optimal threshold
        [sigma2_max, T_idx] = max(sigma2);
        T_opt = T_idx - 1;  % convert back to 0-based

        % Values at optimal T
        idx_B_opt = 1:(T_opt+1);
        idx_F_opt = (T_opt+2):256;
        wB_opt = sum(p(idx_B_opt));
        wF_opt = sum(p(idx_F_opt));
        if wB_opt > 1e-10
            mB_opt = sum(i_vec(idx_B_opt) .* p(idx_B_opt)) / wB_opt;
        else
            mB_opt = 0;
        end
        if wF_opt > 1e-10
            mF_opt = sum(i_vec(idx_F_opt) .* p(idx_F_opt)) / wF_opt;
        else
            mF_opt = 0;
        end

        % Comparison with MATLAB graythresh (returns normalized [0,1])
        T_matlab = round(graythresh(img) * 255);

        % Apply segmentation: pixels >= T_opt -> 255, else 0
        result = uint8(255 * double(img >= uint8(T_opt)));

        % Pack output struct
        od.T           = T_opt;
        od.T_matlab    = T_matlab;
        od.mu_T        = mu_T;
        od.wB          = wB_opt;
        od.wF          = wF_opt;
        od.mB          = mB_opt;
        od.mF          = mF_opt;
        od.sigma2_max  = sigma2_max;
        od.sigma2_curve= sigma2;
        od.hist_counts = hist_counts;
        od.probs       = p;
    end

    % ---------------------------------------------------------------
    % K-MEANS on grayscale image
    %   - Pixels treated as 1D intensity values
    %   - K centroids, random init, max 100 iterations
    %   - Returns label image scaled to uint8 (cluster levels)
    % ---------------------------------------------------------------
    function [result, km] = proc_kmeans(img, K)
        d = double(img(:));
        N = numel(d);

        % Random initialization: pick K unique pixel values as centers
        rand_idx  = randperm(N, K);
        centers   = sort(d(rand_idx));

        labels    = zeros(N, 1);
        max_iter  = 100;
        iters     = 0;

        for iter = 1:max_iter
            iters = iter;

            % Assignment step: assign each pixel to nearest center
            new_labels = zeros(N, 1);
            for n = 1:N
                dists = (d(n) - centers).^2;
                [~, best] = min(dists);
                new_labels(n) = best;
            end

            % Update step: recompute centers
            new_centers = zeros(K, 1);
            for k = 1:K
                members = d(new_labels == k);
                if ~isempty(members)
                    new_centers(k) = mean(members);
                else
                    new_centers(k) = centers(k); % keep old if empty
                end
            end

            % Check convergence
            if max(abs(new_centers - centers)) < 0.5
                labels  = new_labels;
                centers = new_centers;
                break;
            end

            labels  = new_labels;
            centers = new_centers;
        end

        % Map cluster labels to evenly spaced gray levels
        level_map = round(linspace(0, 255, K));
        out = zeros(N, 1);
        for k = 1:K
            out(labels == k) = level_map(k);
        end
        result = uint8(reshape(out, size(img)));

        % Pack output
        km.K       = K;
        km.centers = centers;
        km.iters   = iters;
        km.labels  = labels;
    end

    % ---------------------------------------------------------------
    % Individual processing functions (unchanged from v2.0)
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
        try
            out = adapthisteq(img, 'NumTiles', [8 8], 'ClipLimit', 0.02);
        catch %#ok<CTCH>
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
        h   = fspecial('gaussian', [5 5], 1.5);
        out = imfilter(img, h, 'replicate');
    end

    function out = proc_sharpen(img)
        h   = fspecial('unsharp', 0.5);
        out = imfilter(img, h, 'replicate');
        out = util_clamp(double(out));
    end

    function out = proc_laplacian(img)
        h   = fspecial('laplacian', 0.2);
        lap = imfilter(double(img), h, 'replicate');
        d   = double(img) - lap;
        out = util_clamp(d);
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
        idx    = randperm(total, n_salt);
        d(idx) = 255;
        idx    = randperm(total, n_salt);
        d(idx) = 0;
        out    = d;
    end

    function out = proc_roberts(img)
        Rx  = [1 0; 0 -1];
        Ry  = [0 1; -1 0];
        gx  = imfilter(double(img), Rx, 'replicate');
        gy  = imfilter(double(img), Ry, 'replicate');
        mag = sqrt(gx.^2 + gy.^2);
        out = util_clamp(mag);
    end

    function out = proc_canny(img)
        try
            bw  = edge(img, 'canny');
            out = uint8(255 * double(bw));
        catch %#ok<CTCH>
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

        counts = histc(d, 0:255); %#ok<HISTC>
        [~, pk_idx] = max(counts);
        st.hist_peak = pk_idx - 1;

        p    = counts / sum(counts);
        p    = p(p > 0);
        st.entropy  = -sum(p .* log2(p));
        st.dyn_range = st.mx - st.mn;
    end

    function stats_display(st, lbl, colors) %#ok<INUSD>
        if isempty(st)
            set(lbl, 'String', ...
                sprintf(' STATISTIQUES\n ============\n\n Chargez une image\n pour voir les stats.'));
            return;
        end
        txt = sprintf( ...
            [' STATISTIQUES IMAGE\n ==================\n'...
             ' Taille    : %d x %d px\n'...
             ' Pixels    : %d\n\n'...
             ' Moyenne   : %.2f\n'...
             ' Ecart-typ : %.2f\n'...
             ' Mediane   : %.2f\n'...
             ' Min / Max : %d / %d\n'...
             ' Plage dyn : %d\n\n'...
             ' Pic Hist. : %d\n'...
             ' Entropie  : %.4f bits'], ...
            st.rows, st.cols, st.numel, ...
            st.mean, st.std, st.median, ...
            st.mn, st.mx, st.dyn_range, ...
            st.hist_peak, st.entropy);
        set(lbl, 'String', txt);
    end

    % ---------------------------------------------------------------
    % Stats display for OTSU result (TP7)
    % ---------------------------------------------------------------
    function stats_display_otsu(st, od, lbl)
        match_str = 'NON';
        if od.T == od.T_matlab
            match_str = 'OUI ✓';
        end
        txt = sprintf( ...
            [' OTSU - STATISTIQUES\n ====================\n'...
             ' Taille   : %d x %d px\n\n'...
             ' [TP7 OTSU]\n'...
             ' mu_T      : %.3f\n'...
             ' T* (OTSU) : %d\n'...
             ' wB / wF   : %.3f / %.3f\n'...
             ' mB / mF   : %.2f / %.2f\n'...
             ' sigma2max : %.2f\n\n'...
             ' [COMPARAISON]\n'...
             ' graythresh: %d\n'...
             ' Notre T*  : %d\n'...
             ' Match     : %s\n'...
             ' Delta T   : %d\n\n'...
             ' Entropie  : %.4f bits'], ...
            st.rows, st.cols, ...
            od.mu_T, od.T, ...
            od.wB, od.wF, ...
            od.mB, od.mF, ...
            od.sigma2_max, ...
            od.T_matlab, od.T, match_str, abs(od.T - od.T_matlab), ...
            st.entropy);
        set(lbl, 'String', txt);
    end

    % ---------------------------------------------------------------
    % Stats display for K-Means result
    % ---------------------------------------------------------------
    function stats_display_kmeans(st, km, lbl)
        centers_str = '';
        for k = 1:km.K
            centers_str = sprintf('%s  C%d: %.1f\n', centers_str, k, km.centers(k));
        end
        txt = sprintf( ...
            [' K-MEANS - STATISTIQUES\n ========================\n'...
             ' Taille   : %d x %d px\n\n'...
             ' K         : %d clusters\n'...
             ' Iterations: %d\n\n'...
             ' Centres:\n%s\n'...
             ' Entropie  : %.4f bits'], ...
            st.rows, st.cols, ...
            km.K, km.iters, ...
            centers_str, st.entropy);
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
