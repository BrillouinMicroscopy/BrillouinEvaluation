function drawSignificance(ax, measurement, positions, show)
    if ~exist('positions', 'var')
        positions = 1:max(measurement.significance(:,2));
    end
    if ~exist('show', 'var')
        show = ones(size(measurement.significance,1));
    end
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
            if (measurement.significance(jj,6) < 0.05) && show(jj)
                xStart = positions(measurement.significance(jj,1));
                xEnd = positions(measurement.significance(jj,2));
                stars = getStars(measurement.significance(jj,6));
                xPos = mean([xStart, xEnd]);
                text(xPos,measurement.significance_yPos + stardistance + ind * bracketspacing,stars,...
                    'HorizontalAlignment','Center',...
                    'BackGroundColor','none',...
                    'Tag','sigstar_stars');
                line([xStart, xStart,...
                      xEnd, xEnd],...
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