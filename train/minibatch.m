function ret = minibatch(model, dataset, opts)
% MINIBATCH devide large dataset into small pieces in training

% MooGu Z. <hzhu@case.edu>
% 2 21, 2016

if nargin == 0
    opts = struct( ...
        'tvt',       [0.8, 0.02, 0.18], ...
        'nepoch',    10, ...
        'batchSize', 32);
    ret  = opts; 
    return
end

if isfield(opts, 'logger')
    logger = opts.logger;
else
    logger = Logger();                  % @@@ follow Logger constructor
end

[trainset, validset, testset] = dataset.subsets(opts.tvt);

vdata = validset.next(validset.size);
tdata = testset.next(testset.size);

for ep = 1 : opts.nepoch
    for b = 1 : ceil(trainset.size / opts.batchSize)
        data = trainset.next(opts.batchSize);
        model.trainproc(data);
        logger.add(model.validate(vdata));
    end
end

logger.add(model.evaluate(tdata));

ret = logger; 
return

end
    
