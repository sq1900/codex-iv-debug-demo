clc;
clear;
close all;

% 初始版本：读取单个器件数据
data = readmatrix('irf3710.txt');

% 提取第一列和第二列
x = data(:,1);
y = data(:,2);

% 使用三次多项式拟合
p = polyfit(x, y, 3);
y_fit = polyval(p, x);

% 绘图
figure;
plot(x, y, 'bo');
hold on;
plot(x, y_fit, 'r--', 'LineWidth', 2);

xlabel('Current');
ylabel('Voltage');
title('IRF3710 Polynomial Fitting');
legend('Original Data', 'Polynomial Fit');
grid on;