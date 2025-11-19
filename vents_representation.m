function animerVents()
    %% 1. Initialisation et Configuration
    dataFolderPath = 'C:\Users\Jean\Desktop\Ecole Centrale Lyon\WEEX Eolien ECL\2010\'; 
    rows = 'A':'L';
    cols = 1:19;
    numRows = length(rows);
    numCols = length(cols);
    Dates = (datetime(2010, 1, 1):days(1):datetime(2010, 12, 31))';
    numDays = length(Dates);
    
    U = NaN(numRows, numCols, numDays);
    V = NaN(numRows, numCols, numDays);
    
    %% 2. Chargement et Traitement des Données
    
    fprintf('Début du chargement des données...\n');
    % ... (Toute la section de chargement des données reste identique) ...
    for r = 1:numRows
        for c = 1:numCols
            rowChar = rows(r);
            colStr = sprintf('%02d', c); 
            fileName = sprintf('%s%c_2010.txt', colStr, rowChar);
            filePath = fullfile(dataFolderPath, fileName);
            
            try
                T = readtable(filePath);
                T.Properties.VariableNames = {'Day','Month','Year','Velocity','Direction'};
                
                T.Velocity(T.Velocity < 0) = 0;
                
                dir_rad = deg2rad(90 - T.Direction);
                u_comp = T.Velocity .* cos(dir_rad);
                v_comp = T.Velocity .* sin(dir_rad);
                
                dnum = datenum(T.Year, T.Month, T.Day);
                startOfYear = datenum(T.Year, 1, 1);
                jour_idx_vect = dnum - startOfYear + 1; 
                
                for i = 1:height(T)
                    jour_idx = jour_idx_vect(i);
                    U(r, c, jour_idx) = u_comp(i);
                    V(r, c, jour_idx) = v_comp(i);
                end
            catch ME
                if ~strcmp(ME.identifier, 'MATLAB:readtable:FailedToOpenFile')
                    warning('Problème avec le fichier %s: %s', fileName, ME.message);
                end
            end
        end
        fprintf('Ligne %c/%c traitée.\n', rows(r), rows(end));
    end
    fprintf('Chargement des données terminé.\n');
    
    % --- Section de pré-calcul (identique) ---
    Magnitude = sqrt(U.^2 + V.^2);
    maxVel = prctile(Magnitude(:), 99);
    minVel = 0;
    
    % --- NOUVEAU : Facteur d'échelle pour les vecteurs ---
    % Nous fixons l'échelle manuellement pour que les flèches aient une 
    % taille cohérente tout au long de l'animation.
    % '1.0' signifie que la flèche pour 'maxVel' aura une longueur de 1 case.
    scaling_factor = 1.0 / maxVel;
    if isinf(scaling_factor) % Éviter la division par zéro si maxVel est 0
        scaling_factor = 0;
    end

    %% 3. Moyenne des vents (affichage fixe)
    fprintf('Calcul des moyennes annuelles...\n');
    
    % Moyenne des composantes U et V sur l'année (en ignorant les NaN)
    U_mean = mean(U, 3, 'omitnan');
    V_mean = mean(V, 3, 'omitnan');
    
    % Magnitude moyenne
    Mag_mean = sqrt(U_mean.^2 + V_mean.^2);
    
    % Direction moyenne (optionnel : angle en degrés)
    Dir_mean = atan2(V_mean, U_mean);  % en radians
    Dir_mean_deg = mod(rad2deg(Dir_mean), 360);
    
    % --- Figure des moyennes ---
    figure('Name','Moyenne annuelle des vents','WindowState','maximized');
    ax2 = gca;
    
    [X,Y] = meshgrid(cols, 1:numRows);
    
    % quiver(ax2, X, Y, U_mean, V_mean, 'AutoScale','on','LineWidth',1.5);
    % axis(ax2,'equal');
    % set(ax2,'YDir','reverse');
    % set(ax2,'YTick',1:numRows,'YTickLabel',cellstr(rows'));
    % set(ax2,'XTick',1:numCols);
    % title(ax2, 'Moyenne annuelle des vents - Île de Centrosus');
    % grid(ax2,'on');
    
    % Colormap basée sur la magnitude moyenne
    hold(ax2,'on');
    cmap = colormap(ax2,'jet');
    caxis(ax2,[0 20]);
    hC = colorbar(ax2);
    ylabel(hC,'Vitesse moyenne (m/s)');
    
    % Affichage optionnel d'un champ couleurs
    % scatter(ax2, X(:), Y(:), 40, Mag_mean(:), 'filled');
    % Fond coloré : magnitude moyenne
% hold(ax2, 'on');
% 
% n = 256;  % nombre de couleurs
% 
% baseColors = [
%     1.0 1.0 1.0   % blanc
%     1.0 0.0 0.0   % rouge
% ];
% 
% % Interpolation fine
% cmap = interp1(linspace(0,1,size(baseColors,1)), baseColors, linspace(0,1,n));
% 
% % Utilisation :
% colormap(cmap);
% colorbar;
% 
% 
% % Affichage du fond (interpolé)
% hImg = imagesc(ax2, Mag_mean);
% set(hImg, 'XData', cols, 'YData', 1:numRows);  % Positionnement correct
% 
% caxis(ax2, [5 15]);
% 
% % Colorbar
% hC = colorbar(ax2);
% ylabel(hC, 'Vitesse moyenne (m/s)');
% 
% uistack(hImg, 'bottom');  % met le fond sous les flèches
% 
% hold(ax2, 'off');
% 
% 
%     hold(ax2,'off');
% 
%     fprintf('Affichage des moyennes terminé.\n');



   %% 5. Moyenne annuelle des vents – trois cas : <10, 10-20, >20 m/s

    fprintf('Calcul des moyennes annuelles des vents...\n');
    
    speed_classes = { ...
        [0 10],  'vents faibles (< 10 m/s)'; ...
        [10 20], 'vents moyens (10–20 m/s)'; ...
        [20 inf], 'vents forts (> 20 m/s)' ...
    };
    
    [X,Y] = meshgrid(cols, 1:numRows);
    
    for k = 1:3
        speed_min = speed_classes{k,1}(1);
        speed_max = speed_classes{k,1}(2);
        title_text = speed_classes{k,2};
    
        % Magnitude totale
        Mag = sqrt(U.^2 + V.^2);
    
        % masque vitesse
        mask = (Mag >= speed_min) & (Mag < speed_max);
    
        % Calculs sur la 3e dimension
        U_mean = sum(U .* mask, 3, "omitnan") ./ sum(mask, 3, "omitnan");
        V_mean = sum(V .* mask, 3, "omitnan") ./ sum(mask, 3, "omitnan");
        Mag_mean = sqrt(U_mean.^2 + V_mean.^2);
    
        figure('Name', title_text, 'WindowState','maximized');
        ax2 = gca;
    
        % Quiver
        % quiver(ax2, X, Y, U_mean, V_mean, 'AutoScale','on','LineWidth',1.4);
        % axis(ax2,'equal');
        % set(ax2,'YDir','reverse');
        % set(ax2,'YTick',1:numRows,'YTickLabel',cellstr(rows'));
        % set(ax2,'XTick',1:numCols);
        % grid(ax2,'on');
        % hold(ax2,'on');
        % 
        % Fond coloré
    %     n = 256;
    %     baseColors = [1 1 1; 1 0 0];
    %     cmap = interp1(linspace(0,1,2), baseColors, linspace(0,1,n));
    % 
    %     colormap(ax2, cmap);
    %     hImg = imagesc(ax2, Mag_mean);
    %     set(hImg,'XData',cols,'YData',1:numRows);
    %     uistack(hImg, 'bottom');
    %     caxis(ax2, [min(Mag_mean(:), [], 'omitnan') , max(Mag_mean(:), [], 'omitnan')]);
    % 
    %     hC = colorbar(ax2);
    %     ylabel(hC,'Vitesse moyenne (m/s)');
    % 
    %     title(ax2, ['Moyenne annuelle des vents – ' title_text ' – Île de Centrosus']);
    % 
    %     hold(ax2,'off');
    % end
    % 
    % fprintf('Affichage des moyennes terminé.\n');
%% 6.Moyenne des vents écrétés (affichage fixe)

%  Prétraitement des données de vent (seuillage journalier)

    fprintf('Prétraitement des données de vent...\n');
    
    % Seuillage inférieur et supérieur
    U(U < 3)  = 0;
    U(U > 15) = 15;
    
    V(V < 3)  = 0;
    V(V > 15) = 15;
    
    fprintf('Prétraitement terminé.\n');

    fprintf('Calcul des moyennes annuelles...\n');
    
    % Moyenne des composantes U et V sur l'année (en ignorant les NaN)
    U_mean = mean(U, 3, 'omitnan');
    V_mean = mean(V, 3, 'omitnan');
    
    % Magnitude moyenne
    Mag_mean = sqrt(U_mean.^2 + V_mean.^2);
    
    % Direction moyenne (optionnel : angle en degrés)
    Dir_mean = atan2(V_mean, U_mean);  % en radians
    Dir_mean_deg = mod(rad2deg(Dir_mean), 360);
    
    % --- Figure des moyennes ---
    figure('Name','Moyenne annuelle des vents','WindowState','maximized');
    ax2 = gca;
    
    [X,Y] = meshgrid(cols, 1:numRows);
    
    quiver(ax2, X, Y, U_mean, V_mean, 'AutoScale','on','LineWidth',1.5);
    axis(ax2,'equal');
    set(ax2,'YDir','reverse');
    set(ax2,'YTick',1:numRows,'YTickLabel',cellstr(rows'));
    set(ax2,'XTick',1:numCols);
    title(ax2, 'Moyenne annuelle des vents écrétés - Île de Centrosus');
    grid(ax2,'on');
    
    % Colormap basée sur la magnitude moyenne
    hold(ax2,'on');
    cmap = colormap(ax2,'jet');
    caxis(ax2,[0 20]);
    hC = colorbar(ax2);
    ylabel(hC,'Vitesse moyenne (m/s)');
    
    % Affichage optionnel d'un champ couleurs
    % scatter(ax2, X(:), Y(:), 40, Mag_mean(:), 'filled');
    % Fond coloré : magnitude moyenne
    hold(ax2, 'on');
    
    n = 256;  % nombre de couleurs
    
    baseColors = [
        1.0 1.0 1.0   % blanc
        1.0 0.0 0.0   % rouge
    ];
    
    % Interpolation fine
    cmap = interp1(linspace(0,1,size(baseColors,1)), baseColors, linspace(0,1,n));
    
    % Utilisation :
    colormap(cmap);
    colorbar;
    
    
    % Affichage du fond (interpolé)
    hImg = imagesc(ax2, Mag_mean);
    set(hImg, 'XData', cols, 'YData', 1:numRows);  % Positionnement correct
    
    caxis(ax2, [5 15]);
    
    % Colorbar
    hC = colorbar(ax2);
    ylabel(hC, 'Vitesse moyenne (m/s)');
    
    uistack(hImg, 'bottom');  % met le fond sous les flèches
    
    hold(ax2, 'off');


    hold(ax2,'off');

    fprintf('Affichage des moyennes terminé.\n');

    %% 7.Moyenne au cube des vents écrétés, proportionnel à la puissance (affichage fixe)

%  Prétraitement des données de vent (seuillage journalier)

    fprintf('Prétraitement des données de vent...\n');
    
    % Seuillage inférieur et supérieur
    U(U < 3)  = 0;
    U(U > 15) = 15;
    
    V(V < 3)  = 0;
    V(V > 15) = 15;
    
    fprintf('Prétraitement terminé.\n');

    fprintf('Calcul des moyennes annuelles...\n');
    
    % Moyenne des composantes U et V sur l'année (en ignorant les NaN)
    U_mean = mean(U.^3, 3, 'omitnan');
    V_mean = mean(V.^3, 3, 'omitnan');
    
    % Magnitude moyenne
    Mag_mean = sqrt(U_mean.^2 + V_mean.^2);
    
    % Direction moyenne (optionnel : angle en degrés)
    Dir_mean = atan2(V_mean, U_mean);  % en radians
    Dir_mean_deg = mod(rad2deg(Dir_mean), 360);
    
    % --- Figure des moyennes ---
    figure('Name','Moyenne annuelle des vents','WindowState','maximized');
    ax2 = gca;
    
    [X,Y] = meshgrid(cols, 1:numRows);
    
    quiver(ax2, X, Y, U_mean, V_mean, 'AutoScale','on','LineWidth',1.5);
    axis(ax2,'equal');
    set(ax2,'YDir','reverse');
    set(ax2,'YTick',1:numRows,'YTickLabel',cellstr(rows'));
    set(ax2,'XTick',1:numCols);
    title(ax2, 'Moyenne annuelle au cube des vents écrétés - Île de Centrosus');
    grid(ax2,'on');
    
    % Colormap basée sur la magnitude moyenne
    hold(ax2,'on');
    cmap = colormap(ax2,'jet');
    caxis(ax2,[0 20]);
    hC = colorbar(ax2);
    ylabel(hC,'Vitesse moyenne (m/s)');
    
    % Affichage optionnel d'un champ couleurs
    % scatter(ax2, X(:), Y(:), 40, Mag_mean(:), 'filled');
    % Fond coloré : magnitude moyenne
    hold(ax2, 'on');
    
    n = 256;  % nombre de couleurs
    
    baseColors = [
        1.0 1.0 1.0   % blanc
        1.0 0.0 0.0   % rouge
    ];
    
    % Interpolation fine
    cmap = interp1(linspace(0,1,size(baseColors,1)), baseColors, linspace(0,1,n));
    
    % Utilisation :
    colormap(cmap);
    colorbar;
    
    
    % Affichage du fond (interpolé)
    hImg = imagesc(ax2, Mag_mean);
    set(hImg, 'XData', cols, 'YData', 1:numRows);  % Positionnement correct
    
    caxis(ax2, [5 15]);
    
    % Colorbar
    hC = colorbar(ax2);
    ylabel(hC, 'Vitesse moyenne (m/s)');
    
    uistack(hImg, 'bottom');  % met le fond sous les flèches
    
    hold(ax2, 'off');


    hold(ax2,'off');

    fprintf('Affichage des moyennes terminé.\n');


    end



