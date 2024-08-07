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
        combined_data = table([], [], [], [], [], [], [],'VariableNames', {'Time', 'Voltage_Measured', 'Current_Measured', 'Voltage_Act','Current_Act', 'Temperature', 'Cycle Life'});
        
        % 获取文件中的变量名（假设每个文件只有一个顶级变量）
        var_name = fieldnames(data);
        main_data = data.(var_name{1});
        
        % 检查并提取 charge 的 measured_voltage
        if isfield(main_data, 'cycle')
            cycles = main_data.cycle;
            
            % 获取充电循环的索引
            charge_cycles = find(strcmp({cycles.type}, 'charge'));
            
            % 过滤并提取数据
            for cycle_idx = charge_cycles
                cycle = cycles(cycle_idx);
                voltage_measured_data = cycle.data.Voltage_measured(:);
                current_measured_data = cycle.data.Current_measured(:);
                voltage_actual_data = cycle.data.Voltage_charge(:);
                current_actual_data = cycle.data.Current_charge(:);
                time_data = cycle.data.Time(:);
                cycle_life_data = repmat(cycle_idx, length(time_data), 1);
                temperature_data = cycle.data.Temperature_measured(:);
               
                
                cycle_data = table( time_data, voltage_measured_data, current_measured_data, voltage_actual_data, current_actual_data, temperature_data, cycle_life_data,...
                                   'VariableNames', {'Time', 'Voltage_Measured', 'Current_Measured', 'Voltage_Act','Current_Act', 'Temperature', 'Cycle Life'});
                combined_data = [combined_data; cycle_data];
            end
        end
        
        % 保存合并后的数据到一个新的CSV文件
        outputFolder = '/Users/jonathanzha/Desktop/Battery-dataset-preprocessing-code-library/NASA/ChargeExtract';
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder);
        end
        output_csv = fullfile(outputFolder, sprintf('%s_chargeExtract.csv', mat_files(k).name));
        writetable(combined_data, output_csv);
        
        % 打印合并后的数据行数
        disp(['Combined data rows for file ', mat_files(k).name, ': ', num2str(height(combined_data))]);
    end
end

disp('Data extraction and CSV export completed.');
