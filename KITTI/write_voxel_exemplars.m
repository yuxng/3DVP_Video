function write_voxel_exemplars

is_train = 1;
opt = globals();

% load ids
object = load('kitti_ids.mat');
if is_train
    ids = object.ids_train;
    outdir = 'Voxel_exemplars';
else
    ids = sort([object.ids_train object.ids_val]);
    outdir = 'Voxel_exemplars_all';
end

% load data
if is_train
    object = load('data_train.mat');
else
    object = load('data_trainval.mat');
end
data = object.data;
idx = data.idx;

% cluster centers
centers = unique(idx);
centers(centers == -1) = [];
N = numel(centers);
fprintf('%d clusters\n', N);

% write the mapping from cluster center to azimuth and alpha
filename = sprintf('%s/mapping.txt', outdir);
fid = fopen(filename, 'w');
for i = 1:N
    azimuth = data.azimuth(centers(i));
    type = data.type{centers(i)};
    if strcmp(type, 'Van')
        type = 'Car';
    end    
    alpha = azimuth + 90;
    if alpha >= 360
        alpha = alpha - 360;
    end
    alpha = alpha*pi/180;
    if alpha > pi
        alpha = alpha - 2*pi;
    end
    fprintf(fid, '%d %s %f %f\n', i, type, azimuth, alpha);
end
fclose(fid);

% for each sequence
for i = 1:numel(ids)
    seq_idx = ids(i);
    seq_name = opt.kitti_train_seqs{seq_idx + 1};
    nimages = opt.kitti_train_nums(seq_idx + 1);
    
    if exist(fullfile(outdir, seq_name), 'dir') == 0
        mkdir(fullfile(outdir, seq_name));
    end
    
    % for each image
    for j = 1:nimages
        img_idx = j - 1;
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
            type = data.type{ind};
            if strcmp(type, 'Van')
                type = 'Car';
            end

            fprintf(fid, '%s %d %d %.2f %.2f %.2f %.2f\n', type, cluster_idx, is_flip, bbox(1), bbox(2), bbox(3), bbox(4));
        end

        fclose(fid);
        fprintf('%s: %d objects written\n', filename, numel(index));
    end
end