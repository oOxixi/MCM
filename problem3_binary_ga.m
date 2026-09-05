function [bestX,bestProfit,history] = ...
    binary_ga( ...
    nVar, ...
    popSize, ...
    maxGen, ...
    pc, ...
    pm, ...
    eliteNum)

%% =========================================================
% 二进制遗传算法
%
% nVar
%   决策变量个数
%
% popSize
%   种群规模
%
% maxGen
%   最大迭代代数
%
% pc
%   交叉概率
%
% pm
%   每个基因的变异概率
%
% eliteNum
%   每代保留的精英数量
%% =========================================================


%% =========================================================
% 1. 随机产生初始种群
%% =========================================================

pop = randi( ...
    [0 1], ...
    popSize, ...
    nVar);


fitness = zeros(popSize,1);


for i = 1:popSize

    fitness(i) = ...
        problem3_profit(pop(i,:));

end


history = zeros(maxGen,1);


%% =========================================================
% 2. 开始进化
%% =========================================================

for gen = 1:maxGen


    %% 按利润降序排列

    [fitness,order] = ...
        sort(fitness,'descend');

    pop = ...
        pop(order,:);


    %% 建立下一代

    newPop = ...
        zeros(popSize,nVar);


    %% 精英保留

    newPop(1:eliteNum,:) = ...
        pop(1:eliteNum,:);


    currentNum = ...
        eliteNum;


    %% =====================================================
    % 产生新个体
    %% =====================================================

    while currentNum < popSize


        %% -----------------------------------------
        % 锦标赛选择父代1
        %% -----------------------------------------

        parent1 = tournament_select( ...
            pop, ...
            fitness);


        %% 父代2

        parent2 = tournament_select( ...
            pop, ...
            fitness);


        child1 = parent1;
        child2 = parent2;


        %% -----------------------------------------
        % 单点交叉
        %% -----------------------------------------

        if rand < pc

            point = ...
                randi([1 nVar-1]);


            child1 = [ ...
                parent1(1:point), ...
                parent2(point+1:end) ...
                ];


            child2 = [ ...
                parent2(1:point), ...
                parent1(point+1:end) ...
                ];

        end


        %% -----------------------------------------
        % 位变异
        %% -----------------------------------------

        mutationMask1 = ...
            rand(1,nVar) < pm;


        child1(mutationMask1) = ...
            1-child1(mutationMask1);


        mutationMask2 = ...
            rand(1,nVar) < pm;


        child2(mutationMask2) = ...
            1-child2(mutationMask2);


        %% -----------------------------------------
        % 加入下一代
        %% -----------------------------------------

        currentNum = currentNum + 1;

        newPop(currentNum,:) = ...
            child1;


        if currentNum < popSize

            currentNum = currentNum + 1;

            newPop(currentNum,:) = ...
                child2;

        end

    end


    %% =====================================================
    % 更新种群
    %% =====================================================

    pop = newPop;


    for i = 1:popSize

        fitness(i) = ...
            problem3_profit(pop(i,:));

    end


    history(gen) = ...
        max(fitness);

end


%% =========================================================
% 3. 输出最优方案
%% =========================================================

[bestProfit,bestIndex] = ...
    max(fitness);


bestX = ...
    pop(bestIndex,:);

end



%% =========================================================
% 锦标赛选择
%% =========================================================

function parent = ...
    tournament_select(pop,fitness)

popSize = size(pop,1);

candidate = ...
    randi(popSize,1,3);


[~,bestLocal] = ...
    max(fitness(candidate));


winner = ...
    candidate(bestLocal);


parent = ...
    pop(winner,:);

end