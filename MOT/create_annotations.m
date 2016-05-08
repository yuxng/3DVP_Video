% create annotations with occlusion masks for KITTI dataset
function create_annotations

opt = globals();
is_show = 0;

seq_set = 'train';
num_seqs = numel(opt.mot2d_train_seqs);

for seq_idx = 1:num_seqs

    % get number of images for this dataset
    seq_name = opt.mot2d_train_seqs{seq_idx};
    seq_num = opt.mot2d_train_nums(seq_idx);
    
    % read ground truth
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
    dres_gt = read_mot2dres(filename);
    dres_gt = fix_groundtruth(seq_name, dres_gt);
    y_gt = dres_gt.y + dres_gt.h;
    
    % build the training sequences
    ids = unique(dres_gt.id);
    dres_train = [];
    count = 0;
    for i = 1:numel(ids)
        index = find(dres_gt.id == ids(i));
        dres = sub(dres_gt, index);

        % check if the target is occluded or not
        num = numel(dres.fr);
        dres.occluded = zeros(num, 1);
        dres.covered = zeros(num, 1);
        y = dres.y + dres.h;
        for j = 1:num
            fr = dres.fr(j);
            index = find(dres_gt.fr == fr & dres_gt.id ~= ids(i));

            if isempty(index) == 0
                [~, ov] = calc_overlap(dres, j, dres_gt, index);
                ov(y(j) > y_gt(index)) = 0;
                dres.covered(j) = max(ov);
            end

            if dres.covered(j) > opt.overlap_occ
                dres.occluded(j) = 1;
            end
        end

        % start with bounding overlap > opt.overlap_pos and non-occluded box
        count = count + 1;
        dres_train{count} = dres;

        % show gt
         if is_show
            for j = 1:numel(dres_train{count}.fr)
                fr = dres_train{count}.fr(j);
                filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', fr));
                disp(filename);
                I = imread(filename);
                figure(1);
                show_dres(fr, I, 'GT', dres_train{count});
                pause;
            end
        end
    end

    % handle occlusion by a pole in PETS09-S2L1
    if strcmp(seq_name, 'PETS09-S2L1') == 1
        % dres_train([9, 15, 19]) = [];
        pole = [409.0000, 102.0000, 39.0000, 294.0000];
        dres_pole.x = pole(1);
        dres_pole.y = pole(2);
        dres_pole.w = pole(3);
        dres_pole.h = pole(4);
        for i = 1:numel(dres_train)
            dres = dres_train{i};
            [~, ~, overlap] = calc_overlap(dres_pole, 1, dres, 1:numel(dres.fr));
            dres.covered = max([dres.covered, overlap'], [], 2);
            dres.occluded(dres.covered > opt.overlap_occ) = 1;  
            dres_train{i} = dres;
        end
    end

    fprintf('%s: %d positive sequences\n', seq_name, numel(dres_train));

    % main loop
    for img_idx = 1:seq_num       
      record = [];
      record.folder = seq_set;
      record.seq_name = seq_name;
      record.filename = sprintf('%06d.jpg', img_idx);

      % read image
      I = imread(fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', img_idx)));
      [h, w, d] = size(I);

      record.size.width = w;
      record.size.height = h;
      record.size.depth = d;
      record.imgsize = [w h d];

      % objects in this frame
      objects = [];
      count = 0;
      for i = 1:numel(dres_train)
          index = find(dres_train{i}.fr == img_idx);
          if isempty(index) == 0 && dres_train{i}.occluded(index) == 0
              count = count + 1;
              objects(count).id = dres_train{i}.id(index);
              objects(count).x1 = dres_train{i}.x(index);
              objects(count).y1 = dres_train{i}.y(index);
              objects(count).x2 = dres_train{i}.x(index) + dres_train{i}.w(index);
              objects(count).y2 = dres_train{i}.y(index) + dres_train{i}.h(index);
              objects(count).is_flip = 0;
          end
      end
      record.objects = objects;

      % add flipped objects
      objects_flip = objects;
      for i = 1:numel(objects)
          objects_flip(i).is_flip = 1;
          % flip bbox
          oldx1 = objects(i).x1;
          oldx2 = objects(i).x2;        
          objects_flip(i).x1 = w - oldx2 + 1;
          objects_flip(i).x2 = w - oldx1 + 1;
      end  

      % save annotation
      record.objects_flip = objects_flip;
      if exist(fullfile('Annotations', seq_name), 'dir') == 0
          mkdir(fullfile('Annotations', seq_name));
      end
      filename = sprintf('Annotations/%s/%06d.mat', seq_name, img_idx);
      disp(filename);
      save(filename, 'record');
    end
end