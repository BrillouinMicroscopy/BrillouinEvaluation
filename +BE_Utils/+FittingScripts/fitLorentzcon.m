function [estimates2b, model2b, newxb, FittedCurve2b, deviation] = fitLorentzcon(model2b, newxb, start)
    
    options = optimset('MaxFunEvals', 100000, 'MaxIter', 100000, 'Display', 'off');
%     estimates2b = fminsearch(model2b, start, options);
%     estimates2b(3) = abs(estimates2b(3));
    A = [0 0 1 -1 0 0];
    b = 3;
    Aeq = [];
    beq = [];
    %lower bounds for fitting params
    lb = [0 0 2 2 12 12];
    %upper bounds for fitting params
    ub = [400 400 30 50 400 400];
    nonlcon = [];
    estimates2b = fmincon(model2b, start,A,b,Aeq,beq,lb,ub,nonlcon,options);
    
    
    estimates2b(3) = abs(estimates2b(3));
    
    [deviation, FittedCurve2b] = model2b(estimates2b);
    
end

