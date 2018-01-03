function [intensity] = getIntensity1D(img, extraction, time)

    positions = extraction.interpolationPositions;
    
    if size(positions.x, 3) > 1
        x = 1:size(positions.x,1);
        y = 1:size(positions.x,2);

        [X, Y, T] = meshgrid(y, x, extraction.times);

        time = time*ones(size(Y(:,:,1)));
        
        posX = interp3(X, Y, T, positions.x, X(:,:,1), Y(:,:,1), time);
        posY = interp3(X, Y, T, positions.y, X(:,:,1), Y(:,:,1), time);
    else
        % fall back to normal extraction if only one time point is
        % available
        posX = positions.x;
        posY = positions.y;
    end
    
    [X, Y] = meshgrid(1:size(img,2),1:size(img,1));
    intensity = interp2(X, Y, img, posX, posY);
    
    intensity = mean(intensity, 1);
    
end