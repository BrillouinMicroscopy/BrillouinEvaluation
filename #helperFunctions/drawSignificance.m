function drawSignificance(ax, measurement)
    h = ishold(ax);
    hold(ax, 'on');
    dy = diff(ax.YLim);
    bracketheight = 0.02 * dy;
    bracketspacing = 0.06 * dy;
    stardistance = 0.01 * dy;
    % plot significance stars and lines
    ind = 0;
    if (measurement.p < 0.05)
        for jj = 1:size(measurement.significance,1)
            if (measurement.significance(jj,6) < 0.05)
                stars = getStars(measurement.significance(jj,6));
                xPos = mean(measurement.significance(jj,1:2));
                text(xPos,measurement.significance_yPos + stardistance + ind * bracketspacing,stars,...
                    'HorizontalAlignment','Center',...
                    'BackGroundColor','none',...
                    'Tag','sigstar_stars');
                line([measurement.significance(jj,1), measurement.significance(jj,1),...
                      measurement.significance(jj,2), measurement.significance(jj,2)],...
                     [measurement.significance_yPos - bracketheight, measurement.significance_yPos,...
                      measurement.significance_yPos, measurement.significance_yPos - bracketheight] + ind * bracketspacing, 'color', 'k');
                
                ind = ind + 1;
            end
        end
    end
    if ~h
        hold(ax, 'off');
    end
end