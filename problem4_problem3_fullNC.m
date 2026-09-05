clc;
clear;
close all;

%% =========================================================
% 2024 B题 问题4
% 基于完整SPRT (N,C)联合分布
% 重新完成问题3
%
% 核心：
%
% 第一题完整(N,C)
%       ↓
% Beta后验
%       ↓
% Monte Carlo生成12个真实次品率
%       ↓
% 65536个固定生产策略
%       ↓
% 同一批随机质量场景下比较
%       ↓
% 后验平均利润最大化
%
%% =========================================================


%% =========================================================
% 1. Monte Carlo次数
%% =========================================================

M = 10000;

rng(2026);


%% =========================================================
% 2. 读取问题1完整(N,C)样本池
%% =========================================================

load( ...
    'problem1_sprt_NC_samples.mat', ...
    'pool05', ...
    'pool10', ...
    'pool20');

fprintf('\n完整(N,C)抽样样本读取成功。\n');


%% =========================================================
% 3. 问题3原始参数
%% =========================================================

%% 8个零件名义次品率

pPart_nom = ...
    0.10 * ones(1,8);


%% 8个零件购买价格

partPrice = ...
    [2 8 12 2 8 12 8 12];


%% 8个零件检测成本

partDetect = ...
    [1 1 2 1 1 2 1 2];


%% 三个半成品参数

pSemi_nom = ...
    [0.10 0.10 0.10];

semiAssembly = ...
    [8 8 8];

semiDetect = ...
    [4 4 4];

semiDisassembly = ...
    [6 6 6];


%% 最终成品参数

pFinal_nom = 0.10;

finalAssembly = 8;

finalDetect = 6;

finalDisassembly = 10;

salePrice = 200;

replacementLoss = 40;


%% =========================================================
% 4. 原问题3最优方案
%
% 顺序：
%
% x1...x8
% y1 y2 y3
% z
% u1 u2 u3
% v
%
%% =========================================================

OriginalStrategy = ...
    "1111111111101111";


%% =========================================================
% 5. 生成Monte Carlo随机次品率
%
% 一共有：
%
% 8个零件
% 3个半成品
% 1个最终成品
%
% 共12个随机参数
%% =========================================================

fprintf('\n正在生成12个次品率随机场景...\n');


pPart_mc = zeros(M,8);


for i = 1:8

    pPart_mc(:,i) = ...
        generate_p_from_fullNC( ...
        pPart_nom(i), ...
        M, ...
        pool05,pool10,pool20);

end


pSemi_mc = zeros(M,3);


for j = 1:3

    pSemi_mc(:,j) = ...
        generate_p_from_fullNC( ...
        pSemi_nom(j), ...
        M, ...
        pool05,pool10,pool20);

end


pFinal_mc = ...
    generate_p_from_fullNC( ...
    pFinal_nom, ...
    M, ...
    pool05,pool10,pool20);


fprintf('随机质量场景生成完成。\n');


%% =========================================================
% 6. 枚举65536种策略
%% =========================================================

numStrategies = 2^16;


MeanProfit = zeros(numStrategies,1);

StdProfit = zeros(numStrategies,1);

Q05Profit = zeros(numStrategies,1);


%% 每个Monte Carlo场景当前最好的利润

BestProfitScenario = ...
    -inf(M,1);


%% 每个场景当前最优策略编号

BestStrategyScenario = ...
    zeros(M,1);


fprintf('\n');
fprintf('============================================================\n');
fprintf('开始枚举65536种策略\n');
fprintf('Monte Carlo场景数：%d\n',M);
fprintf('============================================================\n');


tic;


%% =========================================================
% 7. 主循环
%% =========================================================

for strategyID = 0:numStrategies-1


    %% -----------------------------------------------------
    % 把0~65535转换成16位0/1
    %% -----------------------------------------------------

    bits = ...
        bitget(strategyID,16:-1:1);


    %% 零件检测

    x = bits(1:8);


    %% 半成品检测

    y = bits(9:11);


    %% 最终成品检测

    z = bits(12);


    %% 半成品拆解

    u = bits(13:15);


    %% 最终产品拆解

    v = bits(16);


    %% =====================================================
    % 8. 建立8个零件节点
    %% =====================================================

    part = cell(1,8);


    for i = 1:8


        p = pPart_mc(:,i);


        if x(i) == 1


            %% 检测零件：
            % 反复购买+检测直到获得合格件

            part{i}.C = ...
                (partPrice(i)+partDetect(i)) ...
                ./ (1-p);


            part{i}.g = ...
                ones(M,1);


            part{i}.inspected = 1;


            %% 若上级拆解后发现这个孩子有问题，
            % 对已检零件实际上不会发生
            %
            % R仍定义为获得一个合格零件所需成本

            part{i}.R = ...
                (partPrice(i)+partDetect(i)) ...
                ./ (1-p);


        else


            %% 不检测

            part{i}.C = ...
                partPrice(i) ...
                * ones(M,1);


            part{i}.g = ...
                1-p;


            part{i}.inspected = 0;


            %% 拆解后若发现原零件有问题，
            % 重新购买+检测直到合格

            part{i}.R = ...
                (partPrice(i)+partDetect(i)) ...
                ./ (1-p);

        end


        part{i}.detectCost = ...
            partDetect(i);

    end


    %% =====================================================
    % 9. 三个半成品
    %
    % 半成品1：零件1,2,3
    % 半成品2：零件4,5,6
    % 半成品3：零件7,8
    %% =====================================================

    semi1 = evaluate_node_mc( ...
        {part{1},part{2},part{3}}, ...
        pSemi_mc(:,1), ...
        semiAssembly(1), ...
        semiDetect(1), ...
        semiDisassembly(1), ...
        y(1), ...
        u(1));


    semi2 = evaluate_node_mc( ...
        {part{4},part{5},part{6}}, ...
        pSemi_mc(:,2), ...
        semiAssembly(2), ...
        semiDetect(2), ...
        semiDisassembly(2), ...
        y(2), ...
        u(2));


    semi3 = evaluate_node_mc( ...
        {part{7},part{8}}, ...
        pSemi_mc(:,3), ...
        semiAssembly(3), ...
        semiDetect(3), ...
        semiDisassembly(3), ...
        y(3), ...
        u(3));


    %% =====================================================
    % 10. 最终产品
    %% =====================================================

    ExpectedCost = ...
        evaluate_final_mc( ...
        {semi1,semi2,semi3}, ...
        pFinal_mc, ...
        finalAssembly, ...
        finalDetect, ...
        finalDisassembly, ...
        replacementLoss, ...
        z, ...
        v);


    %% =====================================================
    % 11. 利润
    %% =====================================================

    Profit = ...
        salePrice - ExpectedCost;


    %% =====================================================
    % 12. 当前策略统计指标
    %% =====================================================

    idx = strategyID + 1;


    MeanProfit(idx) = ...
        mean(Profit);


    StdProfit(idx) = ...
        std(Profit);


    Q05Profit(idx) = ...
        percentile_local(Profit,0.05);


    %% =====================================================
    % 13. 更新每一个随机场景的最优策略
    %
    % 这只是用来计算：
    %
    % “某策略如果真实p已知，有多少场景会成为最优”
    %
    % 主决策仍然是平均利润最大化
    %% =====================================================

    better = ...
        Profit > BestProfitScenario;


    BestProfitScenario(better) = ...
        Profit(better);


    BestStrategyScenario(better) = ...
        idx;


    %% =====================================================
    % 14. 打印进度
    %% =====================================================

    if mod(idx,4096) == 0

        fprintf( ...
            '已完成 %d / %d，%.1f%%\n', ...
            idx, ...
            numStrategies, ...
            100*idx/numStrategies);

    end

end


elapsedTime = toc;


fprintf('\n枚举完成，耗时 %.2f 秒。\n', ...
    elapsedTime);


%% =========================================================
% 15. 找后验平均利润最大的策略
%% =========================================================

[bestMeanProfit,bestID] = ...
    max(MeanProfit);


bestBits = ...
    bitget(bestID-1,16:-1:1);


BestStrategy = ...
    sprintf('%d',bestBits);


BestStd = ...
    StdProfit(bestID);


BestQ05 = ...
    Q05Profit(bestID);


%% =========================================================
% 16. 计算各策略成为“场景最优”的概率
%% =========================================================

BestCount = ...
    accumarray( ...
    BestStrategyScenario, ...
    1, ...
    [numStrategies,1]);


BestProbability_All = ...
    BestCount / M;


BestProbability = ...
    BestProbability_All(bestID);


%% =========================================================
% 17. 原问题3策略对应编号
%% =========================================================

originalBits = ...
    double(char(OriginalStrategy)-'0');


originalID = 1;


for k = 1:16

    originalID = ...
        originalID ...
        + originalBits(k) ...
        * 2^(16-k);

end


OriginalMeanProfit = ...
    MeanProfit(originalID);


OriginalStd = ...
    StdProfit(originalID);


OriginalQ05 = ...
    Q05Profit(originalID);


OriginalBestProbability = ...
    BestProbability_All(originalID);


%% =========================================================
% 18. 判断策略是否变化
%% =========================================================

if string(BestStrategy) == OriginalStrategy

    StrategyChanged = "未改变";

else

    StrategyChanged = "发生改变";

end


%% =========================================================
% 19. 找平均利润前10名
%% =========================================================

[sortedMean,order] = ...
    sort(MeanProfit,'descend');


topN = 10;


TopStrategy = ...
    strings(topN,1);


TopMeanProfit = ...
    zeros(topN,1);


TopStdProfit = ...
    zeros(topN,1);


TopQ05Profit = ...
    zeros(topN,1);


TopBestProbability = ...
    zeros(topN,1);


for k = 1:topN


    id = order(k);


    bits = ...
        bitget(id-1,16:-1:1);


    TopStrategy(k) = ...
        sprintf('%d',bits);


    TopMeanProfit(k) = ...
        MeanProfit(id);


    TopStdProfit(k) = ...
        StdProfit(id);


    TopQ05Profit(k) = ...
        Q05Profit(id);


    TopBestProbability(k) = ...
        BestProbability_All(id);

end


TopTable = table( ...
    (1:topN)', ...
    TopStrategy, ...
    TopMeanProfit, ...
    TopStdProfit, ...
    TopQ05Profit, ...
    TopBestProbability, ...
    'VariableNames', { ...
    'Rank', ...
    'Strategy', ...
    'MeanProfit', ...
    'StdProfit', ...
    'Q05Profit', ...
    'BestProbability'});


%% =========================================================
% 20. 最终汇总表
%% =========================================================

SummaryTable = table( ...
    OriginalStrategy, ...
    string(BestStrategy), ...
    OriginalMeanProfit, ...
    bestMeanProfit, ...
    BestStd, ...
    BestQ05, ...
    BestProbability, ...
    OriginalBestProbability, ...
    StrategyChanged, ...
    elapsedTime, ...
    'VariableNames', { ...
    'OriginalStrategy', ...
    'FullNCBestStrategy', ...
    'OriginalMeanProfit', ...
    'BestMeanProfit', ...
    'BestStdProfit', ...
    'BestQ05Profit', ...
    'BestProbability', ...
    'OriginalBestProbability', ...
    'StrategyChanged', ...
    'ElapsedSeconds'});


%% =========================================================
% 21. 输出结果
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('问题4——问题3最终结果\n');
fprintf('============================================================\n');


fprintf('\n原问题3策略：%s\n', ...
    OriginalStrategy);


fprintf('考虑完整(N,C)后最优策略：%s\n', ...
    BestStrategy);


fprintf('\n后验平均利润：%.6f 元\n', ...
    bestMeanProfit);


fprintf('利润标准差：%.6f 元\n', ...
    BestStd);


fprintf('5%%利润分位：%.6f 元\n', ...
    BestQ05);


fprintf('成为场景最优策略概率：%.2f%%\n', ...
    100*BestProbability);


fprintf('\n原策略后验平均利润：%.6f 元\n', ...
    OriginalMeanProfit);


fprintf('原策略成为场景最优概率：%.2f%%\n', ...
    100*OriginalBestProbability);


fprintf('\n策略变化：%s\n', ...
    StrategyChanged);


fprintf('\n平均利润前10名：\n');

disp(TopTable);


%% =========================================================
% 22. 保存Excel
%% =========================================================

filename = ...
    'problem4_problem3_fullNC_result.xlsx';


if exist(filename,'file')

    delete(filename);

end


writetable( ...
    SummaryTable, ...
    filename, ...
    'Sheet', ...
    '最终结果');


writetable( ...
    TopTable, ...
    filename, ...
    'Sheet', ...
    '平均利润前10');


%% =========================================================
% 23. 保存全部65536种策略
%% =========================================================

AllStrategyCode = ...
    strings(numStrategies,1);


for id = 1:numStrategies

    bits = ...
        bitget(id-1,16:-1:1);

    AllStrategyCode(id) = ...
        sprintf('%d',bits);

end


AllStrategyTable = table( ...
    AllStrategyCode, ...
    MeanProfit, ...
    StdProfit, ...
    Q05Profit, ...
    BestProbability_All, ...
    'VariableNames', { ...
    'Strategy', ...
    'MeanProfit', ...
    'StdProfit', ...
    'Q05Profit', ...
    'BestProbability'});


writetable( ...
    AllStrategyTable, ...
    filename, ...
    'Sheet', ...
    '全部65536策略');


fprintf('\n结果文件：%s\n',filename);


%% =========================================================
%%                       局部函数
%% =========================================================


function p = ...
    generate_p_from_fullNC( ...
    nominal,M,pool05,pool10,pool20)

%% 根据名义次品率选择对应SPRT样本池

if abs(nominal-0.05) < 1e-10

    pool = pool05;

elseif abs(nominal-0.10) < 1e-10

    pool = pool10;

elseif abs(nominal-0.20) < 1e-10

    pool = pool20;

else

    error('只支持0.05、0.10、0.20');

end


%% 随机抽取(N,C)

K = length(pool.N);

idx = randi(K,M,1);


N = pool.N(idx);

C = pool.C(idx);


%% Beta(1,1)先验后的后验参数

A = C + 1;

B = N - C + 1;


%% Beta随机变量

U = randg(A);

V = randg(B);


p = ...
    U ./ (U+V);

end



function node = evaluate_node_mc( ...
    children, ...
    pNode, ...
    assemblyCost, ...
    detectCost, ...
    disassemblyCost, ...
    inspectNode, ...
    disassembleNode)

%% =========================================================
% 半成品节点的向量化递推
%% =========================================================

M = length(pNode);


childCost = zeros(M,1);

childGood = ones(M,1);


for i = 1:length(children)

    childCost = ...
        childCost + children{i}.C;

    childGood = ...
        childGood .* children{i}.g;

end


BaseCost = ...
    childCost + assemblyCost;


G = ...
    childGood .* (1-pNode);


q = ...
    1-G;


%% =========================================================
% 拆解后的子节点恢复成本
%% =========================================================

RecoveryCost = ...
    zeros(M,1);


for i = 1:length(children)


    child = children{i};


    if child.inspected == 0


        %% 子节点坏 => 父节点一定坏

        probBadGivenFail = ...
            (1-child.g) ./ q;


        probBadGivenFail = ...
            min(max(probBadGivenFail,0),1);


        RecoveryCost = ...
            RecoveryCost ...
            + child.detectCost ...
            + probBadGivenFail ...
            .* child.R;

    end

end


%% =========================================================
% 若半成品不拆解
%% =========================================================

if disassembleNode == 0


    %% 得到一个最终合格半成品的成本

    K = ...
        (BaseCost + detectCost) ...
        ./ G;


    R = K;


%% =========================================================
% 若半成品拆解
%% =========================================================

else


    %% 已获得已知合格子节点后，
    % 重复装配直到半成品合格

    W = ...
        ( ...
        assemblyCost ...
        + detectCost ...
        + pNode .* disassemblyCost ...
        ) ...
        ./ (1-pNode);


    R = ...
        disassemblyCost ...
        + RecoveryCost ...
        + W;


    K = ...
        BaseCost ...
        + detectCost ...
        + q .* R;

end


%% =========================================================
% 半成品是否在装配后检测
%% =========================================================

if inspectNode == 1


    node.C = K;

    node.g = ...
        ones(M,1);


else


    node.C = ...
        BaseCost;

    node.g = G;

end


node.detectCost = ...
    detectCost;


node.inspected = ...
    inspectNode;


node.R = ...
    R;

end



function ExpectedCost = evaluate_final_mc( ...
    children, ...
    pFinal, ...
    assemblyCost, ...
    detectCost, ...
    disassemblyCost, ...
    replacementLoss, ...
    inspectFinal, ...
    disassembleFinal)

%% =========================================================
% 最终产品节点向量化递推
%% =========================================================

M = length(pFinal);


childCost = ...
    zeros(M,1);


childGood = ...
    ones(M,1);


for i = 1:length(children)

    childCost = ...
        childCost + children{i}.C;

    childGood = ...
        childGood .* children{i}.g;

end


BaseCost = ...
    childCost + assemblyCost;


G = ...
    childGood .* (1-pFinal);


q = ...
    1-G;


%% =========================================================
% 最终拆解后的半成品恢复成本
%% =========================================================

RecoveryCost = ...
    zeros(M,1);


for i = 1:length(children)


    child = children{i};


    if child.inspected == 0


        probBadGivenFail = ...
            (1-child.g) ./ q;


        probBadGivenFail = ...
            min(max(probBadGivenFail,0),1);


        RecoveryCost = ...
            RecoveryCost ...
            + child.detectCost ...
            + probBadGivenFail ...
            .* child.R;

    end

end


%% =========================================================
% 情况1：检测成品，不拆解
%% =========================================================

if inspectFinal == 1 && ...
        disassembleFinal == 0


    ExpectedCost = ...
        (BaseCost + detectCost) ...
        ./ G;


%% =========================================================
% 情况2：检测成品，并拆解
%% =========================================================

elseif inspectFinal == 1 && ...
        disassembleFinal == 1


    W = ...
        ( ...
        assemblyCost ...
        + detectCost ...
        + pFinal .* disassemblyCost ...
        ) ...
        ./ (1-pFinal);


    ExpectedCost = ...
        BaseCost ...
        + detectCost ...
        + q .* ...
        ( ...
        disassemblyCost ...
        + RecoveryCost ...
        + W ...
        );


%% =========================================================
% 情况3：不检测成品，不拆解
%% =========================================================

elseif inspectFinal == 0 && ...
        disassembleFinal == 0


    ExpectedCost = ...
        ( ...
        BaseCost ...
        + q .* replacementLoss ...
        ) ...
        ./ G;


%% =========================================================
% 情况4：不检测成品，但退回后拆解
%% =========================================================

else


    W = ...
        ( ...
        assemblyCost ...
        + pFinal .* ...
        ( ...
        replacementLoss ...
        + disassemblyCost ...
        ) ...
        ) ...
        ./ (1-pFinal);


    ExpectedCost = ...
        BaseCost ...
        + q .* ...
        ( ...
        replacementLoss ...
        + disassemblyCost ...
        + RecoveryCost ...
        + W ...
        );

end

end



function q = percentile_local(x,p)

x = sort(x);

N = length(x);

idx = ceil(p*N);

idx = max(1,min(N,idx));

q = x(idx);

end