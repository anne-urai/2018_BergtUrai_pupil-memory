
function dat = removeDuplicateVars(dat, vars)

for v = 1:length(vars),
    v1 = [vars{v} '_dat3'];
    v2 = [vars{v} '_dat4'];
    
    assert(isequaln(dat.(v1), dat.(v2)), 'mismatch');
    dat.(v1) = [];
    dat.Properties.VariableNames{v2} = vars{v};
end
end
