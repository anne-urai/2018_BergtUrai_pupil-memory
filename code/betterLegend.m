
function lh = betterLegend(h, txt, cond)

xlabel(sprintf('Time from %s onset (s)', cond));
%set(gcf, 'color', 'none');
set(gca, 'color', 'none');
set(gca, 'xcolor', 'k', 'ycolor', 'k');
tightfig;

switch cond
    case 'word'
        lh = legend(h, txt, 'Location', 'northwest');
        lh.Position(1) = lh.Position(1) - 0.08;
        lh.Position(2) = lh.Position(2) + 0.08;
        %lh.Position(3) = lh.Position(3) * 0.5;
    case 'image'
        lh = legend(h, txt, 'Location', 'southwest');
        lh.Position(1) = lh.Position(1) - 0.2;
        lh.Position(2) = lh.Position(2) - 0.05;
    otherwise
end

lh.Box = 'off';
lh.EdgeColor = 'none'; 
lh.FontSize = 4;
lh.Visible = 'on';

end