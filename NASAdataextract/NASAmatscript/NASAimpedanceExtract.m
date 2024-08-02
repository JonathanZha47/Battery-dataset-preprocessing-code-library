% 电池Batch信息
Batch1 = {'B0005', 'B0006', 'B0007', 'B0018'};
Batch2 = {'B0025', 'B0026', 'B0027', 'B0028'};
Batch3 = {'B0029', 'B0030', 'B0031', 'B0032'};
Batch4 = {'B0033', 'B0034', 'B0036'};
Batch5 = {'B0038', 'B0039', 'B0040'};
Batch6 = {'B0041', 'B0042', 'B0043', 'B0044'};
Batch7 = {'B0045', 'B0046', 'B0047', 'B0048'};
Batch8 = {'B0049', 'B0050', 'B0051', 'B0052'};
Batch9 = {'B0053', 'B0054', 'B0055', 'B0056'};

% 将Batch信息重建为一个字典
Batch = containers.Map({'Batch1', 'Batch2', 'Batch3', 'Batch4', 'Batch5', 'Batch6', 'Batch7', 'Batch8', 'Batch9'}, ...
                        {Batch1, Batch2, Batch3, Batch4, Batch5, Batch6, Batch7, Batch8, Batch9});

% 设置文件夹路径
base_folder = '/Users/jonathanzha/Desktop/Battery-dataset-preprocessing-code-library/NASA/sourcedata';

% 获取大文件夹列表
big_battery_folders = dir(base_folder);
big_battery_folders = big_battery_folders([big_battery_folders.isdir] & ~ismember({big_battery_folders.name}, {'.', '..'}));

% 遍历每个大文件夹
for i = 1:length(big_battery_folders)
    big_battery_folder = fullfile(base_folder, big_battery_folders(i).name);
    
    % 获取大文件夹下的所有 .mat 文件
    mat_files = dir(fullfile(big_battery_folder, '*.mat'));
    
    disp(['Processing folder: ', big_battery_folders(i).name]);
    
    for k = 1:length(mat_files)
        mat_file = fullfile(big_battery_folder, mat_files(k).name);
        data = load(mat_file);
        
        % 初始化存储合并数据的表
        combined_data = table([], [], [], [], [], [], [], [], [], [], [] ,'VariableNames', ...
            {'Battery_impedance_real_mean', 'Battery_impedance_real_max', 'Battery_impedance_imag_mean', 'Battery_impedance_imag_max', ...
            'Rectified_impedance_real_mean', 'Rectified_impedance_real_max', 'Rectified_impedance_imag_mean', 'Rectified_impedance_imag_max', ...
            'Re', 'Rct', 'Impedance Cycle Life'});
        
        % 获取文件中的变量名（假设每个文件只有一个顶级变量）
        var_name = fieldnames(data);
        main_data = data.(var_name{1});

        % 跳过 B0052.mat 文件
        if strcmp(mat_files(k).name, 'B0052.mat')
            continue;
        end

        % 检查并提取 impedance 数据
        if isfield(main_data, 'cycle')
            cycles = main_data.cycle;
            
            % 获取电阻检测的索引
            impedance_cycles = find(strcmp({cycles.type}, 'impedance'));
            
            % 过滤并提取数据
            for cycle_idx = impedance_cycles
                cycle = cycles(cycle_idx);
                % 检查阻抗数据是否存在
                if ~isfield(cycle.data, 'Battery_impedance') || ~isfield(cycle.data, 'Rectified_Impedance')
                    warning('Skipping cycle %d in file %s due to missing impedance data.', cycle_idx, mat_files(k).name);
                    continue;
                end
                
                battery_impedance_data = cycle.data.Battery_impedance(:);
                rectified_impedance_data = cycle.data.Rectified_Impedance(:);
                re_data = cycle.data.Re;
                rct_data = cycle.data.Rct;
                cycle_life_data = cycle_idx;

                % 计算实部和虚部的 mean 和 max
                battery_impedance_real = real(battery_impedance_data);
                battery_impedance_imag = imag(battery_impedance_data);
                rectified_impedance_real = real(rectified_impedance_data);
                rectified_impedance_imag = imag(rectified_impedance_data);
                
                battery_impedance_real_mean = mean(battery_impedance_real);
                battery_impedance_real_max = max(battery_impedance_real);
                battery_impedance_imag_mean = mean(battery_impedance_imag);
                battery_impedance_imag_max = max(battery_impedance_imag);
                
                rectified_impedance_real_mean = mean(rectified_impedance_real);
                rectified_impedance_real_max = max(rectified_impedance_real);
                rectified_impedance_imag_mean = mean(rectified_impedance_imag);
                rectified_impedance_imag_max = max(rectified_impedance_imag);

                cycle_data = table(battery_impedance_real_mean, battery_impedance_real_max, battery_impedance_imag_mean, battery_impedance_imag_max, ...
                                   rectified_impedance_real_mean, rectified_impedance_real_max, rectified_impedance_imag_mean, rectified_impedance_imag_max, ...
                                   re_data, rct_data, cycle_life_data, ...
                                   'VariableNames', ...
                                   {'Battery_impedance_real_mean', 'Battery_impedance_real_max', 'Battery_impedance_imag_mean', 'Battery_impedance_imag_max', ...
                                   'Rectified_impedance_real_mean', 'Rectified_impedance_real_max', 'Rectified_impedance_imag_mean', 'Rectified_impedance_imag_max', ...
                                   'Re', 'Rct', 'Impedance Cycle Life'});
                combined_data = [combined_data; cycle_data];
            end
        end
        
        % 确定当前文件属于哪个Batch
        current_battery = mat_files(k).name(1:5);  % 假设电池名是前5个字符
        batch_name = '';
        for batch = keys(Batch)
            if ismember(current_battery, Batch(batch{1}))
                batch_name = batch{1};
                break;
            end
        end
        
        if isempty(batch_name)
            warning('Battery %s does not belong to any defined batch.', current_battery);
            continue;
        end
        
        % 保存合并后的数据到一个新的CSV文件
        outputFolder = fullfile('/Users/jonathanzha/Desktop/Battery-dataset-preprocessing-code-library/NASA/ImpedanceOutput', batch_name);
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder);
        end
        output_csv = fullfile(outputFolder, sprintf('%s_ImpedanceExtract.csv', mat_files(k).name));
        writetable(combined_data, output_csv);
        
        % 打印合并后的数据行数
        disp(['Combined data rows for file ', mat_files(k).name, ': ', num2str(height(combined_data))]);
    end
end

disp('Impedance data extraction and CSV export completed.');
