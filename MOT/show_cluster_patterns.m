function show_cluster_patterns(cid)

is_save = 0;

opt = globals;
seq_set = 'train';

% load data
object = load('data.mat');
data = object.data;
idx = data.idx;

% cluster centers
if nargin < 1
    centers = unique(idx);
    centers(centers == -1) = [];
else
    centers = cid;
end
N = numel(centers);

% hf = figure('units','normalized','outerposition',[0 0 0.5 1]);
hf = figure;
nplot = 5;
mplot = 6;
for i = 1:N
    disp(i);
    ind = centers(i);

    bbox = data.bbox(:, idx == ind);
    % plot of center locations of bounding boxes
    x = (bbox(1,:) + bbox(3,:)) / 2;
    y = (bbox(2,:) + bbox(4,:)) / 2;

    h = subplot(nplot, mplot, 1:mplot/2);
    plot(x, y, 'o');
    set(h, 'Ydir', 'reverse');
    axis equal;
    xlabel('x');
    ylabel('y');
    title('location');
    
    % plot of widths and heights of bounding boxes
    w = bbox(3,:) - bbox(1,:);
    h = bbox(4,:) - bbox(2,:);

    subplot(nplot, mplot, mplot/2+1:mplot);
    plot(w, h, 'o');
    axis equal;
    xlabel('w');
    ylabel('h');
    title('width and height');    
    
    ind_plot = mplot + 1;
    
    % show the image patch
    seq_idx = data.sid(ind);
    seq_name = opt.mot2d_train_seqs{seq_idx};
    img_idx = data.id(ind);
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', img_idx));    
    
    I = imread(filename);
    if data.is_flip(ind) == 1
        I = I(:, end:-1:1, :);
    end    
    bbox = data.bbox(:,ind);
    rect = [bbox(1) bbox(2) bbox(3)-bbox(1) bbox(4)-bbox(2)];
    I1 = imcrop(I, rect);
    subplot(nplot, mplot, ind_plot);
    ind_plot = ind_plot + 1;
    imshow(I1);
%     til = sprintf('w:%d, h:%d', size(I1,2), size(I1,1));
%     title(til);
    
    % show several members
    member = find(idx == ind);
    member(member == ind) = [];
    num = numel(member);
    fprintf('%d examples\n', num+1);
    for j = 1:min((nplot-1)*mplot-1, num)
        ind = member(j);
        
        % show the image patch
        seq_idx = data.sid(ind);
        seq_name = opt.mot2d_train_seqs{seq_idx};
        img_idx = data.id(ind);
        filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', img_idx));
        
        I = imread(filename);
        if data.is_flip(ind) == 1
            I = I(:, end:-1:1, :);
        end        
        bbox = data.bbox(:,ind);
        rect = [bbox(1) bbox(2) bbox(3)-bbox(1) bbox(4)-bbox(2)];
        I1 = imcrop(I, rect);
        subplot(nplot, mplot, ind_plot);
        ind_plot = ind_plot + 1;
        imshow(I1);
%         til = sprintf('w:%d, h:%d', size(I1,2), size(I1,1));
%         title(til);        
    end
    for j = ind_plot:nplot*mplot
        subplot(nplot, mplot, j);
        cla;
        title('');
    end
    if is_save
        filename = sprintf('Clusters/%03d.png', i);
        saveas(hf, filename);
    else
        pause;
    end
end