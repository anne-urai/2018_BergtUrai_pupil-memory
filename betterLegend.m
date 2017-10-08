
function betterLegend(h, txt)

lh = legend(h, txt, 'box', 'off', 'Location', 'southwest');

lpos = get(lh, 'Position');
lpos(1) = lpos(1) - 0.02;
lpos(2) = lpos(2) - 0.02;
%lpos(3) = 0.01 * lpos(3);
set(lh, 'Position', lpos, 'box', 'off', 'FontSize', 4);
%
% lpos = get(lgd, 'Position');
% set(lgd, 'Position', [lpos(1)-0.1 lpos(2)-0.1 lpos(3) lpos(4)]);

%lgd.Position(1) = lgd.Position(1) - 0.1; % move left
%lgd.Position(2) = lgd.Position(2) - 0.1; % move down
%
% for i = 1:length(icons),
%     if ~isprop(icons(i), 'String')
%         LineData = get(icons(i),'XData');
%         if numel(LineData) == 2,
%         NewData = [LineData(1)+.2 LineData(2)-.2];
%         set(icons(i),'XData', NewData, 'LineWidth',2);
%         end
%     end
% end
end