function Projet_TI_IISE_2026()
    % --- THEME & COLORS ---
    mainBlue   = [0.05, 0.15, 0.25];  
    accentBlue = [0.00, 0.45, 0.74];  
    saveGreen  = [0.13, 0.55, 0.13];  
    bgColor    = [0.92, 0.94, 0.96];  
    white      = [1, 1, 1];

    % --- ICONS GENERATION (Matrix-based for MATLAB 2013) ---
    % Folder Icon (Load)
    folderIcon = ones(16,16,3); 
    folderIcon(4:12, 2:14, 1) = 1.0; folderIcon(4:12, 2:14, 2) = 0.8; folderIcon(4:12, 2:14, 3) = 0.2; % Yellow
    
    % Disk Icon (Save)
    saveIcon = ones(16,16,3) * 0.9;
    saveIcon(3:13, 3:13, :) = 0.2; % Dark square
    saveIcon(4:6, 5:11, :) = 1.0;  % White label

    % --- WINDOW CONFIGURATION ---
    fig = figure('Name', 'Image Processing Suite - IISE 2026', ...
        'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8], ... 
        'Color', bgColor, 'MenuBar', 'none', 'NumberTitle', 'off', 'Resize', 'on');

    imgData.original = []; imgData.gray = []; imgData.processed = [];

    % --- HEADER ---
    uipanel('Parent', fig, 'Units', 'normalized', 'Position', [0 0.94 1 0.06], ...
        'BackgroundColor', mainBlue, 'BorderType', 'none');
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.02 0.945 0.5 0.04], 'String', ' >> IISE IMAGE ANALYZER PRO', ...
        'FontSize', 12, 'FontWeight', 'bold', 'ForegroundColor', white, 'BackgroundColor', mainBlue, 'HorizontalAlignment', 'left');

    % --- PANELS ---
    pnlImages = uipanel('Parent', fig, 'Title', ' VISUALISATION ', ...
        'Units', 'normalized', 'Position', [0.02 0.28 0.65 0.64], ...
        'BackgroundColor', white, 'FontWeight', 'bold');

    pnlAnalyse = uipanel('Parent', fig, 'Title', ' ANALYSE ', ...
        'Units', 'normalized', 'Position', [0.68 0.28 0.3 0.64], ...
        'BackgroundColor', white, 'FontWeight', 'bold');

    pnlControl = uipanel('Parent', fig, 'Title', ' CONTROLES ', ...
        'Units', 'normalized', 'Position', [0.02 0.08 0.96 0.18], ...
        'BackgroundColor', white, 'FontWeight', 'bold');

    % --- AXES ---
    axOrig = axes('Parent', pnlImages, 'Units', 'normalized', 'Position', [0.05 0.15 0.42 0.75]);
    title('IMAGE ORIGINALE'); axis off;

    axProc = axes('Parent', pnlImages, 'Units', 'normalized', 'Position', [0.53 0.15 0.42 0.75]);
    title('IMAGE TRAITEE'); axis off;

    axHist = axes('Parent', pnlAnalyse, 'Units', 'normalized', 'Position', [0.15 0.5 0.75 0.35]);
    
    lblStats = uicontrol('Parent', pnlAnalyse, 'Style', 'text', ...
        'String', 'Stats : En attente...', 'Units', 'normalized', ...
        'Position', [0.05 0.05 0.9 0.35], 'BackgroundColor', [0.93 0.93 0.93], ...
        'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left');

    % --- CONTROLS ---
    % Load Button with Matrix Icon
    btnLoad = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0.02 0.25 0.15 0.5], ...
        'CData', folderIcon, 'TooltipString', 'Charger une Image', 'Callback', @load_image);
    uicontrol('Parent', pnlControl, 'Style', 'text', 'String', 'CHARGER', ...
        'Units', 'normalized', 'Position', [0.02 0.05 0.15 0.15], 'BackgroundColor', white, 'FontWeight', 'bold');

    % Filter Dropdown
    uicontrol('Style', 'text', 'Parent', pnlControl, 'String', 'FILTRES :', ...
        'Units', 'normalized', 'Position', [0.2 0.6 0.1 0.2], 'BackgroundColor', white, 'FontWeight', 'bold');
    dropdown = uicontrol('Parent', pnlControl, 'Style', 'popupmenu', ...
        'String', {'Originale', 'Correction Gamma', 'Exponentielle', 'Logarithmique', ...
                   'Etirement Lineaire', 'Egalisation Hist.', 'Contours (Sobel)', 'Segmentation (OTSU)'}, ...
        'Units', 'normalized', 'Position', [0.2 0.25 0.2 0.3], 'Callback', @apply_transformation);

    % Gamma Slider
    lblGamma = uicontrol('Parent', pnlControl, 'Style', 'text', 'String', 'Gamma: 1.0', ...
        'Units', 'normalized', 'Position', [0.42 0.6 0.15 0.2], 'BackgroundColor', white, 'Visible', 'off');
    sliderGamma = uicontrol('Parent', pnlControl, 'Style', 'slider', ...
        'Min', 0.1, 'Max', 4.0, 'Value', 1.0, 'Units', 'normalized', ...
        'Position', [0.42 0.3 0.15 0.25], 'Visible', 'off', 'Callback', @apply_transformation);

    % Save Button with Matrix Icon
    btnSave = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0.82 0.25 0.15 0.5], ...
        'CData', saveIcon, 'TooltipString', 'Sauvegarder', 'Callback', @save_image);
    uicontrol('Parent', pnlControl, 'Style', 'text', 'String', 'SAUVEGARDER', ...
        'Units', 'normalized', 'Position', [0.82 0.05 0.15 0.15], 'BackgroundColor', white, 'FontWeight', 'bold');

    % --- FOOTER ---
    uipanel('Parent', fig, 'Units', 'normalized', 'Position', [0 0 1 0.07], ...
        'BackgroundColor', mainBlue, 'BorderType', 'none');
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0 0.015 1 0.04], 'String', 'Hamza Labbaalli & Abdelouahed Id-Boubrik | IISE 2026', ...
        'FontSize', 10, 'ForegroundColor', white, 'BackgroundColor', mainBlue);

    % --- LOGIC FUNCTIONS ---
    function load_image(~, ~)
        [file, path] = uigetfile({'*.jpg;*.png;*.bmp;*.tif'}, 'Ouvrir');
        if isequal(file,0), return; end
        imgData.original = imread(fullfile(path, file));
        imgData.gray = imgData.original;
        if size(imgData.original, 3) == 3, imgData.gray = rgb2gray(imgData.original); end
        imshow(imgData.original, 'Parent', axOrig);
        apply_transformation();
    end

    function apply_transformation(~, ~)
        if isempty(imgData.gray), return; end
        val = get(dropdown, 'Value');
        op = get(dropdown, 'String'); op = op{val};
        
        if val == 2, set(sliderGamma,'Visible','on'); set(lblGamma,'Visible','on');
           g = get(sliderGamma, 'Value'); set(lblGamma, 'String', sprintf('Gamma: %.1f', g));
        else set(sliderGamma,'Visible','off'); set(lblGamma,'Visible','off'); end

        switch val
            case 1, imgData.processed = imgData.original;
            case 2, imgData.processed = imadjust(imgData.gray, [], [], get(sliderGamma, 'Value'));
            case 3, d = im2double(imgData.gray); imgData.processed = im2uint8((exp(d)-1)/(exp(1)-1));
            case 4, d = im2double(imgData.gray); imgData.processed = im2uint8(log(1+d)/log(2));
            case 5, imgData.processed = imadjust(imgData.gray);
            case 6, imgData.processed = histeq(imgData.gray);
            case 7, imgData.processed = edge(imgData.gray, 'sobel');
            case 8, imgData.processed = im2bw(imgData.gray, graythresh(imgData.gray));
        end
        
        imshow(imgData.processed, 'Parent', axProc);
        axes(axHist);
        if islogical(imgData.processed), h = uint8(imgData.processed)*255; else h = imgData.processed; end
        imhist(h);
        set(lblStats, 'String', sprintf(' ANALYSE :\n > Filtre : %s\n > Moyenne : %.1f\n > Ecart-Type : %.1f', op, mean2(h), std2(h)));
    end

    function save_image(~, ~)
        if isempty(imgData.processed), return; end
        [file, path] = uiputfile('resultat.png', 'Sauvegarder');
        if isequal(file,0), return; end
        imwrite(imgData.processed, fullfile(path, file));
    end
end