function show_detections

method = 'detection_train';
threshold = 0.5;

opt = globals;

% load ids
object = load('kitti_ids.mat');
ids = object.ids_val;

% get image directory
root_dir = opt.path_kitti;
data_set = 'training';
cam = 2; % 2 = left color camera
image_dir = fullfile(root_dir, [data_set '/image_' sprintf('%02d', cam)]);

for i = ids
    seq_name = opt.kitti_train_seqs{i+1};
    nimages = opt.kitti_train_nums(i+1);
    
    % load detection results
    filename = fullfile(method, data_set, sprintf('%04d.txt', i));
    fid = fopen(filename, 'r');
    C = textscan(fid, '%d %d %s %d %d %f %f %f %f %f %f %f %f %f %f %f %f %f');
    fclose(fid);
    
    for j = 1:nimages
        % read image
        img_idx = j - 1;
        filename = fullfile(image_dir, seq_name, sprintf('%06d.png', img_idx));
        I = imread(filename);
        imshow(I);
        
        % find detections
        index = C{1} == img_idx & C{18} > threshold;
        
        % boxes
        bbox = [C{7}(index) C{8}(index) C{9}(index) C{10}(index)];
        
        % show top K boxes
        for k = 1:size(bbox, 1)
            bbox_draw = [bbox(k,1) bbox(k,2) bbox(k,3)-bbox(k,1) bbox(k,4)-bbox(k,2)];
            rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth', 2);
        end
        
        pause;
    end
end