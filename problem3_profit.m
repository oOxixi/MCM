function [profit, cost, detail] = problem3_profit(bits)

%% =========================================================
% problem3_profit.m
%
% 输入：
% bits = 1×16 的0-1决策向量
%
% 顺序：
%
% x1~x8
% y1~y3
% z
% u1~u3
% v
%
% 输出：
%
% profit
%   期望利润
%
% cost
%   最终成功交付一件合格产品的期望成本
%
% detail
%   详细结果
%% =========================================================


%% 保证输入为0-1向量

bits = round(bits(:)');

bits(bits < 0) = 0;
bits(bits > 1) = 1;


%% =========================================================
% 1. 拆解决策变量
%% =========================================================

x = bits(1:8);

y = bits(9:11);

z = bits(12);

u = bits(13:15);

v = bits(16);


%% =========================================================
% 2. 零件参数
%% =========================================================

part_p = [ ...
    0.10 0.10 0.10 0.10 ...
    0.10 0.10 0.10 0.10];


part_price = [ ...
    2 8 12 2 8 12 8 12];


part_detect = [ ...
    1 1 2 1 1 2 1 2];


%% =========================================================
% 3. 半成品参数
%% =========================================================

semi_p = [0.10 0.10 0.10];

semi_assembly = [8 8 8];

semi_detect = [4 4 4];

semi_disassembly = [6 6 6];


%% =========================================================
% 4. 最终产品参数
%% =========================================================

final_p = 0.10;

final_assembly = 8;

final_detect = 6;

final_disassembly = 10;

replacement_loss = 40;

sale_price = 200;


%% =========================================================
% 5. 建立8个零件节点
%% =========================================================

parts = repmat( ...
    struct( ...
    'C',0, ...
    'g',0, ...
    'detectCost',0, ...
    'inspected',0, ...
    'R',0), ...
    1,8);


for i = 1:8

    %% 获得确认合格零件的期望成本

    K_part = ...
        (part_price(i) + part_detect(i)) ...
        / (1-part_p(i));


    parts(i).detectCost = ...
        part_detect(i);


    parts(i).inspected = ...
        x(i);


    %% 已知坏件后的替换成本

    parts(i).R = ...
        K_part;


    if x(i) == 1

        %% 提前检测

        parts(i).C = ...
            K_part;

        parts(i).g = ...
            1;

    else

        %% 不检测

        parts(i).C = ...
            part_price(i);

        parts(i).g = ...
            1-part_p(i);

    end

end


%% =========================================================
% 6. 三个半成品
%% =========================================================

semi1 = evaluate_node( ...
    parts(1:3), ...
    semi_p(1), ...
    semi_assembly(1), ...
    semi_detect(1), ...
    semi_disassembly(1), ...
    y(1), ...
    u(1));


semi2 = evaluate_node( ...
    parts(4:6), ...
    semi_p(2), ...
    semi_assembly(2), ...
    semi_detect(2), ...
    semi_disassembly(2), ...
    y(2), ...
    u(2));


semi3 = evaluate_node( ...
    parts(7:8), ...
    semi_p(3), ...
    semi_assembly(3), ...
    semi_detect(3), ...
    semi_disassembly(3), ...
    y(3), ...
    u(3));


semis = [semi1 semi2 semi3];


%% =========================================================
% 7. 最终成品
%% =========================================================

final = evaluate_final( ...
    semis, ...
    final_p, ...
    final_assembly, ...
    final_detect, ...
    final_disassembly, ...
    replacement_loss, ...
    z, ...
    v);


%% =========================================================
% 8. 成本和利润
%% =========================================================

cost = final.C;

profit = ...
    sale_price - cost;


%% =========================================================
% 9. 保存详细结果
%% =========================================================

detail.bits = bits;

detail.semi1 = semi1;
detail.semi2 = semi2;
detail.semi3 = semi3;

detail.final = final;

detail.cost = cost;
detail.profit = profit;

end