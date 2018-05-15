function stars = getStars(p)
    if p<=1e-3
        stars='***'; 
    elseif p<=1e-2
        stars='**';
    elseif p<=0.05
        stars='*';
    elseif isnan(p)
        stars='';
    else
        stars='n.s.';
    end
end