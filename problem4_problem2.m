clc;
clear;
close all;

%% =========================================================
% 2024 全国大学生数学建模竞赛 B题
% 问题4 —— 重新完成问题2
%
% 核心思路：
%
% 问题2：
% 把次品率 p 当成确定常数
%
% 问题4：
% 认为这些次品率来自抽样检测，因此真实p存在不确定性
%
% 采用：
%
% SPRT代表性抽样结果
%        ↓
% Beta后验分布
%        ↓
% Monte Carlo随机生成真实次品率
%        ↓
% 每次重新计算问题2的16种生产策略
%        ↓
% 统计平均利润、标准差、5%分位数、最优概率
%
%% =========================================================


%% =========================================================
% 1. Monte Carlo 参数
%% =========================================================

M = 10000;

rng(2024);


%% =========================================================
% 2. 问题2原始数据
%
% 每列：
%
% 1  p1   零件1次品率
% 2  a1   零件1购买单价
% 3  d1   零件1检测成本
%
% 4  p2
% 5  a2
% 6  d2
%
% 7  pf   成品装配次品率
% 8  Ca   装配成本
% 9  Cf   成品检测成本
%
% 10 S   市场售价
% 11 L   调换损失
% 12 Cd  拆解费用
%% =========================================================

Data = [

    0.10  4  2   0.10  18  3   0.10  6  3   56   6   5;
    0.20  4  2   0.20  18  3   0.20  6  3   56   6   5;
    0.10  4  2   0.10  18  3   0.10  6  3   56  30   5;
    0.20  4  1   0.20  18  1   0.20  6  2   56  30   5;
    0.10  4  8   0.20  18  1   0.10  6  2   56  10   5;
    0.05  4  2   0.05  18  3   0.05  6  3   56  10  40

];


numCases = size(Data,1);


%% =========================================================
% 3. 原问题2得到的最优策略
%
% 用于和问题4结果比较
%% =========================================================

OriginalStrategy = [

    "1001"
    "1101"
    "1011"
    "1111"
    "0101"
    "0000"

];


%% =========================================================
% 4. 建立16种生产策略
%
% 顺序：
%
% x1 x2 x3 x4
%
% x1 = 是否检测零件1
% x2 = 是否检测零件2
% x3 = 是否检测成品
% x4 = 是否拆解不合格成品
%% =========================================================

Strategies = zeros(16,4);

StrategyCode = strings(16,1);

s = 0;


for x1 = 0:1

    for x2 = 0:1

        for x3 = 0:1

            for x4 = 0:1

                s = s + 1;

                Strategies(s,:) = ...
                    [x1 x2 x3 x4];

                StrategyCode(s) = ...
                    sprintf('%d%d%d%d', ...
                    x1,x2,x3,x4);

            end

        end

    end

end


%% =========================================================
% 5. 保存所有策略统计结果
%
% 每种情况16种策略
%
% 6×16 = 96行
%% =========================================================

totalRows = numCases * 16;


CaseID_all = zeros(totalRows,1);

Strategy_all = strings(totalRows,1);

X1_all = zeros(totalRows,1);

X2_all = zeros(totalRows,1);

X3_all = zeros(totalRows,1);

X4_all = zeros(totalRows,1);


MeanProfit_all = zeros(totalRows,1);

StdProfit_all = zeros(totalRows,1);

Q05Profit_all = zeros(totalRows,1);

BestProbability_all = zeros(totalRows,1);


%% =========================================================
% 6. 保存每种情况最终推荐结果
%% =========================================================

CaseID_summary = (1:numCases)';

Original_summary = OriginalStrategy;

MeanBestStrategy = strings(numCases,1);

RobustBestStrategy = strings(numCases,1);


MeanBestProfit = zeros(numCases,1);

MeanBestStd = zeros(numCases,1);

MeanBestQ05 = zeros(numCases,1);

MeanBestProbability = zeros(numCases,1);


RobustQ05 = zeros(numCases,1);

OriginalBestProbability = zeros(numCases,1);


StrategyChanged = strings(numCases,1);


%% =========================================================
% 7. 开始计算六种情况
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('问题4：重新完成问题2\n');
fprintf('Monte Carlo次数：%d\n',M);
fprintf('============================================================\n');


row = 0;


for case_id = 1:numCases


    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('正在计算情况 %d / %d\n', ...
        case_id,numCases);
    fprintf('------------------------------------------------------------\n');


    %% =====================================================
    % 读取该情况原始参数
    %% =====================================================

    p1_hat = Data(case_id,1);

    a1 = Data(case_id,2);

    d1 = Data(case_id,3);


    p2_hat = Data(case_id,4);

    a2 = Data(case_id,5);

    d2 = Data(case_id,6);


    pf_hat = Data(case_id,7);


    Ca = Data(case_id,8);

    Cf = Data(case_id,9);

    S  = Data(case_id,10);

    L  = Data(case_id,11);

    Cd = Data(case_id,12);


    %% =====================================================
    % 根据表中的抽样次品率，
    % 得到代表性抽样数据 n,c
    %
    % 再构造Beta后验
    %% =====================================================

    [n1,c1,A1,B1] = ...
        get_posterior_info(p1_hat);


    [n2,c2,A2,B2] = ...
        get_posterior_info(p2_hat);


    [nf,cf,Af,Bf] = ...
        get_posterior_info(pf_hat);


    fprintf( ...
        '零件1：表中p=%.2f，采用 n=%d, c=%d，Beta(%d,%d)\n', ...
        p1_hat,n1,c1,A1,B1);


    fprintf( ...
        '零件2：表中p=%.2f，采用 n=%d, c=%d，Beta(%d,%d)\n', ...
        p2_hat,n2,c2,A2,B2);


    fprintf( ...
        '成品：  表中p=%.2f，采用 n=%d, c=%d，Beta(%d,%d)\n', ...
        pf_hat,nf,cf,Af,Bf);


    %% =====================================================
    % 8. Monte Carlo随机产生真实次品率
    %
    % 不直接使用固定的0.1、0.2等
    %
    % 每一轮模拟都产生：
    %
    % p1(k)
    % p2(k)
    % pf(k)
    %% =====================================================

    p1_mc = beta_random( ...
        A1,B1,M);


    p2_mc = beta_random( ...
        A2,B2,M);


    pf_mc = beta_random( ...
        Af,Bf,M);


    %% =====================================================
    % 9. 保存16种策略在10000次模拟下的利润
    %% =====================================================

    ProfitMatrix = ...
        zeros(M,16);


    %% =====================================================
    % 10. 计算16种策略
    %% =====================================================

    for strategy_id = 1:16


        x1 = Strategies(strategy_id,1);

        x2 = Strategies(strategy_id,2);

        x3 = Strategies(strategy_id,3);

        x4 = Strategies(strategy_id,4);


        ProfitMatrix(:,strategy_id) = ...
            problem2_profit_mc( ...
            p1_mc, ...
            p2_mc, ...
            pf_mc, ...
            a1,d1, ...
            a2,d2, ...
            Ca,Cf,S,L,Cd, ...
            x1,x2,x3,x4);

    end


    %% =====================================================
    % 11. 每次模拟中找利润最大的策略
    %% =====================================================

    BestProfitEachSimulation = ...
        max(ProfitMatrix,[],2);


    %% =====================================================
    % 12. 逐策略计算统计指标
    %% =====================================================

    MeanProfit = zeros(16,1);

    StdProfit = zeros(16,1);

    Q05Profit = zeros(16,1);

    BestProbability = zeros(16,1);


    for strategy_id = 1:16


        profits = ...
            ProfitMatrix(:,strategy_id);


        %% 平均利润

        MeanProfit(strategy_id) = ...
            mean(profits);


        %% 利润标准差

        StdProfit(strategy_id) = ...
            std(profits);


        %% 5%利润分位数

        Q05Profit(strategy_id) = ...
            percentile5(profits);


        %% 成为本轮最优方案的概率

        isBest = ...
            abs( ...
            profits ...
            - BestProfitEachSimulation ...
            ) <= 1e-10;


        BestProbability(strategy_id) = ...
            mean(isBest);


        %% -----------------------------------------
        % 保存全部96行结果
        %% -----------------------------------------

        row = row + 1;


        CaseID_all(row) = ...
            case_id;


        Strategy_all(row) = ...
            StrategyCode(strategy_id);


        X1_all(row) = ...
            Strategies(strategy_id,1);


        X2_all(row) = ...
            Strategies(strategy_id,2);


        X3_all(row) = ...
            Strategies(strategy_id,3);


        X4_all(row) = ...
            Strategies(strategy_id,4);


        MeanProfit_all(row) = ...
            MeanProfit(strategy_id);


        StdProfit_all(row) = ...
            StdProfit(strategy_id);


        Q05Profit_all(row) = ...
            Q05Profit(strategy_id);


        BestProbability_all(row) = ...
            BestProbability(strategy_id);

    end


    %% =====================================================
    % 13. 按平均利润寻找主推荐方案
    %
    % 与问题2、3保持相同的利润最大化目标
    %% =====================================================

    [bestMeanProfit,bestMeanID] = ...
        max(MeanProfit);


    MeanBestStrategy(case_id) = ...
        StrategyCode(bestMeanID);


    MeanBestProfit(case_id) = ...
        bestMeanProfit;


    MeanBestStd(case_id) = ...
        StdProfit(bestMeanID);


    MeanBestQ05(case_id) = ...
        Q05Profit(bestMeanID);


    MeanBestProbability(case_id) = ...
        BestProbability(bestMeanID);


    %% =====================================================
    % 14. 另外找5%分位利润最大的稳健策略
    %
    % 它不是主目标，
    % 只是用来观察是否存在风险偏好差异
    %% =====================================================

    [bestQ05,bestRobustID] = ...
        max(Q05Profit);


    RobustBestStrategy(case_id) = ...
        StrategyCode(bestRobustID);


    RobustQ05(case_id) = ...
        bestQ05;


    %% =====================================================
    % 15. 找原问题2策略在随机环境中成为最优的概率
    %% =====================================================

    originalID = ...
        find( ...
        StrategyCode == ...
        OriginalStrategy(case_id), ...
        1);


    OriginalBestProbability(case_id) = ...
        BestProbability(originalID);


    %% =====================================================
    % 16. 判断策略是否发生变化
    %% =====================================================

    if MeanBestStrategy(case_id) == ...
            OriginalStrategy(case_id)

        StrategyChanged(case_id) = ...
            "未改变";

    else

        StrategyChanged(case_id) = ...
            "发生改变";

    end


    %% =====================================================
    % 17. 输出当前情况结果
    %% =====================================================

    fprintf('\n原问题2最优策略：%s\n', ...
        OriginalStrategy(case_id));


    fprintf('考虑抽样误差后的平均利润最优策略：%s\n', ...
        MeanBestStrategy(case_id));


    fprintf('平均利润：%.4f 元\n', ...
        MeanBestProfit(case_id));


    fprintf('利润标准差：%.4f 元\n', ...
        MeanBestStd(case_id));


    fprintf('5%%分位利润：%.4f 元\n', ...
        MeanBestQ05(case_id));


    fprintf('该策略成为实际最优方案的概率：%.2f%%\n', ...
        100*MeanBestProbability(case_id));


    fprintf('原问题2策略成为实际最优的概率：%.2f%%\n', ...
        100*OriginalBestProbability(case_id));


    fprintf('稳健5%%分位最优策略：%s\n', ...
        RobustBestStrategy(case_id));


    fprintf('策略变化：%s\n', ...
        StrategyChanged(case_id));

end


%% =========================================================
% 18. 构造全部策略统计表
%% =========================================================

AllStrategyTable = table( ...
    CaseID_all, ...
    Strategy_all, ...
    X1_all, ...
    X2_all, ...
    X3_all, ...
    X4_all, ...
    MeanProfit_all, ...
    StdProfit_all, ...
    Q05Profit_all, ...
    BestProbability_all, ...
    'VariableNames', { ...
    'CaseID', ...
    'Strategy', ...
    'CheckPart1', ...
    'CheckPart2', ...
    'CheckProduct', ...
    'Disassemble', ...
    'MeanProfit', ...
    'StdProfit', ...
    'Q05Profit', ...
    'BestProbability'});


%% =========================================================
% 19. 六种情况汇总表
%% =========================================================

SummaryTable = table( ...
    CaseID_summary, ...
    Original_summary, ...
    MeanBestStrategy, ...
    MeanBestProfit, ...
    MeanBestStd, ...
    MeanBestQ05, ...
    MeanBestProbability, ...
    OriginalBestProbability, ...
    RobustBestStrategy, ...
    RobustQ05, ...
    StrategyChanged, ...
    'VariableNames', { ...
    'CaseID', ...
    'OriginalStrategy', ...
    'PosteriorMeanBestStrategy', ...
    'MeanProfit', ...
    'StdProfit', ...
    'Q05Profit', ...
    'BestProbability', ...
    'OriginalStrategyBestProbability', ...
    'RobustQ05Strategy', ...
    'RobustQ05Profit', ...
    'StrategyChanged'});


fprintf('\n');
fprintf('============================================================\n');
fprintf('问题4——问题2最终汇总\n');
fprintf('============================================================\n');

disp(SummaryTable);


%% =========================================================
% 20. 输出Beta后验参数说明表
%% =========================================================

NominalRate = [
    0.05
    0.10
    0.20
    ];


SampleN = [
    126
    126
    58
    ];


DefectC = [
    6
    13
    12
    ];


BetaA = ...
    DefectC + 1;


BetaB = ...
    SampleN - DefectC + 1;


PosteriorMean = ...
    BetaA ./ (BetaA+BetaB);


PosteriorTable = table( ...
    NominalRate, ...
    SampleN, ...
    DefectC, ...
    BetaA, ...
    BetaB, ...
    PosteriorMean);


%% =========================================================
% 21. 保存Excel
%% =========================================================

filename = ...
    'problem4_problem2_result.xlsx';


if exist(filename,'file')

    delete(filename);

end


%% Sheet 1

writetable( ...
    SummaryTable, ...
    filename, ...
    'Sheet', ...
    '六种情况汇总');


%% Sheet 2

writetable( ...
    AllStrategyTable, ...
    filename, ...
    'Sheet', ...
    '全部策略统计');


%% Sheet 3

writetable( ...
    PosteriorTable, ...
    filename, ...
    'Sheet', ...
    'Beta后验参数');


%% =========================================================
% 22. 建模说明
%% =========================================================

Notes = {

    '问题4-问题2建模说明';

    '1. 表中5%、10%、20%的次品率被视为抽样估计值，而非精确真实值。';

    '2. 由于原题未给出问题2各次品率对应的原始抽样数量和次品数量，采用问题1 SPRT结果构造代表性抽样规模。';

    '3. 对5%次品率取n=126,c=6。';

    '4. 对10%次品率取n=126,c=13。';

    '5. 对20%次品率取n=58,c=12。';

    '6. 采用Beta(1,1)均匀先验。';

    '7. 抽样后真实次品率后验为Beta(c+1,n-c+1)。';

    '8. 每种情况独立进行10000次Monte Carlo模拟。';

    '9. 每次模拟随机生成零件1、零件2和成品三个真实次品率。';

    '10. 每组随机次品率均重新计算16种生产策略。';

    '11. 主决策目标仍为后验平均期望利润最大化。';

    '12. 同时统计利润标准差、5%利润分位数和成为最优方案的概率，用于评估策略稳定性。';

    '13. 拆解规则沿用问题2：装配前检测过的零件拆解后不重复检测；未检测的零件拆解后必须检测。'

    };


writecell( ...
    Notes, ...
    filename, ...
    'Sheet', ...
    '模型说明');


%% =========================================================
% 23. 完成
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('问题4中的问题2计算完成！\n');
fprintf('结果文件：%s\n',filename);
fprintf('============================================================\n');


%% =========================================================
%%                    以下是局部函数
%% =========================================================


function [n,c,a,b] = ...
    get_posterior_info(p_hat)

%% =========================================================
% 根据表中抽样次品率，
% 返回代表性SPRT抽样结果
%
% 5%  -> n=126,c=6
% 10% -> n=126,c=13
% 20% -> n=58,c=12
%
% Beta(1,1)先验：
%
% posterior = Beta(c+1,n-c+1)
%% =========================================================


if abs(p_hat-0.05) < 1e-8

    n = 126;

    c = 6;


elseif abs(p_hat-0.10) < 1e-8

    n = 126;

    c = 13;


elseif abs(p_hat-0.20) < 1e-8

    n = 58;

    c = 12;


else

    error( ...
        '当前程序只定义了5%%、10%%、20%%三种抽样次品率。');

end


a = c + 1;

b = n - c + 1;

end



function x = beta_random(a,b,M)

%% =========================================================
% 从Beta(a,b)随机生成M个数
%
% 使用Gamma变量构造，
% 避免依赖betarnd
%
% 若：
%
% U ~ Gamma(a,1)
% V ~ Gamma(b,1)
%
% 则：
%
% U/(U+V) ~ Beta(a,b)
%% =========================================================

U = randg(a,[M,1]);

V = randg(b,[M,1]);


x = ...
    U ./ (U+V);

end



function q05 = percentile5(x)

%% =========================================================
% 计算经验5%分位数
%
% 避免依赖prctile
%% =========================================================

x = sort(x);

N = length(x);


index = ...
    max(1,ceil(0.05*N));


q05 = ...
    x(index);

end



function profit = problem2_profit_mc( ...
    p1, ...
    p2, ...
    pf, ...
    a1,d1, ...
    a2,d2, ...
    Ca,Cf,S,L,Cd, ...
    x1,x2,x3,x4)

%% =========================================================
% 问题2生产模型
%
% 输入p1、p2、pf均为Monte Carlo随机向量
%
% 输出：
%
% 每一轮Monte Carlo下的期望利润
%% =========================================================


M = length(p1);


%% =========================================================
% 1. 零件1
%% =========================================================

if x1 == 1

    %% 检测：
    % 直到获得一个合格件

    g1 = ones(M,1);


    C1 = ...
        (a1+d1) ...
        ./ (1-p1);

else

    %% 不检测

    g1 = ...
        1-p1;


    C1 = ...
        a1*ones(M,1);

end


%% =========================================================
% 2. 零件2
%% =========================================================

if x2 == 1

    g2 = ...
        ones(M,1);


    C2 = ...
        (a2+d2) ...
        ./ (1-p2);

else

    g2 = ...
        1-p2;


    C2 = ...
        a2*ones(M,1);

end


%% =========================================================
% 3. 第一次成品合格率
%% =========================================================

G = ...
    g1 ...
    .* g2 ...
    .* (1-pf);


q = ...
    1-G;


%% =========================================================
% 4. 一次装配成本
%% =========================================================

AssemblyCost = ...
    Ca + x3*Cf;


%% =========================================================
% 5. 不拆解
%% =========================================================

if x4 == 0


    C0 = ...
        C1 ...
        + C2 ...
        + AssemblyCost;


    ExpectedCost = ...
        ( ...
        C0 ...
        + q .* ...
        ((1-x3)*L) ...
        ) ...
        ./ G;


%% =========================================================
% 6. 拆解
%% =========================================================

else


    %% -----------------------------------------------------
    % 初次生产成本
    %% -----------------------------------------------------

    InitialCost = ...
        C1 ...
        + C2 ...
        + AssemblyCost;


    %% -----------------------------------------------------
    % 拆解后回收零件处理成本
    %
    % 原来检测过：
    % 不重复检测
    %
    % 原来没有检测：
    % 必须检测
    %% -----------------------------------------------------

    RecoveryCost = ...
        zeros(M,1);


    %% 零件1

    if x1 == 0


        ProbBad1GivenFail = ...
            p1 ./ q;


        ProbBad1GivenFail = ...
            min( ...
            max( ...
            ProbBad1GivenFail, ...
            0), ...
            1);


        CostNewGoodPart1 = ...
            (a1+d1) ...
            ./ (1-p1);


        RecoveryPart1 = ...
            d1 ...
            + ProbBad1GivenFail ...
            .* CostNewGoodPart1;


        RecoveryCost = ...
            RecoveryCost ...
            + RecoveryPart1;

    end


    %% 零件2

    if x2 == 0


        ProbBad2GivenFail = ...
            p2 ./ q;


        ProbBad2GivenFail = ...
            min( ...
            max( ...
            ProbBad2GivenFail, ...
            0), ...
            1);


        CostNewGoodPart2 = ...
            (a2+d2) ...
            ./ (1-p2);


        RecoveryPart2 = ...
            d2 ...
            + ProbBad2GivenFail ...
            .* CostNewGoodPart2;


        RecoveryCost = ...
            RecoveryCost ...
            + RecoveryPart2;

    end


    %% -----------------------------------------------------
    % 首次拆解处理完成后，
    % 两个零件都成为已知合格件
    %
    % 以后如果失败，
    % 只能来自装配自身次品率pf
    %% -----------------------------------------------------

    FutureKnownGoodCost = ...
        ( ...
        AssemblyCost ...
        + pf .* ...
        ( ...
        Cd ...
        + (1-x3)*L ...
        ) ...
        ) ...
        ./ (1-pf);


    %% -----------------------------------------------------
    % 总期望成本
    %% -----------------------------------------------------

    ExpectedCost = ...
        InitialCost ...
        + q .* ...
        ( ...
        (1-x3)*L ...
        + Cd ...
        + RecoveryCost ...
        + FutureKnownGoodCost ...
        );

end


%% =========================================================
% 7. 期望利润
%% =========================================================

profit = ...
    S - ExpectedCost;

end