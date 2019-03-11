function [image, diftime] = getMeasurementImage(model, time)
%% GETMEASUREMENTIMAGE
%   This function return the image from the actual measurement which was
%   acquired closest to the requested time

    % if the time array does not exist yet, create it
    if isempty(model.results.times) || ~sum(~isnan(model.results.times(:)))
        try
            refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
        catch
            refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
        end
        imgs = model.controllers.data.getPayload('data', 1, 1, 1);
        times = NaN(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3));
        for jj = 1:1:model.parameters.resolution.X
            for kk = 1:1:model.parameters.resolution.Y
                for ll = 1:1:model.parameters.resolution.Z
                    try
                        % read data from the file
                        datestring = model.controllers.data.getPayload('date', jj, kk, ll);
                        try
                            date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
                        catch
                            date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
                        end

                        for mm = 1:size(imgs,3)
                            time = etime(datevec(date),datevec(refTime)) + (mm-1) * model.parameters.exposureTime;
                            times(kk, jj, ll, mm) = time;
                        end
                    catch
                    end
                end
            end
        end
        model.results.times = times;
    end
    
    diftimes = abs(model.results.times - time);
    [diftime, ind] = min(diftimes(:));
    
    [y, x, z, imgNr] = ind2sub(size(model.results.times), ind);
    
    image = model.controllers.data.getPayload('data', x, y, z);
    image = image(:,:,imgNr);
end