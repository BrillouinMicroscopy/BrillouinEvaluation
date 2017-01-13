function plotData (data, positions, datalabel)
    %% define possible dimensions and their labels
    dims = {'Y', 'X', 'Z'};
    dimslabel = {'y', 'x', 'z'};
    
    %% calculate zero mean positions
    for jj = 1:length(dims)
        positions.([dims{jj} '_zm']) = positions.(dims{jj}) - mean(positions.(dims{jj})(:))*ones(size(positions.(dims{jj})));
    end
    
    %% find non-singleton dimensions
    dimensions = size(data);
    dimension = sum(dimensions > 1);
    nsdims = cell(dimension,1);
    nsdimslabel = cell(dimension,1);
    ind = 0;
    for jj = 1:length(dimensions)
        if dimensions(jj) > 1
            ind = ind + 1;
            nsdims{ind} = dims{jj};
            nsdimslabel{ind} = dimslabel{jj};
        end
    end

    %% plot data for different dimensions
    switch dimension
        case 0
            %% 0D data
            disp(data(1,1,1));
        case 1
            %% 1D data
            d = squeeze(data);
            p = squeeze(positions.([nsdims{1} '_zm']));
            figure;
            plot(p,d);
            xlim([min(p(:)), max(p(:))]);
            xlabel(['$' nsdimslabel{1} '$ [$\mu$m]'], 'interpreter', 'latex');
            ylabel(datalabel, 'interpreter', 'latex');
        case 2
            %% 2D data
            d = squeeze(data);
            px = squeeze(positions.X_zm);
            py = squeeze(positions.Y_zm);
            pz = squeeze(positions.Z_zm);
            figure;
            surf(px, py, pz, d);
            shading flat;
            axis equal;
%             xlim([min(px(:)), max(px(:))]);
%             ylim([min(py(:)), max(py(:))]);
%             zlim([min(pz(:)), max(pz(:))]);
            xlabel('$x$ [$\mu$m]', 'interpreter', 'latex');
            ylabel('$y$ [$\mu$m]', 'interpreter', 'latex');
            zlabel('$z$ [$\mu$m]', 'interpreter', 'latex');
            cb = colorbar();
            title(cb,datalabel, 'interpreter', 'latex');
        case 3
            %% 3D data
            figure;
            hold on;
            for jj = 1:size(data,3)
                surf(positions.X_zm(:,:,jj),positions.Y_zm(:,:,jj),positions.Z_zm(:,:,jj),data(:,:,jj));
            end
            shading flat;
            axis equal;
            xlim([min(positions.X_zm(:)), max(positions.X_zm(:))]);
            ylim([min(positions.Y_zm(:)), max(positions.Y_zm(:))]);
            zlim([min(positions.Z_zm(:)), max(positions.Z_zm(:))]);
            xlabel('$x$ [$\mu$m]', 'interpreter', 'latex');
            ylabel('$y$ [$\mu$m]', 'interpreter', 'latex');
            zlabel('$z$ [$\mu$m]', 'interpreter', 'latex');
            cb = colorbar();
            title(cb,datalabel, 'interpreter', 'latex');
    end
end