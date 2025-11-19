function animerVents()
    %% 1. Initialisation et Configuration
    dataFolderPath = '.\2010\'; 
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
    %% 3. Création de l'Animation
    
    % fprintf('Lancement de l animation...\n');
    % 
    % 
    % [X, Y] = meshgrid(cols, 1:numRows);
    % 
    % fig = figure('Name', 'Animation des Vents - Île de Centrosus', ...
    %              'WindowState', 'maximized');
    % ax = gca; 
    % 
    % % Configuration de l'axe (identique)
    % set(ax, 'YTick', 1:numRows, 'YTickLabel', cellstr(rows'));
    % set(ax, 'XTick', 1:numCols);
    % set(ax, 'YDir', 'reverse'); 
    % axis(ax, [cols(1)-0.5, cols(end)+0.5, 1-0.5, numRows+0.5]);
    % axis(ax, 'equal');
    % grid(ax, 'on');
    % set(ax, 'Layer', 'top'); 
    % 
    % hTitle = title(ax, 'Date:');
    % hold(ax, 'on');
    % 
    % % --- SUPPRIMÉ : Suppression du pcolor ---
    % % hPcolor = pcolor(ax, X, Y, NaN(size(X))); 
    % 
    % % --- NOUVELLE STRATÉGIE : Créer une grille d'objets quiver ---
    % hQuivers = gobjects(numRows, numCols); % Array pour stocker les poignées
    % for r = 1:numRows
    %     for c = 1:numCols
    %         % Crée un vecteur "vide" à chaque emplacement
    %         hQuivers(r,c) = quiver(ax, X(r,c), Y(r,c), NaN, NaN, ...
    %                                'AutoScale', 'off', ... % <-- MODIFIÉ : Nous gérons l'échelle
    %                                'LineWidth', 1.5);
    %     end
    % end
    % 
    % hold(ax, 'off');
    % 
    % % --- Configuration de la colormap (identique) ---
    % cmap = colormap(ax, 'jet'); % Obtenir la colormap
    % caxis(ax, [minVel, maxVel]);
    % hColorbar = colorbar(ax);
    % ylabel(hColorbar, 'Vitesse du vent (m/s)');
    % 
    % 
    % % Boucle d'animation
    % for day = 1:numDays
    %     % Mettre à jour le titre
    %     dateStr = datestr(Dates(day), 'dd-mmm-yyyy');
    %     set(hTitle, 'String', sprintf('Date: %s', dateStr));
    % 
    %     % --- NOUVELLE BOUCLE : Mettre à jour chaque vecteur (plus lent) ---
    %     for r = 1:numRows
    %         for c = 1:numCols
    %             % Obtenir les données du jour pour cette case
    %             u = U(r,c,day);
    %             v = V(r,c,day);
    %             mag = Magnitude(r,c,day);
    % 
    %             if isnan(mag)
    %                 % Cacher le vecteur s'il n'y a pas de données
    %                 set(hQuivers(r,c), 'UData', 0, 'VData', 0, 'Color', 'none');
    %             else
    %                 % Mettre à l'échelle les composantes pour l'affichage
    %                 u_scaled = u * scaling_factor;
    %                 v_scaled = v * scaling_factor;
    % 
    %                 % Calculer la couleur basée sur la magnitude
    %                 color_idx = max(1, min(length(cmap), ...
    %                                 1 + round((mag - minVel) / (maxVel - minVel) * (length(cmap) - 1))));
    % 
    %                 vector_color = cmap(color_idx, :);
    % 
    % 
    %                 % Mettre à jour le vecteur
    %                 set(hQuivers(r,c), ...
    %                     'UData', u_scaled, ...
    %                     'VData', v_scaled, ...
    %                     'Color', vector_color);
    %             end
    %         end
    %     end
    %     % --- Fin de la nouvelle boucle ---
    % 
    %     drawnow;
    %     pause(0.01); % Réduire la pause, car la boucle de rendu est déjà longue
    % end
    % 
    % fprintf('Animation terminée.\n');

    %% 4. Moyenne des vents (affichage fixe)
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
    title(ax2, 'Moyenne annuelle des vents - Île de Centrosus');
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
    
        
    fprintf('Affichage des moyennes terminé.\n');

    % ... (Votre code pour la Figure des moyennes reste ici) ...
    % ... (juste après la ligne 'hold(ax2,'off');')

    %% 5. Écart-type des vents (Nouvelle Figure)
    fprintf('Calcul des écart-types annuels...\n');
    
    % Écart-type de la magnitude (mesure de la variabilité de la vitesse)
    Mag_std = std(Magnitude, 0, 3, 'omitnan');
    
    % --- Figure des écart-types ---
    figure('Name','Écart-type annuel des vents','WindowState','maximized');
    ax3 = gca;
    hold(ax3, 'on');
    
    % Fond coloré : écart-type de la magnitude
    hImg_std = imagesc(ax3, Mag_std);
    set(hImg_std, 'XData', cols, 'YData', 1:numRows);
    
    % Définir les limites de la colormap (ajustez [0, 5] au besoin)
    max_std = prctile(Mag_std(:), 98); % Plafonnons à 98e percentile
    if isnan(max_std) || max_std == 0, max_std = 1; end % Éviter caxis([0 0])
    caxis(ax3, [0, max_std]);
    colormap(ax3, 'parula'); % 'parula' est bien pour la variabilité
    hC_std = colorbar(ax3);
    ylabel(hC_std, 'Écart-type de la vitesse (m/s)');
    uistack(hImg_std, 'bottom'); % Mettre le fond en arrière-plan
    
    % Afficher les vecteurs de vent MOYENS par-dessus (en noir)
    quiver(ax3, X, Y, U_mean, V_mean, 'AutoScale','on','LineWidth', 1.5, 'Color', 'k');
    
    % Configuration de l'axe (identique à la fig moyenne)
    axis(ax3,'equal');
    set(ax3,'YDir','reverse');
    set(ax3,'YTick',1:numRows,'YTickLabel',cellstr(rows'));
    set(ax3,'XTick',1:numCols);
    title(ax3, 'Écart-type de la vitesse (fond) et Vent moyen (vecteurs) - Île de Centrosus');
    grid(ax3,'on');
    
    hold(ax3,'off');

    
end



