function data = prepare_clustering_data

opt = globals();

% seq_set = 'train';
num_seqs = numel(opt.mot2d_train_seqs);

count = 0;
sid = [];
id = [];
obj_ind = [];
imgname = [];
bbox = [];
is_flip = [];

for seq_idx = 1:num_seqs

    % get number of images for this dataset
    seq_name = opt.mot2d_train_seqs{seq_idx};
    seq_num = opt.mot2d_train_nums(seq_idx);
    
    % for each frame
    for img_idx = 1:seq_num

        % load annotation
        filename = fullfile('Annotations', seq_name, sprintf('%06d.mat', img_idx));
        disp(filename);
        object = load(filename);
        record = object.record;
        objects = [record.objects record.objects_flip];

        for j = 1:numel(objects)
            object = objects(j);
            count = count + 1;
            sid(count) = seq_idx;
            id(count) = img_idx;
            obj_ind(count) = j;
            imgname{count} = record.filename;
            bbox(:,count) = [object.x1; object.y1; object.x2; object.y2];
            is_flip(count) = object.is_flip;
        end
    end
end

data.sid = sid;
data.id = id;
data.obj_ind = obj_ind;
data.imgname = imgname;
data.bbox = bbox;
data.is_flip = is_flip;