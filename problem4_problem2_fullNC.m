clc;
clear;
close all;

%% =========================================================
% 2024 B题 问题4
%
% 基于完整SPRT (N,C)联合分布
% 重新完成问题2
%
% 不使用：
% 平均ASN
% 固定样本量
% 90%分位固定样本量
%
% 而是：
%
% SPRT完整(N,C)样本
%       ↓
% 随机抽一组(N,C)
%       ↓
% Beta(C+1,N-C+1)
%       ↓
% 随机产生真实次品率
%       ↓
% 重新计算16种生产方案
%% =========================================================


rng(2025);

M = 10000;


%% =========================================================
% 1. 读取第一题生成的完整(N,C)样本
%% =========================================================

load( ...
    'problem1_sprt_NC_samples.mat', ...
    'pool05', ...
    'pool10', ...
    'pool20');


fprintf('\n完整(N,C)样本读取成功。\n');


%% =========================================================
% 2. 问题2数据
%% =========================================================

Data = [

    0.10  4  2   0.10 18 3   0.10 6 3 56  6  5;
    0.20  4  2   0.20 18 3   0.20 6 3 56  6  5;
    0.10  4  2   0.10 18 3   0.10 6 3 56 30  5;
    0.20  4  1   0.20 18 1   0.20 6 2 56 30  5;
    0.10  4  8   0.20 18 1   0.10 6 2 56 10  5;
    0.05  4  2   0.05 18 3   0.05 6 3 56 10 40

];


numCases = size(Data,1);


%% =========================================================
% 3. 原问题2最优方案
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
% 4. 枚举16种策略
%% =========================================================

Strategies = zeros(16,4);

StrategyCode = strings(16,1);

id = 0;


for x1 = 0:1

    for x2 = 0:1

        for x3 = 0:1

            for x4 = 0:1

                id = id + 1;

                Strategies(id,:) = ...
                    [x1 x2 x3 x4];

                StrategyCode(id) = ...
                    sprintf('%d%d%d%d', ...
                    x1,x2,x3,x4);

            end

        end

    end

end


%% =========================================================
% 5. 最终汇总结果
%% =========================================================

BestStrategy = strings(numCases,1);

MeanProfitBest = zeros(numCases,1);

StdProfitBest = zeros(numCases,1);

Q05ProfitBest = zeros(numCases,1);

BestProbability = zeros(numCases,1);

OriginalBestProbability = zeros(numCases,1);

StrategyChanged = strings(numCases,1);


%% 全部策略结果

CaseID_All = [];

Strategy_All = strings(0,1);

MeanProfit_All = [];

StdProfit_All = [];

Q05Profit_All = [];

BestProb_All = [];


%% =========================================================
% 6. 六种情况
%% =========================================================

for case_id = 1:numCases


    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('正在计算情况 %d\n',case_id);
    fprintf('============================================================\n');


    %% 读取参数

    p1_nom = Data(case_id,1);

    a1 = Data(case_id,2);

    d1 = Data(case_id,3);


    p2_nom = Data(case_id,4);

    a2 = Data(case_id,5);

    d2 = Data(case_id,6);


    pf_nom = Data(case_id,7);


    Ca = Data(case_id,8);

    Cf = Data(case_id,9);

    S = Data(case_id,10);

    L = Data(case_id,11);

    Cd = Data(case_id,12);


    %% =====================================================
    % 7. 为三个次品率分别生成M个可能真实值
    %
    % 注意：
    %
    % 即使两个名义次品率都是10%，
    % 零件1和零件2也是独立进行抽样，
    % 所以分别随机抽取(N,C)
    %% =====================================================

    [p1_mc,N1_mc,C1_mc] = ...
        generate_p_from_fullNC( ...
        p1_nom,M,pool05,pool10,pool20);


    [p2_mc,N2_mc,C2_mc] = ...
        generate_p_from_fullNC( ...
        p2_nom,M,pool05,pool10,pool20);


    [pf_mc,Nf_mc,Cf_mc] = ...
        generate_p_from_fullNC( ...
        pf_nom,M,pool05,pool10,pool20);


    fprintf( ...
        '零件1：名义p=%.2f，平均抽到N=%.2f\n', ...
        p1_nom,mean(N1_mc));


    fprintf( ...
        '零件2：名义p=%.2f，平均抽到N=%.2f\n', ...
        p2_nom,mean(N2_mc));


    fprintf( ...
        '成品：名义p=%.2f，平均抽到N=%.2f\n', ...
        pf_nom,mean(Nf_mc));


    %% =====================================================
    % 8. M × 16 利润矩阵
    %% =====================================================

    ProfitMatrix = zeros(M,16);


    for s = 1:16

        x1 = Strategies(s,1);

        x2 = Strategies(s,2);

        x3 = Strategies(s,3);

        x4 = Strategies(s,4);


        ProfitMatrix(:,s) = ...
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
    % 9. 每一次随机环境下的最大利润
    %% =====================================================

    BestEach = ...
        max(ProfitMatrix,[],2);


    %% =====================================================
    % 10. 计算16个方案统计指标
    %% =====================================================

    MeanProfit = zeros(16,1);

    StdProfit = zeros(16,1);

    Q05Profit = zeros(16,1);

    ProbBest = zeros(16,1);


    for s = 1:16

        x = ProfitMatrix(:,s);


        MeanProfit(s) = ...
            mean(x);


        StdProfit(s) = ...
            std(x);


        Q05Profit(s) = ...
            percentile_local(x,0.05);


        ProbBest(s) = ...
            mean( ...
            abs(x-BestEach) < 1e-10);


        %% 保存

        CaseID_All(end+1,1) = case_id;

        Strategy_All(end+1,1) = StrategyCode(s);

        MeanProfit_All(end+1,1) = MeanProfit(s);

        StdProfit_All(end+1,1) = StdProfit(s);

        Q05Profit_All(end+1,1) = Q05Profit(s);

        BestProb_All(end+1,1) = ProbBest(s);

    end


    %% =====================================================
    % 11. 后验平均利润最大的方案
    %% =====================================================

    [~,bestID] = ...
        max(MeanProfit);


    BestStrategy(case_id) = ...
        StrategyCode(bestID);


    MeanProfitBest(case_id) = ...
        MeanProfit(bestID);


    StdProfitBest(case_id) = ...
        StdProfit(bestID);


    Q05ProfitBest(case_id) = ...
        Q05Profit(bestID);


    BestProbability(case_id) = ...
        ProbBest(bestID);


    %% =====================================================
    % 原问题2方案最优概率
    %% =====================================================

    oldID = ...
        find( ...
        StrategyCode == ...
        OriginalStrategy(case_id), ...
        1);


    OriginalBestProbability(case_id) = ...
        ProbBest(oldID);


    %% 是否改变

    if BestStrategy(case_id) == ...
            OriginalStrategy(case_id)

        StrategyChanged(case_id) = ...
            "未改变";

    else

        StrategyChanged(case_id) = ...
            "发生改变";

    end


    %% =====================================================
    % 输出
    %% =====================================================

    fprintf('\n原问题2策略：%s\n', ...
        OriginalStrategy(case_id));


    fprintf('问题4推荐策略：%s\n', ...
        BestStrategy(case_id));


    fprintf('平均利润：%.4f\n', ...
        MeanProfitBest(case_id));


    fprintf('利润标准差：%.4f\n', ...
        StdProfitBest(case_id));


    fprintf('5%%分位利润：%.4f\n', ...
        Q05ProfitBest(case_id));


    fprintf('成为实际最优策略概率：%.2f%%\n', ...
        BestProbability(case_id)*100);


    fprintf('原方案成为实际最优概率：%.2f%%\n', ...
        OriginalBestProbability(case_id)*100);


    fprintf('策略是否改变：%s\n', ...
        StrategyChanged(case_id));

end


%% =========================================================
% 12. 六种情况汇总
%% =========================================================

CaseID = (1:numCases)';


SummaryTable = table( ...
    CaseID, ...
    OriginalStrategy, ...
    BestStrategy, ...
    MeanProfitBest, ...
    StdProfitBest, ...
    Q05ProfitBest, ...
    BestProbability, ...
    OriginalBestProbability, ...
    StrategyChanged, ...
    'VariableNames', { ...
    'CaseID', ...
    'OriginalStrategy', ...
    'FullNCBestStrategy', ...
    'MeanProfit', ...
    'StdProfit', ...
    'Q05Profit', ...
    'BestProbability', ...
    'OriginalBestProbability', ...
    'StrategyChanged'});


fprintf('\n');
fprintf('============================================================\n');
fprintf('问题4——问题2最终结果\n');
fprintf('============================================================\n');

disp(SummaryTable);


%% =========================================================
% 13. 全部策略表
%% =========================================================

AllStrategyTable = table( ...
    CaseID_All, ...
    Strategy_All, ...
    MeanProfit_All, ...
    StdProfit_All, ...
    Q05Profit_All, ...
    BestProb_All, ...
    'VariableNames', { ...
    'CaseID', ...
    'Strategy', ...
    'MeanProfit', ...
    'StdProfit', ...
    'Q05Profit', ...
    'BestProbability'});


%% =========================================================
% 14. 保存Excel
%% =========================================================

filename = ...
    'problem4_problem2_fullNC_result.xlsx';


if exist(filename,'file')

    delete(filename);

end


writetable( ...
    SummaryTable, ...
    filename, ...
    'Sheet', ...
    '六种情况汇总');


writetable( ...
    AllStrategyTable, ...
    filename, ...
    'Sheet', ...
    '全部策略');


fprintf('\n结果已保存：%s\n',filename);


%% =========================================================
%%                     局部函数
%% =========================================================


function [p,N,C] = ...
    generate_p_from_fullNC( ...
    nominal,M,pool05,pool10,pool20)

%% =========================================================
% 第一步：
% 根据名义次品率选择对应的完整(N,C)样本池
%% =========================================================

if abs(nominal-0.05) < 1e-10

    pool = pool05;

elseif abs(nominal-0.10) < 1e-10

    pool = pool10;

elseif abs(nominal-0.20) < 1e-10

    pool = pool20;

else

    error('只支持0.05、0.10、0.20');

end


%% =========================================================
% 第二步：
% 从10000组真实SPRT停止记录中随机抽M组
%% =========================================================

K = length(pool.N);

idx = randi(K,M,1);


N = pool.N(idx);

C = pool.C(idx);


%% =========================================================
% 第三步：
%
% Beta(1,1)先验
%
% 后验：
%
% p | N,C ~ Beta(C+1,N-C+1)
%% =========================================================

A = C + 1;

B = N - C + 1;


%% =========================================================
% 第四步：
% 从每一个不同的Beta后验中各抽一个p
%
% Gamma方法生成Beta随机数
%% =========================================================

U = randg(A);

V = randg(B);


p = U ./ (U+V);

end



function q = percentile_local(x,p)

x = sort(x);

N = length(x);

idx = ceil(p*N);

idx = max(1,min(N,idx));

q = x(idx);

end



function profit = problem2_profit_mc( ...
    p1,p2,pf, ...
    a1,d1,a2,d2, ...
    Ca,Cf,S,L,Cd, ...
    x1,x2,x3,x4)

%% =========================================================
% 问题2原生产决策模型
%% =========================================================

M = length(p1);


%% 零件1

if x1 == 1

    g1 = ones(M,1);

    C1 = ...
        (a1+d1) ./ (1-p1);

else

    g1 = 1-p1;

    C1 = a1*ones(M,1);

end


%% 零件2

if x2 == 1

    g2 = ones(M,1);

    C2 = ...
        (a2+d2) ./ (1-p2);

else

    g2 = 1-p2;

    C2 = a2*ones(M,1);

end


%% 第一次成品合格率

G = ...
    g1 .* g2 .* (1-pf);

q = ...
    1-G;


AssemblyCost = ...
    Ca + x3*Cf;


%% =========================================================
% 不拆解
%% =========================================================

if x4 == 0

    C0 = ...
        C1 + C2 + AssemblyCost;


    ExpectedCost = ...
        ( ...
        C0 ...
        + q.*((1-x3)*L) ...
        ) ./ G;


%% =========================================================
% 拆解
%% =========================================================

else

    InitialCost = ...
        C1 + C2 + AssemblyCost;


    RecoveryCost = ...
        zeros(M,1);


    %% 零件1没检测

    if x1 == 0

        ProbBad1 = ...
            p1 ./ q;


        ProbBad1 = ...
            min(max(ProbBad1,0),1);


        NewGood1 = ...
            (a1+d1) ./ (1-p1);


        RecoveryCost = ...
            RecoveryCost ...
            + d1 ...
            + ProbBad1 .* NewGood1;

    end


    %% 零件2没检测

    if x2 == 0

        ProbBad2 = ...
            p2 ./ q;


        ProbBad2 = ...
            min(max(ProbBad2,0),1);


        NewGood2 = ...
            (a2+d2) ./ (1-p2);


        RecoveryCost = ...
            RecoveryCost ...
            + d2 ...
            + ProbBad2 .* NewGood2;

    end


    %% 已经得到两个确定合格零件后的重复生产期望成本

    W = ...
        ( ...
        AssemblyCost ...
        + pf .* ...
        (Cd+(1-x3)*L) ...
        ) ...
        ./ (1-pf);


    ExpectedCost = ...
        InitialCost ...
        + q .* ...
        ( ...
        (1-x3)*L ...
        + Cd ...
        + RecoveryCost ...
        + W ...
        );

end


profit = ...
    S - ExpectedCost;

end