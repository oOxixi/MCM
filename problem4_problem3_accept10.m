clc;
clear;
close all;

%% =========================================================
% 2024 B题 问题4 —— 重新完成问题3
%
% B版：
% 对名义次品率 p=0.10
% 使用“接收侧SPRT”生成完整(N,C)分布
%
% H0: p = 0.10
% H1: p = 0.05
%
% alpha = 0.10
% beta  = 0.05
%
% 然后：
%
% SPRT完整(N,C)
%       ↓
% Beta(C+1,N-C+1)
%       ↓
% Monte Carlo生成12个真实次品率
%       ↓
% 枚举65536种生产策略
%       ↓
% 后验平均利润最大化
%% =========================================================


%% =========================================================
% 1. 参数
%% =========================================================

M_pool = 10000;

M = 10000;

max_n = 10000;


%% =========================================================
% 2. 生成p=0.10的完整(N,C)样本池
%
% 接收侧：
%
% H0 = 0.10
% H1 = 0.05
%% =========================================================

rng(2026);

fprintf('\n');
fprintf('============================================================\n');
fprintf('B版：10%%采用接收侧SPRT\n');
fprintf('正在生成p=0.10时完整(N,C)样本池...\n');
fprintf('============================================================\n');


pool10 = simulate_NC_pool( ...
    0.10, ...
    0.05, ...
    0.10, ...
    0.05, ...
    0.10, ...
    M_pool, ...
    max_n);


fprintf('\n接收侧SPRT在真实p=0.10时：\n');

fprintf('平均停止样本量 = %.3f\n', ...
    mean(pool10.N));

fprintf('中位数N = %.0f\n', ...
    percentile_local(pool10.N,0.50));

fprintf('90%%分位N = %.0f\n', ...
    percentile_local(pool10.N,0.90));

fprintf('95%%分位N = %.0f\n', ...
    percentile_local(pool10.N,0.95));

fprintf('平均次品数C = %.3f\n', ...
    mean(pool10.C));


%% =========================================================
% 3. 问题3参数
%% =========================================================

partPrice = ...
    [2 8 12 2 8 12 8 12];


partDetect = ...
    [1 1 2 1 1 2 1 2];


semiAssembly = ...
    [8 8 8];


semiDetect = ...
    [4 4 4];


semiDisassembly = ...
    [6 6 6];


finalAssembly = 8;

finalDetect = 6;

finalDisassembly = 10;

salePrice = 200;

replacementLoss = 40;


%% =========================================================
% 4. 原问题3最优策略
%% =========================================================

OriginalStrategy = ...
    "1111111111101111";


%% =========================================================
% 5. 生成12个真实次品率随机场景
%% =========================================================

rng(3001);


fprintf('\n正在生成12个随机次品率场景...\n');


pPart_mc = ...
    zeros(M,8);


for i = 1:8

    pPart_mc(:,i) = ...
        generate_p_from_pool( ...
        pool10,M);

end


pSemi_mc = ...
    zeros(M,3);


for i = 1:3

    pSemi_mc(:,i) = ...
        generate_p_from_pool( ...
        pool10,M);

end


pFinal_mc = ...
    generate_p_from_pool( ...
    pool10,M);


fprintf('随机质量场景生成完成。\n');


%% =========================================================
% 6. 65536种策略
%% =========================================================

numStrategies = ...
    2^16;


MeanProfit = ...
    zeros(numStrategies,1);


StdProfit = ...
    zeros(numStrategies,1);


Q05Profit = ...
    zeros(numStrategies,1);


BestProfitScenario = ...
    -inf(M,1);


BestStrategyScenario = ...
    ones(M,1);


%% =========================================================
% 7. 开始枚举
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('开始枚举65536种策略\n');
fprintf('Monte Carlo场景数：%d\n',M);
fprintf('============================================================\n');


tic;


for strategyID = 0:numStrategies-1


    bits = ...
        bitget(strategyID,16:-1:1);


    %% 零件检测

    x = ...
        bits(1:8);


    %% 半成品检测

    y = ...
        bits(9:11);


    %% 最终检测

    z = ...
        bits(12);


    %% 半成品拆解

    u = ...
        bits(13:15);


    %% 最终产品拆解

    v = ...
        bits(16);


    %% =====================================================
    % 8. 八个零件
    %% =====================================================

    part = ...
        cell(1,8);


    for i = 1:8


        p = ...
            pPart_mc(:,i);


        part{i}.detectCost = ...
            partDetect(i);


        if x(i) == 1


            part{i}.C = ...
                (partPrice(i)+partDetect(i)) ...
                ./ (1-p);


            part{i}.g = ...
                ones(M,1);


            part{i}.inspected = ...
                1;


            part{i}.R = ...
                (partPrice(i)+partDetect(i)) ...
                ./ (1-p);


        else


            part{i}.C = ...
                partPrice(i) ...
                * ones(M,1);


            part{i}.g = ...
                1-p;


            part{i}.inspected = ...
                0;


            part{i}.R = ...
                (partPrice(i)+partDetect(i)) ...
                ./ (1-p);

        end

    end


    %% =====================================================
    % 9. 三个半成品
    %% =====================================================

    semi1 = ...
        evaluate_node_mc( ...
        {part{1},part{2},part{3}}, ...
        pSemi_mc(:,1), ...
        semiAssembly(1), ...
        semiDetect(1), ...
        semiDisassembly(1), ...
        y(1), ...
        u(1));


    semi2 = ...
        evaluate_node_mc( ...
        {part{4},part{5},part{6}}, ...
        pSemi_mc(:,2), ...
        semiAssembly(2), ...
        semiDetect(2), ...
        semiDisassembly(2), ...
        y(2), ...
        u(2));


    semi3 = ...
        evaluate_node_mc( ...
        {part{7},part{8}}, ...
        pSemi_mc(:,3), ...
        semiAssembly(3), ...
        semiDetect(3), ...
        semiDisassembly(3), ...
        y(3), ...
        u(3));


    %% =====================================================
    % 10. 最终成品
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
        salePrice ...
        - ExpectedCost;


    idx = ...
        strategyID + 1;


    MeanProfit(idx) = ...
        mean(Profit);


    StdProfit(idx) = ...
        std(Profit);


    Q05Profit(idx) = ...
        percentile_local( ...
        Profit,0.05);


    %% 场景最优

    better = ...
        Profit > BestProfitScenario;


    BestProfitScenario(better) = ...
        Profit(better);


    BestStrategyScenario(better) = ...
        idx;


    %% 显示进度

    if mod(idx,4096) == 0

        fprintf( ...
            '已完成 %d / %d，%.1f%%\n', ...
            idx, ...
            numStrategies, ...
            100*idx/numStrategies);

    end

end


elapsedTime = ...
    toc;


fprintf('\n枚举完成！耗时 %.2f 秒。\n', ...
    elapsedTime);


%% =========================================================
% 12. 平均利润最大策略
%% =========================================================

[bestMeanProfit,bestID] = ...
    max(MeanProfit);


BestStrategy = ...
    string( ...
    dec2bin(bestID-1,16));


BestStd = ...
    StdProfit(bestID);


BestQ05 = ...
    Q05Profit(bestID);


%% =========================================================
% 13. 场景最优概率
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
% 14. 原问题3方案
%% =========================================================

originalID = ...
    bin2dec( ...
    char(OriginalStrategy)) ...
    + 1;


OriginalMeanProfit = ...
    MeanProfit(originalID);


OriginalStdProfit = ...
    StdProfit(originalID);


OriginalQ05Profit = ...
    Q05Profit(originalID);


OriginalBestProbability = ...
    BestProbability_All(originalID);


%% =========================================================
% 15. 判断策略变化
%% =========================================================

if BestStrategy == OriginalStrategy

    StrategyChanged = ...
        "未改变";

else

    StrategyChanged = ...
        "发生改变";

end


%% =========================================================
% 16. 找平均利润前10名
%% =========================================================

[~,order] = ...
    sort( ...
    MeanProfit, ...
    'descend');


topN = 10;


TopRank = ...
    (1:topN)';


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


    id = ...
        order(k);


    TopStrategy(k) = ...
        string( ...
        dec2bin(id-1,16));


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
    TopRank, ...
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
% 17. 汇总
%% =========================================================

SamplingMethod = ...
    "10%采用接收侧SPRT";


SummaryTable = table( ...
    SamplingMethod, ...
    OriginalStrategy, ...
    BestStrategy, ...
    OriginalMeanProfit, ...
    bestMeanProfit, ...
    BestStd, ...
    BestQ05, ...
    BestProbability, ...
    OriginalBestProbability, ...
    StrategyChanged, ...
    elapsedTime, ...
    'VariableNames', { ...
    'SamplingMethod', ...
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
% 18. 输出
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('B版最终结果：10%%采用接收侧SPRT\n');
fprintf('============================================================\n');


fprintf('原问题3策略：%s\n', ...
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
% 19. 全部65536种策略
%% =========================================================

AllStrategyCode = ...
    strings(numStrategies,1);


for id = 1:numStrategies

    AllStrategyCode(id) = ...
        string( ...
        dec2bin(id-1,16));

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


%% =========================================================
% 20. SPRT样本池
%% =========================================================

N = ...
    pool10.N;


C = ...
    pool10.C;


LLR = ...
    pool10.LLR;


Boundary = ...
    pool10.Boundary;


PoolTable = ...
    table( ...
    N,C,LLR,Boundary);


%% =========================================================
% 21. 保存Excel
%% =========================================================

filename = ...
    'problem4_problem3_accept10_result.xlsx';


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


writetable( ...
    AllStrategyTable, ...
    filename, ...
    'Sheet', ...
    '全部65536策略');


writetable( ...
    PoolTable, ...
    filename, ...
    'Sheet', ...
    '10%SPRT样本');


fprintf('\n结果文件：%s\n',filename);


%% =========================================================
%%                     局部函数
%% =========================================================


function pool = simulate_NC_pool( ...
    p0,p1,alpha,beta,true_p,M,max_n)

lower = ...
    log(beta/(1-alpha));


upper = ...
    log((1-beta)/alpha);


badStep = ...
    log(p1/p0);


goodStep = ...
    log((1-p1)/(1-p0));


N_all = ...
    zeros(M,1);


C_all = ...
    zeros(M,1);


LLR_all = ...
    zeros(M,1);


Boundary_all = ...
    strings(M,1);


for k = 1:M


    llr = 0;

    c = 0;

    boundary = "";


    for n = 1:max_n


        x = ...
            rand < true_p;


        if x == 1


            c = ...
                c + 1;


            llr = ...
                llr + badStep;


        else


            llr = ...
                llr + goodStep;

        end


        if llr >= upper


            boundary = ...
                "Upper";


            break;

        end


        if llr <= lower


            boundary = ...
                "Lower";


            break;

        end

    end


    if boundary == ""


        if llr >= 0

            boundary = ...
                "TruncatedUpper";

        else

            boundary = ...
                "TruncatedLower";

        end

    end


    N_all(k) = n;

    C_all(k) = c;

    LLR_all(k) = llr;

    Boundary_all(k) = ...
        boundary;

end


pool.N = ...
    N_all;


pool.C = ...
    C_all;


pool.LLR = ...
    LLR_all;


pool.Boundary = ...
    Boundary_all;

end



function p = ...
    generate_p_from_pool(pool,M)

K = ...
    length(pool.N);


idx = ...
    randi(K,M,1);


N = ...
    pool.N(idx);


C = ...
    pool.C(idx);


A = ...
    C + 1;


B = ...
    N - C + 1;


U = ...
    randg(A);


V = ...
    randg(B);


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

M = ...
    length(pNode);


childCost = ...
    zeros(M,1);


childGood = ...
    ones(M,1);


for i = 1:length(children)


    childCost = ...
        childCost ...
        + children{i}.C;


    childGood = ...
        childGood ...
        .* children{i}.g;

end


BaseCost = ...
    childCost ...
    + assemblyCost;


G = ...
    childGood ...
    .* (1-pNode);


q = ...
    1-G;


RecoveryCost = ...
    zeros(M,1);


for i = 1:length(children)


    child = ...
        children{i};


    if child.inspected == 0


        probBadGivenFail = ...
            (1-child.g) ...
            ./ q;


        probBadGivenFail = ...
            min( ...
            max(probBadGivenFail,0), ...
            1);


        RecoveryCost = ...
            RecoveryCost ...
            + child.detectCost ...
            + probBadGivenFail ...
            .* child.R;

    end

end


if disassembleNode == 0


    K = ...
        (BaseCost + detectCost) ...
        ./ G;


    R = ...
        K;


else


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


if inspectNode == 1


    node.C = ...
        K;


    node.g = ...
        ones(M,1);


else


    node.C = ...
        BaseCost;


    node.g = ...
        G;

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

M = ...
    length(pFinal);


childCost = ...
    zeros(M,1);


childGood = ...
    ones(M,1);


for i = 1:length(children)


    childCost = ...
        childCost ...
        + children{i}.C;


    childGood = ...
        childGood ...
        .* children{i}.g;

end


BaseCost = ...
    childCost ...
    + assemblyCost;


G = ...
    childGood ...
    .* (1-pFinal);


q = ...
    1-G;


RecoveryCost = ...
    zeros(M,1);


for i = 1:length(children)


    child = ...
        children{i};


    if child.inspected == 0


        probBadGivenFail = ...
            (1-child.g) ...
            ./ q;


        probBadGivenFail = ...
            min( ...
            max(probBadGivenFail,0), ...
            1);


        RecoveryCost = ...
            RecoveryCost ...
            + child.detectCost ...
            + probBadGivenFail ...
            .* child.R;

    end

end


%% 检测，不拆解

if inspectFinal == 1 && ...
        disassembleFinal == 0


    ExpectedCost = ...
        (BaseCost + detectCost) ...
        ./ G;


%% 检测，拆解

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


%% 不检测，不拆解

elseif inspectFinal == 0 && ...
        disassembleFinal == 0


    ExpectedCost = ...
        ( ...
        BaseCost ...
        + q .* replacementLoss ...
        ) ...
        ./ G;


%% 不检测，但退回后拆解

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



function q = ...
    percentile_local(x,p)

x = ...
    sort(x);


N = ...
    length(x);


idx = ...
    ceil(p*N);


idx = ...
    max( ...
    1, ...
    min(N,idx));


q = ...
    x(idx);

end