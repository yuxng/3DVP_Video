function show_annotations

opt = globals();
is_flip = 1;

seq_set = 'train';
num_seqs = numel(opt.mot2d_train_seqs);

for seq_idx = 1:num_seqs

    % get number of images for this dataset
    seq_name = opt.mot2d_train_seqs{seq_idx};
    seq_num = opt.mot2d_train_nums(seq_idx);
    
    for i = 1:seq_num
        
        % load annotation
        filename = sprintf('Annotations/%s/%06d.mat', seq_name, i);
        object = load(filename);
        record = object.record;
        if is_flip
            objects = record.objects_flip;
        else
            objects = record.objects;
        end
        
        % read image
        filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', i));
        I = imread(filename);
        if is_flip
            I = I(:,end:-1:1,:);
        end
        imshow(I);
        hold on;
        
        for j = 1:numel(objects)
            bbox = [objects(j).x1 objects(j).y1 objects(j).x2 objects(j).y2];
            bbox_draw = [bbox(1) bbox(2) bbox(3)-bbox(1) bbox(4)-bbox(2)];
            rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'Linewidth', 2);
        end
        hold off;
        pause;
    end
    
end