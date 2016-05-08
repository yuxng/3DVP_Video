function write_voxel_exemplars

opt = globals();
% seq_set = 'train';
num_seqs = numel(opt.mot2d_train_seqs);

% load ids
outdir = 'Voxel_exemplars';

% load data
object = load('data.mat');
data = object.data;
idx = data.idx;

% cluster centers
centers = unique(idx);
centers(centers == -1) = [];
N = numel(centers);
fprintf('%d clusters\n', N);

% write the mapping from cluster center to type
filename = sprintf('%s/mapping.txt', outdir);
fid = fopen(filename, 'w');
type = 'Pedestrian';
for i = 1:N
    fprintf(fid, '%d %s\n', i, type);
end
fclose(fid);

% for each sequence
for seq_idx = 1:num_seqs
    % get number of images for this dataset
    seq_name = opt.mot2d_train_seqs{seq_idx};
    seq_num = opt.mot2d_train_nums(seq_idx);
    
    if exist(fullfile(outdir, seq_name), 'dir') == 0
        mkdir(fullfile(outdir, seq_name));
    end
    
    % for each image
    for img_idx = 1:seq_num
        filename = sprintf('%s/%s/%06d.txt', outdir, seq_name, img_idx);
        fid = fopen(filename, 'w');

        % write object info to file
        index = find(data.sid == seq_idx & data.id == img_idx);
        for k = 1:numel(index)
            ind = index(k);
            % cluster id
            cluster_idx = idx(ind);
            if cluster_idx ~= -1
                cluster_idx = find(centers == cluster_idx);
            end

            % flip
            is_flip = data.is_flip(ind);

            % bounding box
            bbox = data.bbox(:,ind);

            % type
            type = 'Pedestrian';

            fprintf(fid, '%s %d %d %.2f %.2f %.2f %.2f\n', type, cluster_idx, is_flip, bbox(1), bbox(2), bbox(3), bbox(4));
        end

        fclose(fid);
        fprintf('%s: %d objects written\n', filename, numel(index));
    end
end