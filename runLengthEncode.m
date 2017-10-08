function [lengths, values, offsets] = runLengthEncode(data)
startPos    = find(diff([data(1)-1, data]));
lengths     = diff([startPos, numel(data)+1]);
offsets     = startPos + lengths;
values      = data(startPos);

end