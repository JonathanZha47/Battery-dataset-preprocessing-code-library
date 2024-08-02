% 设置文件夹路径
base_folder = '/Users/jonathanzha/Desktop/Battery-dataset-preprocessing-code-library/NASA/sourcedata';

% 获取大文件夹列表
big_battery_folders = dir(base_folder);
big_battery_folders = big_battery_folders([big_battery_folders.isdir] & ~ismember({big_battery_folders.name}, {'.', '..'}));

% 设置每个文件抽取的充电和放电循环数
num_samples = 3;

% 遍历每个大文件夹
for i = 1:length(big_battery_folders)
    big_battery_folder = fullfile(base_folder, big_battery_folders(i).name);
    
    % 初始化存储合并数据的表
    combined_charge_data = table([], [], 'VariableNames', {'Time', 'Voltage'});
    combined_discharge_data = table([], [], 'VariableNames', {'Time', 'Voltage'});
    
    % 获取大文件夹下的所有 .mat 文件
    mat_files = dir(fullfile(big_battery_folder, '*.mat'));
    
    disp(['Processing folder: ', big_battery_folders(i).name]);
    
    for k = 1:length(mat_files)
        mat_file = fullfile(big_battery_folder, mat_files(k).name);
        data = load(mat_file);
        
        % 获取文件中的变量名（假设每个文件只有一个顶级变量）
        var_name = fieldnames(data);
        main_data = data.(var_name{1});
        
        % 检查并提取 charge 和 discharge 的 measured_voltage
        if isfield(main_data, 'cycle')
            cycles = main_data.cycle;
            
            % 获取充电和放电循环的索引
            charge_cycles = find(strcmp({cycles.type}, 'charge'));
            discharge_cycles = find(strcmp({cycles.type}, 'discharge'));
            
            % 过滤掉前20个充电循环
            if length(charge_cycles) > 20
                charge_cycles = charge_cycles(21:end);
            end

            % 随机抽取指定数量的充电和放电循环
            if length(charge_cycles) > num_samples
                charge_cycles = charge_cycles(randperm(length(charge_cycles), num_samples));
            end
            if length(discharge_cycles) > num_samples
                discharge_cycles = discharge_cycles(randperm(length(discharge_cycles), num_samples));
            end
            
            % 提取并合并充电循环数据
            for cycle_idx = charge_cycles
                cycle = cycles(cycle_idx);
                voltage_data = cycle.data.Voltage_measured(:);
                time_data = cycle.data.Time(:);
                cycle_data = table(time_data, voltage_data, 'VariableNames', {'Time', 'Voltage'});
                combined_charge_data = [combined_charge_data; cycle_data];
            end
            
            % 提取并合并放电循环数据
            for cycle_idx = discharge_cycles
                cycle = cycles(cycle_idx);
                voltage_data = cycle.data.Voltage_measured(:);
                time_data = cycle.data.Time(:);
                cycle_data = table(time_data, voltage_data, 'VariableNames', {'Time', 'Voltage'});
                combined_discharge_data = [combined_discharge_data; cycle_data];
            end
        end
    end
    
    % 打印合并后的数据行数
    disp(['Combined charge data rows for folder ', big_battery_folders(i).name, ': ', num2str(height(combined_charge_data))]);
    disp(['Combined discharge data rows for folder ', big_battery_folders(i).name, ': ', num2str(height(combined_discharge_data))]);
    
    % 对合并的数据按时间排序
    if ~isempty(combined_charge_data)
        combined_charge_data = sortrows(combined_charge_data, 'Time');
    end

    if ~isempty(combined_discharge_data)
        combined_discharge_data = sortrows(combined_discharge_data, 'Time');
    end
    
    outputChargeFolder = '/Users/jonathanzha/Desktop/Battery-dataset-preprocessing-code-library/NASA/CombinedBatchSamples(withoutFirst20)/charge';
    outputDischargeFolder = '/Users/jonathanzha/Desktop/Battery-dataset-preprocessing-code-library/NASA/CombinedBatchSamples(withoutFirst20)/discharge';

    % 保存合并后的数据到一个新的CSV文件
    charge_output_csv = fullfile(outputChargeFolder, sprintf('%s_combined_charge_cycles.csv', big_battery_folders(i).name));
    discharge_output_csv = fullfile(outputDischargeFolder, sprintf('%s_combined_discharge_cycles.csv', big_battery_folders(i).name));
    
    writetable(combined_charge_data, charge_output_csv);
    writetable(combined_discharge_data, discharge_output_csv);
end

disp('Data extraction, merging, and CSV export completed.');
