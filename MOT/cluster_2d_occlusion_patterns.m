function idx = cluster_2d_occlusion_patterns(data)

K = 128;
opt = globals;
seq_set = 'train';

% select the clustering data
flag = ones(size(data.is_flip));
fprintf('%d examples in clustering\n', sum(flag));

% determine the canonical size of the bounding boxes
modelDs = compute_model_size(data.bbox(:,flag));

% compute features
sbin = 8;
index = find(flag == 1);
X = [];
fprintf('computing features...\n');
for i = 1:numel(index)
    ind = index(i);
    % read the image
    seq_idx = data.sid(ind);
    seq_name = opt.mot2d_train_seqs{seq_idx};
    img_idx = data.id(ind);
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', img_idx));
    
    I = imread(filename);
    if data.is_flip(ind) == 1
        I = I(:, end:-1:1, :);
    end
    % crop image
    bbox = data.bbox(:,ind);
    gt = [bbox(1) bbox(2) bbox(3)-bbox(1) bbox(4)-bbox(2)];
    Is = bbApply('crop', I, gt, 'replicate', modelDs([2 1]));
    C = features(double(Is{1}), sbin);
    X(:,i) = C(:);
end
fprintf('done\n');

% kmeans clustering
fprintf('2d kmeans %d\n', K);
opts = struct('maxiters', 1000, 'mindelta', eps, 'verbose', 1);
[center, sse] = vgg_kmeans(X, K, opts);
[idx_kmeans, d] = vgg_nearest_neighbour(X, center);

% construct idx
num = numel(data.imgname);
idx = zeros(num, 1);
idx(flag == 0) = -1;
index_all = find(flag == 1);
for i = 1:K
    index = find(idx_kmeans == i);
    [~, ind] = min(d(index));
    cid = index_all(index(ind));
    idx(index_all(index)) = cid;
end


function modelDs = compute_model_size(bbox)

% pick mode of aspect ratios
h = bbox(4,:) - bbox(2,:) + 1;
w = bbox(3,:) - bbox(1,:) + 1;
xx = -2:.02:2;
filter = exp(-[-100:100].^2/400);
aspects = hist(log(h./w), xx);
aspects = convn(aspects, filter, 'same');
[~, I] = max(aspects);
aspect = exp(xx(I));

% pick 20 percentile area
areas = sort(h.*w);
area = areas(max(floor(length(areas) * 0.2), 1));
area = max(min(area, 10000), 500);

% pick dimensions
w = sqrt(area/aspect);
h = w*aspect;
modelDs = round([h w]);