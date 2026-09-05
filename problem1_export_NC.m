clc;
clear;
close all;

%% =========================================================
% 问题1 —— 为问题4生成完整的(N,C)联合样本
%
% N = SPRT停止时总抽样数
% C = SPRT停止时累计次品数
%
% 分别为：
% p = 0.05
% p = 0.10
% p = 0.20
%
% 生成10000组(N,C)
%% =========================================================

rng(2024);

M = 10000;
max_n = 10000;

p0 = 0.10;


%% =========================================================
% 1. p = 0.20
%
% 使用拒收侧SPRT：
%
% H0 : p = 0.10
% H1 : p = 0.20
%
% alpha = 0.05
% beta  = 0.10
%% =========================================================

fprintf('\n正在生成 p=0.20 的(N,C)样本...\n');

pool20 = simulate_NC_pool( ...
    0.10, ...
    0.20, ...
    0.05, ...
    0.10, ...
    0.20, ...
    M, ...
    max_n);


%% =========================================================
% 2. p = 0.05
%
% 使用接收侧SPRT：
%
% p0 = 0.10
% p1 = 0.05
%
% alpha = 0.10
% beta  = 0.05
%% =========================================================

fprintf('正在生成 p=0.05 的(N,C)样本...\n');

pool05 = simulate_NC_pool( ...
    0.10, ...
    0.05, ...
    0.10, ...
    0.05, ...
    0.05, ...
    M, ...
    max_n);


%% =========================================================
% 3. p = 0.10
%
% 10%正好处于标称边界。
%
% 这里采用拒收侧SPRT在p=0.10下产生的完整停止数据。
%
% 这是一个建模约定。
% 好处是它给出的样本量相对较少，
% 因而第四题对10%次品率保留更大的不确定性，
% 属于较保守处理。
%% =========================================================

fprintf('正在生成 p=0.10 的(N,C)样本...\n');

pool10 = simulate_NC_pool( ...
    0.10, ...
    0.20, ...
    0.05, ...
    0.10, ...
    0.10, ...
    M, ...
    max_n);


%% =========================================================
% 4. 查看三个样本池的统计信息
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('完整(N,C)样本统计\n');
fprintf('============================================================\n');


show_pool_info('p=0.05',pool05);
show_pool_info('p=0.10',pool10);
show_pool_info('p=0.20',pool20);


%% =========================================================
% 5. 保存MAT文件
%
% 第四题直接读取这个文件
%% =========================================================

save( ...
    'problem1_sprt_NC_samples.mat', ...
    'pool05', ...
    'pool10', ...
    'pool20');


%% =========================================================
% 6. 同时保存Excel，方便查看
%% =========================================================

filename = ...
    'problem1_sprt_NC_samples.xlsx';


if exist(filename,'file')

    delete(filename);

end


T05 = table( ...
    pool05.N, ...
    pool05.C, ...
    pool05.LLR, ...
    pool05.Boundary, ...
    'VariableNames', ...
    {'N','C','LLR','Boundary'});


T10 = table( ...
    pool10.N, ...
    pool10.C, ...
    pool10.LLR, ...
    pool10.Boundary, ...
    'VariableNames', ...
    {'N','C','LLR','Boundary'});


T20 = table( ...
    pool20.N, ...
    pool20.C, ...
    pool20.LLR, ...
    pool20.Boundary, ...
    'VariableNames', ...
    {'N','C','LLR','Boundary'});


writetable(T05,filename,'Sheet','p005');
writetable(T10,filename,'Sheet','p010');
writetable(T20,filename,'Sheet','p020');


fprintf('\n');
fprintf('已保存：problem1_sprt_NC_samples.mat\n');
fprintf('已保存：problem1_sprt_NC_samples.xlsx\n');


%% =========================================================
%%                    局部函数
%% =========================================================


function pool = simulate_NC_pool( ...
    p0,p1,alpha,beta,true_p,M,max_n)

%% Wald边界

lower = ...
    log(beta/(1-alpha));

upper = ...
    log((1-beta)/alpha);


%% 单个样本产生的LLR增量

badStep = ...
    log(p1/p0);

goodStep = ...
    log((1-p1)/(1-p0));


%% 初始化

N_all = zeros(M,1);

C_all = zeros(M,1);

LLR_all = zeros(M,1);

Boundary_all = strings(M,1);


%% Monte Carlo

for k = 1:M

    llr = 0;

    c = 0;


    for n = 1:max_n

        %% x=1表示次品

        x = rand < true_p;


        if x == 1

            c = c + 1;

            llr = ...
                llr + badStep;

        else

            llr = ...
                llr + goodStep;

        end


        %% 达到上界

        if llr >= upper

            boundary = "Upper";

            break;

        end


        %% 达到下界

        if llr <= lower

            boundary = "Lower";

            break;

        end

    end


    %% 如果达到最大样本量

    if n == max_n

        if llr >= 0

            boundary = "TruncatedUpper";

        else

            boundary = "TruncatedLower";

        end

    end


    N_all(k) = n;

    C_all(k) = c;

    LLR_all(k) = llr;

    Boundary_all(k) = boundary;

end


pool.N = N_all;

pool.C = C_all;

pool.LLR = LLR_all;

pool.Boundary = Boundary_all;

pool.true_p = true_p;

end



function show_pool_info(name,pool)

N = pool.N;

fprintf('\n%s\n',name);

fprintf('平均N = %.3f\n',mean(N));

fprintf('中位数N = %.0f\n',percentile_local(N,0.50));

fprintf('90%%分位N = %.0f\n',percentile_local(N,0.90));

fprintf('95%%分位N = %.0f\n',percentile_local(N,0.95));

fprintf('平均C = %.3f\n',mean(pool.C));

end



function q = percentile_local(x,p)

x = sort(x);

N = length(x);

idx = ceil(p*N);

idx = max(1,min(N,idx));

q = x(idx);

end