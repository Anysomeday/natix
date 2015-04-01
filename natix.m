clear; 
clf;

% Konfiguracja
for par_image_id = [1];       % numer obrazu
par_wideness = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Wczytywanie obrazu
%%%

fprintf('\n# Wczytywanie obrazu\t'); 
tic;
ncube = hyper_ncube(par_image_id);
ncube_god_classification = hyper_class(par_image_id);
signature_depth = size(ncube,3);
layer_count = numel(ncube) / signature_depth;
toc;

imwrite(mean_RGB_from_hyperspectral(ncube), '00_image.png'); % Poka

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Detekcja granic
%%%

fprintf('# Detekcja granic\t');tic;
edges_cube = zeros(size(ncube));

% Budowa czterowymiarowej kostki
index = 1;
huge_stack_length = (1+par_wideness*2)^2;
huge_stack = zeros( size(ncube,1),...
                    size(ncube,2),...
                    size(ncube,3),...
                    huge_stack_length);
for x=-par_wideness:par_wideness
    for y=-par_wideness:par_wideness
            huge_stack(:,:,:,index) = circshift(ncube,[x,y]);
            index = index+1;
    end
end

% Analiza kostki
edges_cube = max(huge_stack,[],4)-min(huge_stack,[],4);
treshold = mean(mean(mean(edges_cube)));

edges_cube(edges_cube < treshold) = 0;
edges_cube(edges_cube >= treshold) = 1;

toc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Filtering
%%%
fprintf('# Filtrowanie\t');tic;

filter = hs_filter(edges_cube);

filtered_edges_cube = edges_cube(:,:,filter);
filtered_mean_edges = mean(filtered_edges_cube,3);
filtered_ncube = ncube(:,:,filter);

filtered_signature_depth = size(filtered_ncube,3);

edges_treshold = mean(mean(filtered_mean_edges));
edges_mask = filtered_mean_edges > edges_treshold;

imwrite(mean(edges_cube,3), '01_edge_mask.png');
imwrite(edges_mask, '01_edge_mask_f.png');
toc;

%%% Filling
% http://www.mathworks.com/help/images/ref/imfill.html
% http://blogs.mathworks.com/steve/2008/08/05/filling-small-holes/
negative = imcomplement(edges_mask);
filled = imfill(negative, 'holes');
holes = filled & ~negative;
bigholes = bwareaopen(holes, 200);
smallholes = holes & ~bigholes;
new = negative | smallholes;

% Image
imwrite(negative, '02_negative.png');
imwrite(filled, '03_filled_negative.png');
imwrite(new, '04_new.png');

%%% Labelling
% http://www.mathworks.com/help/images/ref/bwlabel.html
labels = bwlabel(new);
labels_no = max(max(labels));
centroids = regionprops(labels,'centroid');

fprintf('%i labels\n', labels_no);

% Image
% http://www.mathworks.com/help/images/ref/labelmatrix.html
imwrite(label2rgb(labels), '05_labels.png');

end
