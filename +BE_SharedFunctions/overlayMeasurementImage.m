function [image] = overlayMeasurementImage(model, image, currentCalibrationNr)
%% OVERLAYMEASUREMENTIMAGE
    
    try
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end

    datestring = model.controllers.data.getCalibration('date', currentCalibrationNr);
    try
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    time = etime(datevec(date),datevec(refTime));

    img_measurement = BE_SharedFunctions.getMeasurementImage(model, time);
    try
        img_measurement = medfilt2(img_measurement);
    catch
    end
    image = max(image, img_measurement);
        
end