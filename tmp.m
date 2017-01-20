x1 = linspace(1,10,21);
y1 = sin(x1);

figure;
p = plot(x1,y1);
hold on;
p = plot(x1,y1,'color',[1, 0, 0, 0.2], 'linewidth', 5);

brush on;

xd = get(p, 'XData');
yd = get(p, 'YData');
brush = get(p, 'BrushData');
brushed_x = xd(logical(brush));
brushed_y = yd(logical(brush));