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
    dx = diff(ax.XLim);
    bracketheight = 0.02 * dy;
    bracketspacing = 0.06 * dy;
    stardistance = 0.01 * dy;
    % plot significance stars and lines
    levels = [];
    if (measurement.p < 0.05)
        for jj = 1:size(measurement.significance,1)
            if (measurement.significance(jj,6) < 0.05) && show(jj)
                xStart = positions(measurement.significance(jj,1));
                xEnd = positions(measurement.significance(jj,2));
                stars = getStars(measurement.significance(jj,6));
                bracket = [xStart, xEnd];
                xPos = mean(bracket);
                
                %% Calculate level
                level = 0;
                for kk = 1:size(levels, 1)
                    % Check if the level is free
                    if xEnd <= levels(kk, 1)
                        levels(kk, 1) = xEnd; %#ok<AGROW>
                        level = kk - 1;
                        break
                    end
                    if levels(kk, 2) <= xStart
                        levels(kk, 2) = xStart; %#ok<AGROW>
                        level = kk - 1;
                        break
                    end
                    % Go one level up
                    level = kk;
                end
                if level == size(levels, 1)
                    levels(level + 1, 1:2) = bracket; %#ok<AGROW>
                end
                
                %% Set line and text
                text(xPos,measurement.significance_yPos + stardistance + level * bracketspacing,stars,...
                    'HorizontalAlignment','Center',...
                    'BackGroundColor','none',...
                    'Tag','sigstar_stars');
                line([xStart, xStart,...
                      xEnd, xEnd] + [1 1 -1 -1] * 0.004* dx,...
                     [measurement.significance_yPos - bracketheight, measurement.significance_yPos,...
                      measurement.significance_yPos, measurement.significance_yPos - bracketheight] + level * bracketspacing, 'color', 'k');
            end
        end
    end
    if ~h
        hold(ax, 'off');
    end
end