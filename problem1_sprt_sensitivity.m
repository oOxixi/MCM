clc;
clear;
close all;

%% =========================================================
% 2024 B题 第一问
% Wald SPRT 参数敏感性分析
%
% 比较：
%
% 可接收质量水平：
% pA = 0.03, 0.05, 0.07
%
% 拒收质量水平：
% pR = 0.15, 0.20, 0.25
%
% 重点比较：
%
% 1. 平均抽样数 ASN
% 2. 错误接收/错误拒收概率
% 3. 正确判定概率
%
%% =========================================================


%% =========================================================
% 1. 基础参数
%% =========================================================

p0 = 0.10;

pA_list = [ ...
    0.03, ...
    0.05, ...
    0.07];

pR_list = [ ...
    0.15, ...
    0.20, ...
    0.25];


%% Monte Carlo重复次数

trials = 10000;


%% 最大允许抽样数

max_n = 10000;


%% 固定随机数种子

rng(2024);


%% =========================================================
% 2. 拒收检验参数
%
% H0: p = 0.10
% H1: p = pR
%
% 95%信度控制错误拒收风险
%% =========================================================

alpha_R = 0.05;

beta_R = 0.10;


%% =========================================================
% 3. 接收检验参数
%
% H0: p = 0.10
% H1: p = pA
%
% 90%信度控制错误接收风险
%% =========================================================

alpha_A = 0.10;

beta_A = 0.05;


%% =========================================================
% 4. 拒收水平 pR 敏感性分析
%% =========================================================

nR = length(pR_list);


R_ASN_p0 = zeros(nR,1);

R_ASN_pR = zeros(nR,1);


R_FalseReject = zeros(nR,1);

R_CorrectReject = zeros(nR,1);

R_MissReject = zeros(nR,1);


R_lower = zeros(nR,1);

R_upper = zeros(nR,1);


fprintf('\n');
fprintf('============================================================\n');
fprintf('拒收水平 pR 敏感性分析\n');
fprintf('============================================================\n');


for j = 1:nR

    pR = pR_list(j);


    %% -----------------------------------------------------
    % Wald边界
    %% -----------------------------------------------------

    lower = ...
        log(beta_R/(1-alpha_R));


    upper = ...
        log((1-beta_R)/alpha_R);


    R_lower(j) = lower;

    R_upper(j) = upper;


    %% -----------------------------------------------------
    % 当真实p=p0时
    %
    % 理想情况：
    % 不应该拒收
    %
    % 因此达到上边界的概率
    % 就是错误拒收概率
    %% -----------------------------------------------------

    res_p0 = monte_carlo_upper( ...
        p0, ...
        pR, ...
        alpha_R, ...
        beta_R, ...
        p0, ...
        trials, ...
        max_n);


    R_ASN_p0(j) = ...
        res_p0.ASN;


    R_FalseReject(j) = ...
        res_p0.UpperProb;


    %% -----------------------------------------------------
    % 当真实p=pR时
    %
    % 理想情况：
    % 应该拒收
    %
    % 达到上界 = 正确拒收
    %% -----------------------------------------------------

    res_pR = monte_carlo_upper( ...
        p0, ...
        pR, ...
        alpha_R, ...
        beta_R, ...
        pR, ...
        trials, ...
        max_n);


    R_ASN_pR(j) = ...
        res_pR.ASN;


    R_CorrectReject(j) = ...
        res_pR.UpperProb;


    R_MissReject(j) = ...
        1 - R_CorrectReject(j);


    fprintf('\n');
    fprintf('pR = %.2f\n',pR);

    fprintf( ...
        '  p=0.10时 ASN = %.3f\n', ...
        R_ASN_p0(j));

    fprintf( ...
        '  错误拒收概率 = %.4f\n', ...
        R_FalseReject(j));

    fprintf( ...
        '  p=pR时 ASN = %.3f\n', ...
        R_ASN_pR(j));

    fprintf( ...
        '  正确拒收概率 = %.4f\n', ...
        R_CorrectReject(j));

    fprintf( ...
        '  漏拒概率 = %.4f\n', ...
        R_MissReject(j));

end


%% =========================================================
% 5. 拒收结果表
%% =========================================================

RejectTable = table( ...
    pR_list(:), ...
    R_ASN_p0, ...
    R_ASN_pR, ...
    R_FalseReject, ...
    R_CorrectReject, ...
    R_MissReject, ...
    'VariableNames', { ...
    'pR', ...
    'ASN_at_p0', ...
    'ASN_at_pR', ...
    'FalseRejectRate', ...
    'CorrectRejectRate', ...
    'MissRejectRate'});


fprintf('\n');
fprintf('============================================================\n');
fprintf('拒收水平敏感性汇总\n');
fprintf('============================================================\n');

disp(RejectTable);


%% =========================================================
% 6. 接收水平 pA 敏感性分析
%% =========================================================

nA = length(pA_list);


A_ASN_p0 = zeros(nA,1);

A_ASN_pA = zeros(nA,1);


A_FalseAccept = zeros(nA,1);

A_CorrectAccept = zeros(nA,1);

A_MissAccept = zeros(nA,1);


A_lower = zeros(nA,1);

A_upper = zeros(nA,1);


fprintf('\n');
fprintf('============================================================\n');
fprintf('接收水平 pA 敏感性分析\n');
fprintf('============================================================\n');


for j = 1:nA

    pA = pA_list(j);


    %% -----------------------------------------------------
    % 注意：
    %
    % 此时pA < p0
    %
    % 所以SPRT的上边界支持较低次品率pA
    %
    % 达到上界 = 接收
    %% -----------------------------------------------------

    lower = ...
        log(beta_A/(1-alpha_A));


    upper = ...
        log((1-beta_A)/alpha_A);


    A_lower(j) = lower;

    A_upper(j) = upper;


    %% -----------------------------------------------------
    % 当真实p=pA
    %
    % 理想情况：
    % 应该接收
    %% -----------------------------------------------------

    res_pA = monte_carlo_upper( ...
        p0, ...
        pA, ...
        alpha_A, ...
        beta_A, ...
        pA, ...
        trials, ...
        max_n);


    A_ASN_pA(j) = ...
        res_pA.ASN;


    A_CorrectAccept(j) = ...
        res_pA.UpperProb;


    A_MissAccept(j) = ...
        1 - A_CorrectAccept(j);


    %% -----------------------------------------------------
    % 当真实p=p0
    %
    % 此时如果达到支持pA的上界，
    % 就相当于错误接收
    %% -----------------------------------------------------

    res_p0 = monte_carlo_upper( ...
        p0, ...
        pA, ...
        alpha_A, ...
        beta_A, ...
        p0, ...
        trials, ...
        max_n);


    A_ASN_p0(j) = ...
        res_p0.ASN;


    A_FalseAccept(j) = ...
        res_p0.UpperProb;


    fprintf('\n');
    fprintf('pA = %.2f\n',pA);

    fprintf( ...
        '  p=pA时 ASN = %.3f\n', ...
        A_ASN_pA(j));

    fprintf( ...
        '  正确接收概率 = %.4f\n', ...
        A_CorrectAccept(j));

    fprintf( ...
        '  漏接概率 = %.4f\n', ...
        A_MissAccept(j));

    fprintf( ...
        '  p=0.10时 ASN = %.3f\n', ...
        A_ASN_p0(j));

    fprintf( ...
        '  错误接收概率 = %.4f\n', ...
        A_FalseAccept(j));

end


%% =========================================================
% 7. 接收结果表
%% =========================================================

AcceptTable = table( ...
    pA_list(:), ...
    A_ASN_pA, ...
    A_ASN_p0, ...
    A_CorrectAccept, ...
    A_FalseAccept, ...
    A_MissAccept, ...
    'VariableNames', { ...
    'pA', ...
    'ASN_at_pA', ...
    'ASN_at_p0', ...
    'CorrectAcceptRate', ...
    'FalseAcceptRate', ...
    'MissAcceptRate'});


fprintf('\n');
fprintf('============================================================\n');
fprintf('接收水平敏感性汇总\n');
fprintf('============================================================\n');

disp(AcceptTable);


%% =========================================================
% 8. 构造一个综合评价指标
%
% 为了比较不同pA、pR的抽样效率，
% 取两个边界真实状态下ASN的平均值
%% =========================================================

R_MeanASN = ...
    (R_ASN_p0 + R_ASN_pR)/2;


A_MeanASN = ...
    (A_ASN_p0 + A_ASN_pA)/2;


RejectTable.MeanASN = ...
    R_MeanASN;


AcceptTable.MeanASN = ...
    A_MeanASN;


%% =========================================================
% 9. 绘制 pR 与 ASN
%% =========================================================

figure;

plot( ...
    pR_list, ...
    R_ASN_p0, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    pR_list, ...
    R_ASN_pR, ...
    '-s', ...
    'LineWidth',1.5);

plot( ...
    pR_list, ...
    R_MeanASN, ...
    '-^', ...
    'LineWidth',1.5);


xlabel('Rejection Quality Level p_R');

ylabel('Average Sample Number');

title('Sensitivity of ASN to p_R');

legend( ...
    'True p = 0.10', ...
    'True p = p_R', ...
    'Mean ASN', ...
    'Location','best');

grid on;

box on;


exportgraphics( ...
    gcf, ...
    'problem1_pR_ASN_sensitivity.png', ...
    'Resolution',300);


%% =========================================================
% 10. 绘制 pR 与错误概率
%% =========================================================

figure;

plot( ...
    pR_list, ...
    R_FalseReject, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    pR_list, ...
    R_MissReject, ...
    '-s', ...
    'LineWidth',1.5);


yline( ...
    alpha_R, ...
    '--', ...
    'alpha = 0.05');


yline( ...
    beta_R, ...
    '--', ...
    'beta = 0.10');


xlabel('Rejection Quality Level p_R');

ylabel('Error Probability');

title('Error Rate Sensitivity to p_R');

legend( ...
    'False rejection', ...
    'Missed rejection', ...
    'Location','best');

grid on;

box on;


exportgraphics( ...
    gcf, ...
    'problem1_pR_error_sensitivity.png', ...
    'Resolution',300);


%% =========================================================
% 11. 绘制 pA 与 ASN
%% =========================================================

figure;

plot( ...
    pA_list, ...
    A_ASN_pA, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    pA_list, ...
    A_ASN_p0, ...
    '-s', ...
    'LineWidth',1.5);

plot( ...
    pA_list, ...
    A_MeanASN, ...
    '-^', ...
    'LineWidth',1.5);


xlabel('Acceptance Quality Level p_A');

ylabel('Average Sample Number');

title('Sensitivity of ASN to p_A');

legend( ...
    'True p = p_A', ...
    'True p = 0.10', ...
    'Mean ASN', ...
    'Location','best');

grid on;

box on;


exportgraphics( ...
    gcf, ...
    'problem1_pA_ASN_sensitivity.png', ...
    'Resolution',300);


%% =========================================================
% 12. 绘制 pA 与错误概率
%% =========================================================

figure;

plot( ...
    pA_list, ...
    A_FalseAccept, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    pA_list, ...
    A_MissAccept, ...
    '-s', ...
    'LineWidth',1.5);


yline( ...
    alpha_A, ...
    '--', ...
    'alpha = 0.10');


yline( ...
    beta_A, ...
    '--', ...
    'beta = 0.05');


xlabel('Acceptance Quality Level p_A');

ylabel('Error Probability');

title('Error Rate Sensitivity to p_A');

legend( ...
    'False acceptance', ...
    'Missed acceptance', ...
    'Location','best');

grid on;

box on;


exportgraphics( ...
    gcf, ...
    'problem1_pA_error_sensitivity.png', ...
    'Resolution',300);


%% =========================================================
% 13. 保存Excel
%% =========================================================

filename = ...
    'problem1_sprt_sensitivity.xlsx';


if exist(filename,'file')

    delete(filename);

end


writetable( ...
    RejectTable, ...
    filename, ...
    'Sheet', ...
    'pR敏感性');


writetable( ...
    AcceptTable, ...
    filename, ...
    'Sheet', ...
    'pA敏感性');


%% =========================================================
% 14. 输出推荐方案
%
% 这里先不自动说哪一个最好，
% 因为最终要结合ASN和业务含义判断
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('敏感性分析完成\n');
fprintf('============================================================\n');

fprintf('\n拒收水平：\n');

for j = 1:nR

    fprintf( ...
        'pR=%.2f：平均ASN=%.3f，错误拒收=%.4f，漏拒=%.4f\n', ...
        pR_list(j), ...
        R_MeanASN(j), ...
        R_FalseReject(j), ...
        R_MissReject(j));

end


fprintf('\n接收水平：\n');

for j = 1:nA

    fprintf( ...
        'pA=%.2f：平均ASN=%.3f，错误接收=%.4f，漏接=%.4f\n', ...
        pA_list(j), ...
        A_MeanASN(j), ...
        A_FalseAccept(j), ...
        A_MissAccept(j));

end


fprintf('\n结果文件：%s\n',filename);

fprintf('============================================================\n');


%% =========================================================
%%               以下是局部函数
%% =========================================================


function result = monte_carlo_upper( ...
    p0, ...
    p1, ...
    alpha, ...
    beta, ...
    true_p, ...
    trials, ...
    max_n)

%% =========================================================
% Monte Carlo模拟一个SPRT
%
% 输出：
%
% ASN
% UpperProb
% LowerProb
% TruncateProb
%% =========================================================


sampleN = zeros(trials,1);


upperCount = 0;

lowerCount = 0;

truncateCount = 0;


for k = 1:trials

    [decision,n] = ...
        sprt_once_simple( ...
        p0, ...
        p1, ...
        alpha, ...
        beta, ...
        true_p, ...
        max_n);


    sampleN(k) = n;


    if decision == 1

        upperCount = ...
            upperCount + 1;

    elseif decision == -1

        lowerCount = ...
            lowerCount + 1;

    else

        truncateCount = ...
            truncateCount + 1;

    end

end


result.ASN = ...
    mean(sampleN);


result.UpperProb = ...
    upperCount/trials;


result.LowerProb = ...
    lowerCount/trials;


result.TruncateProb = ...
    truncateCount/trials;

end



function [decision,n] = sprt_once_simple( ...
    p0, ...
    p1, ...
    alpha, ...
    beta, ...
    true_p, ...
    max_n)

%% =========================================================
% 单次SPRT
%
% decision:
%
% 1  = 达到上边界
% -1 = 达到下边界
% 0  = 达到max_n仍未判定
%% =========================================================


%% Wald边界

lower = ...
    log(beta/(1-alpha));


upper = ...
    log((1-beta)/alpha);


%% LLR增量

badStep = ...
    log(p1/p0);


goodStep = ...
    log((1-p1)/(1-p0));


%% 初始化

llr = 0;


for n = 1:max_n


    %% 随机产生一个样本
    %
    % x=1 次品
    % x=0 合格

    x = ...
        rand < true_p;


    %% 更新LLR

    if x == 1

        llr = ...
            llr + badStep;

    else

        llr = ...
            llr + goodStep;

    end


    %% 上边界

    if llr >= upper

        decision = 1;

        return;

    end


    %% 下边界

    if llr <= lower

        decision = -1;

        return;

    end

end


%% 达到最大样本数仍未跨界

decision = 0;

end