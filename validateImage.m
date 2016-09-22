function [ ] = validateImage( img )
%% VALIDATEIMAGE
% function checks if the image is valid or something went wrong during its
% acquisition
% valid images
% - should not be zero
% - should not exceed a certain value, 1e9 was arbitrarily chosen

img_sum = sum(img(:));
if img_sum == 0 || img_sum > 1e9
    ME = MException('The image appears to be invalid.');
    throw(ME);
end

end