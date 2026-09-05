clc;
clear;

%% =========================================================
% test_final.m
%
% 测试 evaluate_final.m
%
% 为了方便手工核算，
% 假设三个半成品都已经检测过并确认合格。
%
% 因此：
%
% g1 = g2 = g3 = 1
%
% 三个半成品进入最终装配时不存在质量风险，
% 最终产品失败只可能来自最终装配过程。
%% =========================================================


%% =========================================================
% 1. 构造三个简单的半成品节点
%% =========================================================

semis = repmat( ...
    struct( ...
    'C',0, ...
    'g',0, ...
    'detectCost',0, ...
    'inspected',0, ...
    'R',0), ...
    1,3);


%% 假设三个半成品的成本均为20元

for i = 1:3

    semis(i).C = 20;

    % 已经检测确认合格
    semis(i).g = 1;

    % 半成品检测费
    semis(i).detectCost = 4;

    % 已经检测过
    semis(i).inspected = 1;

    % 本测试中不会调用R
    semis(i).R = 0;

end


%% =========================================================
% 2. 最终成品参数
%% =========================================================

p_final = 0.10;

assemblyCost = 8;

detectCost = 6;

disassemblyCost = 10;

replacementLoss = 40;


%% =========================================================
% 3. 手工基础量
%
% 三个半成品总成本：
%
% 20 + 20 + 20 = 60
%
% 加最终装配费：
%
% BaseCost = 68
%
% 最终装配成功率：
%
% G = 0.9
%
% q = 0.1
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('evaluate_final.m 四种情况测试\n');
fprintf('============================================================\n');


%% =========================================================
% 情况1
%
% 检测最终成品
% 不拆解
%
% inspectFinal = 1
% disassembleFinal = 0
%% =========================================================

inspectFinal = 1;

disassembleFinal = 0;


result1 = evaluate_final( ...
    semis, ...
    p_final, ...
    assemblyCost, ...
    detectCost, ...
    disassemblyCost, ...
    replacementLoss, ...
    inspectFinal, ...
    disassembleFinal);


fprintf('\n');
fprintf('---------------- 情况1 ----------------\n');
fprintf('最终成品：检测\n');
fprintf('次品：不拆解\n');

fprintf('合格率 = %.6f\n', ...
    result1.goodRate);

fprintf('次品率 = %.6f\n', ...
    result1.defectRate);

fprintf('RecoveryCost = %.6f\n', ...
    result1.recoveryCost);

fprintf('ExpectedCost = %.6f 元\n', ...
    result1.C);


%% =========================================================
% 情况2
%
% 检测最终成品
% 拆解
%% =========================================================

inspectFinal = 1;

disassembleFinal = 1;


result2 = evaluate_final( ...
    semis, ...
    p_final, ...
    assemblyCost, ...
    detectCost, ...
    disassemblyCost, ...
    replacementLoss, ...
    inspectFinal, ...
    disassembleFinal);


fprintf('\n');
fprintf('---------------- 情况2 ----------------\n');
fprintf('最终成品：检测\n');
fprintf('次品：拆解\n');

fprintf('合格率 = %.6f\n', ...
    result2.goodRate);

fprintf('次品率 = %.6f\n', ...
    result2.defectRate);

fprintf('RecoveryCost = %.6f\n', ...
    result2.recoveryCost);

fprintf('W = %.6f 元\n', ...
    result2.W);

fprintf('ExpectedCost = %.6f 元\n', ...
    result2.C);


%% =========================================================
% 情况3
%
% 不检测最终成品
% 不拆解
%% =========================================================

inspectFinal = 0;

disassembleFinal = 0;


result3 = evaluate_final( ...
    semis, ...
    p_final, ...
    assemblyCost, ...
    detectCost, ...
    disassemblyCost, ...
    replacementLoss, ...
    inspectFinal, ...
    disassembleFinal);


fprintf('\n');
fprintf('---------------- 情况3 ----------------\n');
fprintf('最终成品：不检测\n');
fprintf('退回次品：不拆解\n');

fprintf('合格率 = %.6f\n', ...
    result3.goodRate);

fprintf('次品率 = %.6f\n', ...
    result3.defectRate);

fprintf('RecoveryCost = %.6f\n', ...
    result3.recoveryCost);

fprintf('ExpectedCost = %.6f 元\n', ...
    result3.C);


%% =========================================================
% 情况4
%
% 不检测最终成品
% 拆解
%% =========================================================

inspectFinal = 0;

disassembleFinal = 1;


result4 = evaluate_final( ...
    semis, ...
    p_final, ...
    assemblyCost, ...
    detectCost, ...
    disassemblyCost, ...
    replacementLoss, ...
    inspectFinal, ...
    disassembleFinal);


fprintf('\n');
fprintf('---------------- 情况4 ----------------\n');
fprintf('最终成品：不检测\n');
fprintf('退回次品：拆解\n');

fprintf('合格率 = %.6f\n', ...
    result4.goodRate);

fprintf('次品率 = %.6f\n', ...
    result4.defectRate);

fprintf('RecoveryCost = %.6f\n', ...
    result4.recoveryCost);

fprintf('W = %.6f 元\n', ...
    result4.W);

fprintf('ExpectedCost = %.6f 元\n', ...
    result4.C);


%% =========================================================
% 4. 汇总
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('四种情况期望成本汇总\n');
fprintf('============================================================\n');

fprintf('检测 + 不拆解：%.6f 元\n', ...
    result1.C);

fprintf('检测 + 拆解：  %.6f 元\n', ...
    result2.C);

fprintf('不检测 + 不拆解：%.6f 元\n', ...
    result3.C);

fprintf('不检测 + 拆解：  %.6f 元\n', ...
    result4.C);

fprintf('============================================================\n');
fprintf('测试结束\n');
fprintf('============================================================\n');