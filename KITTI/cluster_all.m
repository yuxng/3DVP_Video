function cluster_all

% load data
filename = 'data_train.mat';
disp(filename);
object = load(filename);
data = object.data;
N = numel(data.id);

idxes = zeros(N, 3);

pscale = 0.001;
idxes(:,1) = cluster_3d_occlusion_patterns(data, 'Car', 'ap', [], pscale);
idxes(:,2) = cluster_3d_occlusion_patterns(data, 'Pedestrian', 'ap', [], pscale);
idxes(:,3) = cluster_3d_occlusion_patterns(data, 'Cyclist', 'ap', [], pscale);

% combine the idxes
idx = max(idxes, [], 2);
data.idx = idx;
save(filename, 'data', '-v7.3');