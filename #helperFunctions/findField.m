function fieldName = findField(structure, field, value)
    fieldNames = fieldnames(structure);
    for jj = 1:length(fieldNames)
        if strcmp(structure.(fieldNames{jj}).(field), value)
            fieldName = fieldNames{jj};
            return;
        end
    end
    fieldName = [];
end