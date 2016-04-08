function data = prepare_clustering_data

is_train = 1;

% KITTI path
opt = globals();
root_dir = opt.path_kitti;
data_set = 'training';
calib_dir = fullfile(root_dir, [data_set '/calib']);

% load mean model
cls = 'car';
filename = sprintf('../Geometry/%s_mean.mat', cls);
object = load(filename);
cad = object.(cls);
index = cad.grid == 1;

% load pedestrian cad model
filename = '../Geometry/pedestrian.mat';
object = load(filename);
cad_pedestrian = object.pedestrian;
index_pedestrian = cad_pedestrian.grid == 1;

% load cyclist cad model
filename = '../Geometry/cyclist.mat';
object = load(filename);
cad_cyclist = object.cyclist;
index_cyclist = cad_cyclist.grid == 1;

% load original model
filename = sprintf('../Geometry/%s.mat', cls);
object = load(filename);
cads = object.(cls);

% load ids
object = load('kitti_ids.mat');
if is_train
    ids = object.ids_train;
else
    ids = sort([object.ids_train object.ids_val]);
end

count = 0;
sid = [];
id = [];
obj_ind = [];
imgname = [];
type = [];
bbox = [];
l = [];
h = [];
w = [];
alpha = [];
azimuth = [];
elevation = [];
distance = [];
occ_per = [];
truncation = [];
occlusion = [];
pattern = [];
grid = [];
grid_origin = [];
translation = [];
is_flip = [];
cad_index = [];

for k = 1:numel(ids)
    seq_idx = ids(k);
    seq_name = opt.kitti_train_seqs{seq_idx + 1};
    nimages = opt.kitti_train_nums(seq_idx + 1);
    
    % load the velo_to_cam matrix
    R0_rect = readCalibration(calib_dir, seq_idx, 4);
    tmp = R0_rect';
    tmp = tmp(1:9);
    tmp = reshape(tmp, 3, 3);
    tmp = tmp';
    Pv2c = readCalibration(calib_dir, seq_idx, 5);
    Pv2c = tmp * Pv2c;
    Pv2c = [Pv2c; 0 0 0 1];
    
    % for each frame
    for i = 1:nimages
        img_idx = i - 1;
        % load annotation
        filename = fullfile('Annotations', seq_name, sprintf('%06d.mat', img_idx));
        disp(filename);
        object = load(filename);
        record = object.record;
        objects = [record.objects record.objects_flip];

        for j = 1:numel(objects)
            object = objects(j);
            if (strcmp(object.type, 'Car') == 1 || strcmp(object.type, 'Van') == 1 ...
                    || strcmp(object.type, 'Pedestrian') == 1 || strcmp(object.type, 'Cyclist') == 1) ...
                    && isempty(object.grid) == 0
                count = count + 1;
                sid(count) = seq_idx;
                id(count) = img_idx;
                obj_ind(count) = j;
                imgname{count} = record.filename;
                type{count} = object.type;
                bbox(:,count) = [object.x1; object.y1; object.x2; object.y2];
                l(count) = object.l;
                h(count) = object.h;
                w(count) = object.w;
                alpha(count) = object.alpha;
                azimuth(count) = object.azimuth;
                elevation(count) = object.elevation;
                distance(count) = object.distance;
                occ_per(count) = object.occ_per;
                truncation(count) = object.truncation;
                occlusion(count) = object.occlusion;
                pattern{count} = object.pattern;
                
                if strcmp(object.type, 'Car') || strcmp(object.type, 'Van')
                    grid{count} = uint8(object.grid(index));
                elseif strcmp(object.type, 'Pedestrian')
                    grid{count} = uint8(object.grid(index_pedestrian));
                else
                    grid{count} = uint8(object.grid(index_cyclist));
                end
                    
                if strcmp(object.type, 'Car') || strcmp(object.type, 'Van')
                    index_cad = cads(object.cad_index).grid == 1;
                    grid_origin{count} = uint8(object.grid_origin(index_cad));
                else
                    grid_origin{count} = grid{count};
                end
                    
                % transform to velodyne space
                X = [object.t'; 1];
                X = Pv2c\X;
                X(4) = [];
                translation(:,count) = X;
                is_flip(count) = object.is_flip;
                cad_index(count) = object.cad_index;
            end
        end
    end
end

data.sid = sid;
data.id = id;
data.obj_ind = obj_ind;
data.imgname = imgname;
data.type = type;
data.bbox = bbox;
data.l = l;
data.h = h;
data.w = w;
data.alpha = alpha;
data.azimuth = azimuth;
data.elevation = elevation;
data.distance = distance;
data.occ_per = occ_per;
data.truncation = truncation;
data.occlusion = occlusion;
data.pattern = pattern;
data.grid = grid;
data.grid_origin = grid_origin;
data.translation = translation;
data.is_flip = is_flip;
data.cad_index = cad_index;