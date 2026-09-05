clc;
clear;
close all;

%% =========================================================
% 2024 国赛 B题 第一问
% Wald SPRT 序贯概率比检验
%
% 约定：
% x = 1 表示次品
% x = 0 表示合格品
%
% 每检测一个产品，就更新一次对数似然比 LLR
%
% 如果 LLR >= 上边界：
%     支持 H1
%
% 如果 LLR <= 下边界：
%     支持 H0
%
% 否则：
%     继续抽样
%% =========================================================


%% =========================================================
% Monte Carlo 参数
%% =========================================================

trials = 10000;      % 蒙特卡洛重复次数
max_n  = 10000;      % 最大允许抽样数

rng(2024);           % 固定随机种子，保证结果可复现


%% =========================================================
% 情形1
%
% 目标：
% 在95%信度下判断次品率是否超过标称值0.10
%
% 设置：
% H0: p = 0.10
% H1: p = 0.20
%
% p1=0.20表示我们希望重点识别的明显偏离水平
%
% alpha = 0.05
% beta  = 0.10
%% =========================================================

p0_1 = 0.10;
p1_1 = 0.20;

alpha1 = 0.05;
beta1  = 0.10;


%% Wald边界

lower1 = log( ...
    beta1 / (1-alpha1) ...
    );

upper1 = log( ...
    (1-beta1) / alpha1 ...
    );


%% 每出现一个次品，对LLR的增量

badStep1 = ...
    log(p1_1/p0_1);


%% 每出现一个合格品，对LLR的增量

goodStep1 = ...
    log((1-p1_1)/(1-p0_1));


fprintf('\n');
fprintf('============================================================\n');
fprintf('情形1：95%%信度判断次品率是否偏高\n');
fprintf('============================================================\n');

fprintf('H0: p = %.2f\n',p0_1);
fprintf('H1: p = %.2f\n',p1_1);

fprintf('下边界 A = %.6f\n',lower1);
fprintf('上边界 B = %.6f\n',upper1);

fprintf('次品LLR增量 = %.6f\n',badStep1);
fprintf('合格品LLR增量 = %.6f\n',goodStep1);


%% =========================================================
% 情形1 Monte Carlo
%
% 分别测试：
%
% 真实 p = 0.10
% 真实 p = 0.20
%% =========================================================

result_1_p010 = monte_carlo_sprt( ...
    p0_1, ...
    p1_1, ...
    alpha1, ...
    beta1, ...
    0.10, ...
    trials, ...
    max_n, ...
    1);


result_1_p020 = monte_carlo_sprt( ...
    p0_1, ...
    p1_1, ...
    alpha1, ...
    beta1, ...
    0.20, ...
    trials, ...
    max_n, ...
    1);


fprintf('\n情形1 Monte Carlo结果：\n');

disp(result_1_p010);
disp(result_1_p020);


%% =========================================================
% 情形2
%
% 目标：
% 在90%信度下判断次品率是否可以接受
%
% 这里按照上传Python程序的设定：
%
% p0 = 0.10
% p1 = 0.05
%
% 即重点比较：
%
% p = 0.10
% 与
% p = 0.05
%
% alpha = 0.10
% beta  = 0.05
%
% 由于 p1 < p0，
% LLR较大时更支持较低次品率p=0.05，
% 因此解释为“接收”
%% =========================================================

p0_2 = 0.10;
p1_2 = 0.05;

alpha2 = 0.10;
beta2  = 0.05;


%% Wald边界

lower2 = ...
    log(beta2/(1-alpha2));

upper2 = ...
    log((1-beta2)/alpha2);


%% 单样本LLR增量

badStep2 = ...
    log(p1_2/p0_2);

goodStep2 = ...
    log((1-p1_2)/(1-p0_2));


fprintf('\n');
fprintf('============================================================\n');
fprintf('情形2：90%%信度判断批次是否可以接受\n');
fprintf('============================================================\n');

fprintf('比较 p = %.2f 与 p = %.2f\n', ...
    p0_2,p1_2);

fprintf('下边界 A = %.6f\n',lower2);
fprintf('上边界 B = %.6f\n',upper2);

fprintf('次品LLR增量 = %.6f\n',badStep2);
fprintf('合格品LLR增量 = %.6f\n',goodStep2);


%% =========================================================
% 情形2 Monte Carlo
%
% 测试：
%
% 真实 p = 0.05
% 真实 p = 0.10
%% =========================================================

result_2_p005 = monte_carlo_sprt( ...
    p0_2, ...
    p1_2, ...
    alpha2, ...
    beta2, ...
    0.05, ...
    trials, ...
    max_n, ...
    2);


result_2_p010 = monte_carlo_sprt( ...
    p0_2, ...
    p1_2, ...
    alpha2, ...
    beta2, ...
    0.10, ...
    trials, ...
    max_n, ...
    2);


fprintf('\n情形2 Monte Carlo结果：\n');

disp(result_2_p005);
disp(result_2_p010);


%% =========================================================
% 将4组Monte Carlo结果合并
%% =========================================================

Scenario = [
    "情形1"
    "情形1"
    "情形2"
    "情形2"
    ];

TrueDefectRate = [
    0.10
    0.20
    0.05
    0.10
    ];

AverageSampleNumber = [
    result_1_p010.AverageSampleNumber
    result_1_p020.AverageSampleNumber
    result_2_p005.AverageSampleNumber
    result_2_p010.AverageSampleNumber
    ];

UpperDecisionProbability = [
    result_1_p010.UpperDecisionProbability
    result_1_p020.UpperDecisionProbability
    result_2_p005.UpperDecisionProbability
    result_2_p010.UpperDecisionProbability
    ];


SummaryTable = table( ...
    Scenario, ...
    TrueDefectRate, ...
    AverageSampleNumber, ...
    UpperDecisionProbability);


fprintf('\n');
fprintf('============================================================\n');
fprintf('Monte Carlo汇总结果\n');
fprintf('============================================================\n');

disp(SummaryTable);


%% =========================================================
% 保存到Excel
%% =========================================================

filename = 'problem1_sprt_result.xlsx';


if exist(filename,'file')
    delete(filename);
end


writetable( ...
    SummaryTable, ...
    filename, ...
    'Sheet', ...
    'MonteCarlo结果');


%% =========================================================
% 保存SPRT参数
%% =========================================================

ParameterName = [
    "情形1_p0"
    "情形1_p1"
    "情形1_alpha"
    "情形1_beta"
    "情形1_lower"
    "情形1_upper"
    "情形2_p0"
    "情形2_p1"
    "情形2_alpha"
    "情形2_beta"
    "情形2_lower"
    "情形2_upper"
    ];


ParameterValue = [
    p0_1
    p1_1
    alpha1
    beta1
    lower1
    upper1
    p0_2
    p1_2
    alpha2
    beta2
    lower2
    upper2
    ];


ParameterTable = table( ...
    ParameterName, ...
    ParameterValue);


writetable( ...
    ParameterTable, ...
    filename, ...
    'Sheet', ...
    'SPRT参数');


%% =========================================================
% 示例：
% 随机生成一批真实次品率p=0.20的数据，
% 看一次具体序贯检测过程
%% =========================================================

true_p_example = 0.20;


[decisionExample, ...
 nExample, ...
 defectsExample, ...
 llrExample, ...
 nHistory, ...
 llrHistory] = ...
    sprt_once( ...
    p0_1, ...
    p1_1, ...
    alpha1, ...
    beta1, ...
    true_p_example, ...
    max_n, ...
    1);


fprintf('\n');
fprintf('============================================================\n');
fprintf('一次具体SPRT检测示例\n');
fprintf('============================================================\n');

fprintf('真实次品率：%.2f\n',true_p_example);

fprintf('最终决策：%s\n',decisionExample);

fprintf('停止时样本数：%d\n',nExample);

fprintf('累计发现次品数：%d\n',defectsExample);

fprintf('停止时LLR：%.6f\n',llrExample);


%% =========================================================
% 绘制一次SPRT路径
%% =========================================================

figure;


plot( ...
    nHistory, ...
    llrHistory, ...
    'LineWidth',1.5);


hold on;


yline( ...
    upper1, ...
    '--', ...
    'Upper boundary');


yline( ...
    lower1, ...
    '--', ...
    'Lower boundary');


xlabel('Sample Number');

ylabel('Log-Likelihood Ratio');

title('Example Path of Wald SPRT');

grid on;

box on;


%% =========================================================
% 保存图片
%% =========================================================

exportgraphics( ...
    gcf, ...
    'problem1_sprt_example.png', ...
    'Resolution',300);


%% =========================================================
% 完成
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('第一问 SPRT 计算完成！\n');
fprintf('结果文件：%s\n',filename);
fprintf('示例路径图：problem1_sprt_example.png\n');
fprintf('============================================================\n');


%% =========================================================
%%                  以下为局部函数
%% =========================================================


function result = monte_carlo_sprt( ...
    p0, ...
    p1, ...
    alpha, ...
    beta, ...
    true_p, ...
    trials, ...
    max_n, ...
    mode)

%% =========================================================
% Monte Carlo验证SPRT
%
% 输出：
%
% AverageSampleNumber：
% 平均检测次数ASN
%
% UpperDecisionProbability：
% 达到上边界的概率
%
% LowerDecisionProbability：
% 达到下边界的概率
%% =========================================================


sampleNumbers = ...
    zeros(trials,1);


upperCount = 0;

lowerCount = 0;

truncateCount = 0;


for k = 1:trials

    [decision, ...
     n, ...
     ~, ...
     ~] = ...
        sprt_once( ...
        p0, ...
        p1, ...
        alpha, ...
        beta, ...
        true_p, ...
        max_n, ...
        mode);


    sampleNumbers(k) = n;


    if startsWith(decision,"UPPER")

        upperCount = ...
            upperCount + 1;

    elseif startsWith(decision,"LOWER")

        lowerCount = ...
            lowerCount + 1;

    else

        truncateCount = ...
            truncateCount + 1;

    end

end


AverageSampleNumber = ...
    mean(sampleNumbers);


UpperDecisionProbability = ...
    upperCount/trials;


LowerDecisionProbability = ...
    lowerCount/trials;


TruncateProbability = ...
    truncateCount/trials;


result = table( ...
    true_p, ...
    AverageSampleNumber, ...
    UpperDecisionProbability, ...
    LowerDecisionProbability, ...
    TruncateProbability, ...
    'VariableNames', { ...
    'TrueDefectRate', ...
    'AverageSampleNumber', ...
    'UpperDecisionProbability', ...
    'LowerDecisionProbability', ...
    'TruncateProbability'});

end



function [decision, ...
          n, ...
          defects, ...
          llr, ...
          nHistory, ...
          llrHistory] = ...
    sprt_once( ...
    p0, ...
    p1, ...
    alpha, ...
    beta, ...
    true_p, ...
    max_n, ...
    mode)

%% =========================================================
% 执行一次SPRT序贯检验
%% =========================================================


%% Wald上下边界

lower = ...
    log(beta/(1-alpha));


upper = ...
    log((1-beta)/alpha);


%% 单个观测对LLR的增量

badStep = ...
    log(p1/p0);


goodStep = ...
    log((1-p1)/(1-p0));


%% 初始化

llr = 0;

defects = 0;


nHistory = zeros(max_n,1);

llrHistory = zeros(max_n,1);


%% =========================================================
% 序贯抽样
%% =========================================================

for n = 1:max_n

    %% 产生一个Bernoulli样本
    %
    % x=1：次品
    % x=0：合格品

    x = ...
        rand < true_p;


    defects = ...
        defects + x;


    %% 更新对数似然比

    if x == 1

        llr = ...
            llr + badStep;

    else

        llr = ...
            llr + goodStep;

    end


    %% 保存轨迹

    nHistory(n) = n;

    llrHistory(n) = llr;


    %% =====================================================
    % 达到上界
    %% =====================================================

    if llr >= upper

        if mode == 1

            %% 情形1：
            % 上界支持高次品率

            decision = ...
                "UPPER：拒收 / 支持较高次品率";

        else

            %% 情形2：
            % p1 < p0
            % 上界支持较低次品率

            decision = ...
                "UPPER：接收 / 支持较低次品率";

        end


        nHistory = ...
            nHistory(1:n);

        llrHistory = ...
            llrHistory(1:n);

        return;

    end


    %% =====================================================
    % 达到下界
    %% =====================================================

    if llr <= lower

        if mode == 1

            decision = ...
                "LOWER：接收 / 支持标称次品率";

        else

            decision = ...
                "LOWER：拒收 / 不支持较低次品率";

        end


        nHistory = ...
            nHistory(1:n);

        llrHistory = ...
            llrHistory(1:n);

        return;

    end

end


%% =========================================================
% 如果达到max_n仍然没有跨界
%
% 按当前LLR正负进行截尾判定
%
% 与上传Python版本保持一致
%% =========================================================

if llr >= 0

    decision = ...
        "TRUNCATE：上限截尾，倾向上边界";

else

    decision = ...
        "TRUNCATE：上限截尾，倾向下边界";

end


nHistory = ...
    nHistory(1:max_n);

llrHistory = ...
    llrHistory(1:max_n);

end