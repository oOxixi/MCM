function [bestX,bestProfit,history] = ...
    binary_sa( ...
    nVar, ...
    maxIter, ...
    T0, ...
    alpha)

%% =========================================================
% 二进制模拟退火算法
%
% T0
%   初始温度
%
% alpha
%   降温系数
%
% 目标：
% 最大化problem3_profit
%% =========================================================


%% =========================================================
% 1. 随机初始解
%% =========================================================

x = ...
    randi([0 1],1,nVar);


currentProfit = ...
    problem3_profit(x);


bestX = x;

bestProfit = ...
    currentProfit;


T = T0;


history = zeros(maxIter,1);


%% =========================================================
% 2. 模拟退火
%% =========================================================

for iter = 1:maxIter


    %% -----------------------------------------
    % 产生邻域解
    %% -----------------------------------------

    xNew = x;


    %% 85%概率翻转1位
    %  15%概率翻转2位

    if rand < 0.85

        numFlip = 1;

    else

        numFlip = 2;

    end


    index = ...
        randperm(nVar,numFlip);


    xNew(index) = ...
        1-xNew(index);


    %% -----------------------------------------
    % 计算新方案利润
    %% -----------------------------------------

    newProfit = ...
        problem3_profit(xNew);


    delta = ...
        newProfit-currentProfit;


    %% -----------------------------------------
    % Metropolis准则
    %
    % 如果更优：
    % 必然接受
    %
    % 如果更差：
    % 以一定概率接受
    %% -----------------------------------------

    if delta >= 0

        accept = true;

    else

        probability = ...
            exp(delta/max(T,1e-12));


        accept = ...
            rand < probability;

    end


    %% 更新当前解

    if accept

        x = xNew;

        currentProfit = ...
            newProfit;

    end


    %% 更新历史最优

    if currentProfit > bestProfit

        bestProfit = ...
            currentProfit;

        bestX = ...
            x;

    end


    history(iter) = ...
        bestProfit;


    %% -----------------------------------------
    % 降温
    %% -----------------------------------------

    T = ...
        max(T*alpha,1e-8);

end

end