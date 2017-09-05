function [intensity] = getIntensity1D(img, positions)
    
    [X, Y] = meshgrid(1:size(img,2),1:size(img,1));
    intensity = interp2(X,Y,img,positions.x,positions.y);
    
    intensity = mean(intensity, 1);
    
end