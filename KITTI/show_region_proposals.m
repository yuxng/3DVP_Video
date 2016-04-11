function show_region_proposals

method = 'RPN_train';
K = 20;

opt = globals;

% get image directory
root_dir = opt.path_kitti;
data_set = 'training';
cam = 2; % 2 = left color camera
image_dir = fullfile(root_dir, [data_set '/image_' sprintf('%02d', cam)]);

num = numel(opt.kitti_train_seqs);
for i = 1:num
    seq_name = opt.kitti_train_seqs{i};
    nimages = opt.kitti_train_nums(i);
    
    for j = 1:nimages
        % read image
        img_idx = j - 1;
        filename = fullfile(image_dir, seq_name, sprintf('%06d.png', img_idx));
        I = imread(filename);
        imshow(I);
        
        % read region proposals
        filename = fullfile('region_proposals', method, data_set, seq_name,  sprintf('%06d.txt', img_idx));
        fid = fopen(filename, 'r');
        C = textscan(fid, '%f %f %f %f %f');
        fclose(fid);
        
        % boxes
        bbox = [C{1} C{2} C{3} C{4}];
        
        % show top K boxes
        for k = 1:K
            bbox_draw = [bbox(k,1) bbox(k,2) bbox(k,3)-bbox(k,1) bbox(k,4)-bbox(k,2)];
            rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth', 2);
        end
        
        pause;
    end
end