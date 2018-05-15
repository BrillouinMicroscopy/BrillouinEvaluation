function drawSignificance(ax, measurement)
    h = ishold(ax);
    hold(ax, 'on');
    % plot significance stars and lines
    ind = 0;
    if (measurement.p < 0.05)
        for jj = 1:size(measurement.significance,1)
            if (measurement.significance(jj,6) < 0.05)
                stars = getStars(measurement.significance(jj,6));
                xPos = mean(measurement.significance(jj,1:2));
                text(xPos,measurement.significance_yPos + ind*0.015,stars,...
                    'HorizontalAlignment','Center',...
                    'BackGroundColor','none',...
                    'Tag','sigstar_stars');
                line([measurement.significance(jj,1), measurement.significance(jj,1),...
                      measurement.significance(jj,2), measurement.significance(jj,2)],...
                     [measurement.significance_yPos - 0.004, measurement.significance_yPos,...
                      measurement.significance_yPos, measurement.significance_yPos - 0.004] + (ind-1)*0.015, 'color', 'k');
                
                ind = ind + 1;
            end
        end
    end
    if ~h
        hold(ax, 'off');
    end
end