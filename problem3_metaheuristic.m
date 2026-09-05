clc;
clear;
close all;

%% =========================================================
% 2024 全国大学生数学建模竞赛 B题 问题3
%
% 元启发式算法对比：
%
% 1. 遗传算法 GA
% 2. 模拟退火算法 SA
% 3. 二进制粒子群算法 BPSO
%
% 每种算法独立运行20次
%
% 与完全枚举全局最优结果进行比较
%% =========================================================


%% =========================================================
% 1. 决策变量个数
%
% x1~x8
% y1~y3
% z
% u1~u3
% v
%
% 共16个0-1变量
%% =========================================================

nVar = 16;


%% =========================================================
% 2. 独立运行次数
%% =========================================================

nRuns = 20;


%% =========================================================
% 3. 完全枚举得到的标准答案
%
% 用于验证元启发式算法
%% =========================================================

referenceStrategy = ...
    "1111111111101111";


referenceProfit = ...
    60.222222222222;


%% 判断是否达到全局最优的容差

successTol = 1e-6;


%% =========================================================
% 4. GA 参数
%% =========================================================

GA_popSize = 60;

GA_maxGen = 100;

GA_pc = 0.80;

GA_pm = 1/nVar;

GA_elite = 2;


%% =========================================================
% 5. SA 参数
%% =========================================================

SA_maxIter = 8000;

SA_T0 = 10;

SA_alpha = 0.999;


%% =========================================================
% 6. BPSO 参数
%% =========================================================

PSO_particles = 50;

PSO_maxIter = 150;

PSO_wMax = 0.9;

PSO_wMin = 0.4;

PSO_c1 = 1.8;

PSO_c2 = 1.8;


%% =========================================================
% 7. 初始化每次运行结果
%% =========================================================

GA_profit = zeros(nRuns,1);

SA_profit = zeros(nRuns,1);

PSO_profit = zeros(nRuns,1);


GA_time = zeros(nRuns,1);

SA_time = zeros(nRuns,1);

PSO_time = zeros(nRuns,1);


GA_strategy = strings(nRuns,1);

SA_strategy = strings(nRuns,1);

PSO_strategy = strings(nRuns,1);


%% =========================================================
% 8. 保存每一次运行的收敛历史
%
% 每一列对应一次独立运行
%% =========================================================

GA_history_all = ...
    zeros(GA_maxGen,nRuns);


SA_history_all = ...
    zeros(SA_maxIter,nRuns);


PSO_history_all = ...
    zeros(PSO_maxIter,nRuns);


%% =========================================================
% 9. 开始20次独立实验
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('2024 B题 问题3 元启发式算法比较\n');
fprintf('GA、SA、BPSO 各独立运行 %d 次\n',nRuns);
fprintf('============================================================\n');


for run = 1:nRuns

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('第 %d / %d 次独立实验\n',run,nRuns);
    fprintf('============================================================\n');


    %% =====================================================
    % A. 遗传算法 GA
    %% =====================================================

    % 固定不同随机种子
    % 保证实验可复现

    rng(1000 + run);


    tic;


    [xGA,pGA,hGA] = ...
        binary_ga( ...
        nVar, ...
        GA_popSize, ...
        GA_maxGen, ...
        GA_pc, ...
        GA_pm, ...
        GA_elite);


    GA_time(run) = toc;


    %% 保存利润

    GA_profit(run) = ...
        pGA;


    %% 保存策略

    GA_strategy(run) = ...
        string(sprintf('%d',xGA));


    %% 保存收敛历史

    GA_history_all(:,run) = ...
        hGA(:);


    fprintf( ...
        'GA   利润 = %.6f 元，策略 = %s，时间 = %.4f s\n', ...
        GA_profit(run), ...
        GA_strategy(run), ...
        GA_time(run));


    %% =====================================================
    % B. 模拟退火 SA
    %% =====================================================

    rng(2000 + run);


    tic;


    [xSA,pSA,hSA] = ...
        binary_sa( ...
        nVar, ...
        SA_maxIter, ...
        SA_T0, ...
        SA_alpha);


    SA_time(run) = toc;


    %% 保存利润

    SA_profit(run) = ...
        pSA;


    %% 保存策略

    SA_strategy(run) = ...
        string(sprintf('%d',xSA));


    %% 保存收敛历史

    SA_history_all(:,run) = ...
        hSA(:);


    fprintf( ...
        'SA   利润 = %.6f 元，策略 = %s，时间 = %.4f s\n', ...
        SA_profit(run), ...
        SA_strategy(run), ...
        SA_time(run));


    %% =====================================================
    % C. 二进制粒子群 BPSO
    %% =====================================================

    rng(3000 + run);


    tic;


    [xPSO,pPSO,hPSO] = ...
        binary_pso( ...
        nVar, ...
        PSO_particles, ...
        PSO_maxIter, ...
        PSO_wMax, ...
        PSO_wMin, ...
        PSO_c1, ...
        PSO_c2);


    PSO_time(run) = toc;


    %% 保存利润

    PSO_profit(run) = ...
        pPSO;


    %% 保存策略

    PSO_strategy(run) = ...
        string(sprintf('%d',xPSO));


    %% 保存收敛历史

    PSO_history_all(:,run) = ...
        hPSO(:);


    fprintf( ...
        'BPSO 利润 = %.6f 元，策略 = %s，时间 = %.4f s\n', ...
        PSO_profit(run), ...
        PSO_strategy(run), ...
        PSO_time(run));

end


%% =========================================================
% 10. 判断每一次是否成功找到全局最优解
%% =========================================================

GA_success = ...
    abs(GA_profit-referenceProfit) ...
    <= successTol;


SA_success = ...
    abs(SA_profit-referenceProfit) ...
    <= successTol;


PSO_success = ...
    abs(PSO_profit-referenceProfit) ...
    <= successTol;


%% =========================================================
% 11. 计算成功次数与成功率
%% =========================================================

GA_successNum = ...
    sum(GA_success);


SA_successNum = ...
    sum(SA_success);


PSO_successNum = ...
    sum(PSO_success);


GA_successRate = ...
    100 * GA_successNum / nRuns;


SA_successRate = ...
    100 * SA_successNum / nRuns;


PSO_successRate = ...
    100 * PSO_successNum / nRuns;


%% =========================================================
% 12. 找三种算法的最好一次
%% =========================================================

[GA_bestProfit,GA_bestIndex] = ...
    max(GA_profit);


[SA_bestProfit,SA_bestIndex] = ...
    max(SA_profit);


[PSO_bestProfit,PSO_bestIndex] = ...
    max(PSO_profit);


GA_bestStrategy = ...
    GA_strategy(GA_bestIndex);


SA_bestStrategy = ...
    SA_strategy(SA_bestIndex);


PSO_bestStrategy = ...
    PSO_strategy(PSO_bestIndex);


%% =========================================================
% 13. 计算统计指标
%% =========================================================

GA_meanProfit = ...
    mean(GA_profit);


SA_meanProfit = ...
    mean(SA_profit);


PSO_meanProfit = ...
    mean(PSO_profit);


GA_stdProfit = ...
    std(GA_profit);


SA_stdProfit = ...
    std(SA_profit);


PSO_stdProfit = ...
    std(PSO_profit);


GA_meanTime = ...
    mean(GA_time);


SA_meanTime = ...
    mean(SA_time);


PSO_meanTime = ...
    mean(PSO_time);


GA_stdTime = ...
    std(GA_time);


SA_stdTime = ...
    std(SA_time);


PSO_stdTime = ...
    std(PSO_time);


%% =========================================================
% 14. 构造总汇总表
%% =========================================================

Algorithm = [
    "GA"
    "SA"
    "BPSO"
    ];


BestStrategy = [
    GA_bestStrategy
    SA_bestStrategy
    PSO_bestStrategy
    ];


BestProfit = [
    GA_bestProfit
    SA_bestProfit
    PSO_bestProfit
    ];


MeanProfit = [
    GA_meanProfit
    SA_meanProfit
    PSO_meanProfit
    ];


StdProfit = [
    GA_stdProfit
    SA_stdProfit
    PSO_stdProfit
    ];


SuccessNum = [
    GA_successNum
    SA_successNum
    PSO_successNum
    ];


SuccessRate = [
    GA_successRate
    SA_successRate
    PSO_successRate
    ];


MeanTime = [
    GA_meanTime
    SA_meanTime
    PSO_meanTime
    ];


StdTime = [
    GA_stdTime
    SA_stdTime
    PSO_stdTime
    ];


SummaryTable = table( ...
    Algorithm, ...
    BestStrategy, ...
    BestProfit, ...
    MeanProfit, ...
    StdProfit, ...
    SuccessNum, ...
    SuccessRate, ...
    MeanTime, ...
    StdTime);


%% =========================================================
% 15. 命令窗口输出统计结果
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('三种算法20次独立实验结果汇总\n');
fprintf('============================================================\n');

disp(SummaryTable);


%% =========================================================
% 16. 与完全枚举结果比较
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('与完全枚举结果比较\n');
fprintf('============================================================\n');


fprintf( ...
    '完全枚举最优策略：%s\n', ...
    referenceStrategy);


fprintf( ...
    '完全枚举最大期望利润：%.6f 元\n\n', ...
    referenceProfit);


fprintf( ...
    'GA 最优策略：%s\n', ...
    GA_bestStrategy);

fprintf( ...
    'GA 最大利润：%.6f 元\n', ...
    GA_bestProfit);

fprintf( ...
    'GA 与枚举最优值差：%.10f\n', ...
    abs(GA_bestProfit-referenceProfit));

fprintf( ...
    'GA 成功次数：%d / %d\n', ...
    GA_successNum,nRuns);

fprintf( ...
    'GA 成功率：%.2f%%\n\n', ...
    GA_successRate);


fprintf( ...
    'SA 最优策略：%s\n', ...
    SA_bestStrategy);

fprintf( ...
    'SA 最大利润：%.6f 元\n', ...
    SA_bestProfit);

fprintf( ...
    'SA 与枚举最优值差：%.10f\n', ...
    abs(SA_bestProfit-referenceProfit));

fprintf( ...
    'SA 成功次数：%d / %d\n', ...
    SA_successNum,nRuns);

fprintf( ...
    'SA 成功率：%.2f%%\n\n', ...
    SA_successRate);


fprintf( ...
    'BPSO 最优策略：%s\n', ...
    PSO_bestStrategy);

fprintf( ...
    'BPSO 最大利润：%.6f 元\n', ...
    PSO_bestProfit);

fprintf( ...
    'BPSO 与枚举最优值差：%.10f\n', ...
    abs(PSO_bestProfit-referenceProfit));

fprintf( ...
    'BPSO 成功次数：%d / %d\n', ...
    PSO_successNum,nRuns);

fprintf( ...
    'BPSO 成功率：%.2f%%\n', ...
    PSO_successRate);


%% =========================================================
% 17. 每次运行结果表
%% =========================================================

RunID = ...
    (1:nRuns)';


%% ---------------- GA ----------------

GARuns = table( ...
    RunID, ...
    GA_strategy, ...
    GA_profit, ...
    GA_time, ...
    GA_success, ...
    'VariableNames', { ...
    'RunID', ...
    'Strategy', ...
    'Profit', ...
    'Time', ...
    'Success'});


%% ---------------- SA ----------------

SARuns = table( ...
    RunID, ...
    SA_strategy, ...
    SA_profit, ...
    SA_time, ...
    SA_success, ...
    'VariableNames', { ...
    'RunID', ...
    'Strategy', ...
    'Profit', ...
    'Time', ...
    'Success'});


%% ---------------- BPSO ----------------

PSORuns = table( ...
    RunID, ...
    PSO_strategy, ...
    PSO_profit, ...
    PSO_time, ...
    PSO_success, ...
    'VariableNames', { ...
    'RunID', ...
    'Strategy', ...
    'Profit', ...
    'Time', ...
    'Success'});


%% =========================================================
% 18. 计算20次平均收敛曲线
%% =========================================================

GA_meanHistory = ...
    mean(GA_history_all,2);


SA_meanHistory = ...
    mean(SA_history_all,2);


PSO_meanHistory = ...
    mean(PSO_history_all,2);


%% =========================================================
% 19. 目标函数评价次数
%
% 注意：
%
% GA：
% 每代大约评价popSize个方案
%
% SA：
% 每次迭代评价1个新方案
%
% BPSO：
% 每次迭代评价particles个粒子
%% =========================================================

GA_eval = ...
    (1:GA_maxGen)' ...
    * GA_popSize;


SA_eval = ...
    (1:SA_maxIter)';


PSO_eval = ...
    (1:PSO_maxIter)' ...
    * PSO_particles;


%% =========================================================
% 20. 绘制三种算法平均收敛曲线
%% =========================================================

figure;


plot( ...
    GA_eval, ...
    GA_meanHistory, ...
    'LineWidth',1.8);


hold on;


plot( ...
    SA_eval, ...
    SA_meanHistory, ...
    'LineWidth',1.8);


plot( ...
    PSO_eval, ...
    PSO_meanHistory, ...
    'LineWidth',1.8);


%% 完全枚举的全局最优值

yline( ...
    referenceProfit, ...
    '--', ...
    'Global optimum', ...
    'LineWidth',1.3);


xlabel( ...
    'Number of Objective Function Evaluations');


ylabel( ...
    'Best Expected Profit / Yuan');


title( ...
    'Average Convergence of GA, SA and BPSO over 20 Runs');


legend( ...
    'GA', ...
    'SA', ...
    'BPSO', ...
    'Enumeration optimum', ...
    'Location','best');


grid on;

box on;


%% =========================================================
% 21. 保存收敛图
%% =========================================================

exportgraphics( ...
    gcf, ...
    'problem3_algorithm_convergence_20runs.png', ...
    'Resolution',300);


%% =========================================================
% 22. 输出算法统计柱状图
%
% 成功率
%% =========================================================

figure;


bar( ...
    categorical(Algorithm), ...
    SuccessRate);


ylabel( ...
    'Success Rate / %');


xlabel( ...
    'Algorithm');


title( ...
    'Global Optimum Success Rate over 20 Runs');


ylim([55 60.5]);


grid on;


exportgraphics( ...
    gcf, ...
    'problem3_algorithm_success_rate.png', ...
    'Resolution',300);


%% =========================================================
% 23. 保存Excel
%% =========================================================

filename = ...
    'problem3_metaheuristic_20runs_result.xlsx';


if exist(filename,'file')

    delete(filename);

end


%% -----------------------------------------
% Sheet 1：算法总体比较
%% -----------------------------------------

writetable( ...
    SummaryTable, ...
    filename, ...
    'Sheet', ...
    '算法比较');


%% -----------------------------------------
% Sheet 2：GA 20次结果
%% -----------------------------------------

writetable( ...
    GARuns, ...
    filename, ...
    'Sheet', ...
    'GA_20次');


%% -----------------------------------------
% Sheet 3：SA 20次结果
%% -----------------------------------------

writetable( ...
    SARuns, ...
    filename, ...
    'Sheet', ...
    'SA_20次');


%% -----------------------------------------
% Sheet 4：BPSO 20次结果
%% -----------------------------------------

writetable( ...
    PSORuns, ...
    filename, ...
    'Sheet', ...
    'BPSO_20次');


%% =========================================================
% 24. 保存完全枚举基准信息
%% =========================================================

ReferenceTable = table( ...
    referenceStrategy, ...
    referenceProfit, ...
    'VariableNames', { ...
    'EnumerationBestStrategy', ...
    'EnumerationBestProfit'});


writetable( ...
    ReferenceTable, ...
    filename, ...
    'Sheet', ...
    '完全枚举基准');


%% =========================================================
% 25. 保存参数设置
%% =========================================================

Parameter = {

    '参数','数值';

    '独立运行次数',nRuns;

    '决策变量个数',nVar;

    'GA种群规模',GA_popSize;

    'GA最大代数',GA_maxGen;

    'GA交叉概率',GA_pc;

    'GA变异概率',GA_pm;

    'GA精英数量',GA_elite;

    'SA最大迭代次数',SA_maxIter;

    'SA初始温度',SA_T0;

    'SA降温系数',SA_alpha;

    'BPSO粒子数量',PSO_particles;

    'BPSO最大迭代次数',PSO_maxIter;

    'BPSO最大惯性权重',PSO_wMax;

    'BPSO最小惯性权重',PSO_wMin;

    'BPSO个体学习因子',PSO_c1;

    'BPSO群体学习因子',PSO_c2;

    '完全枚举最优利润',referenceProfit

    };


writecell( ...
    Parameter, ...
    filename, ...
    'Sheet', ...
    '算法参数');


%% =========================================================
% 26. 最终提示
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('20次元启发式优化实验全部完成！\n');
fprintf('============================================================\n');

fprintf('\n结果文件：\n');
fprintf('%s\n',filename);

fprintf('\n生成图片：\n');

fprintf( ...
    'problem3_algorithm_convergence_20runs.png\n');

fprintf( ...
    'problem3_algorithm_success_rate.png\n');


fprintf('\n');
fprintf('GA成功率：%.2f%%\n', ...
    GA_successRate);

fprintf('SA成功率：%.2f%%\n', ...
    SA_successRate);

fprintf('BPSO成功率：%.2f%%\n', ...
    PSO_successRate);


fprintf('\n');
fprintf('完全枚举最优利润：%.6f 元\n', ...
    referenceProfit);

fprintf('============================================================\n');