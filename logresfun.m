
function b = logresfun(x,y)
warning('error', 'stats:glmfit:IllConditioned'); % remove those subjects
warning('error', 'stats:glmfit:IterationLimit');

try
    b = glmfit(y, x, 'binomial', 'link', 'logit');
    b = b(2);
catch
    % if there
    b = nan(1);
end
if abs(b) > 2, b = nan; end

end

