---
title: "Decimation vs Down-sampling"
description: ""
icon: "code"
date: "2023-05-22T00:44:31+01:00"
lastmod: "2023-05-22T00:44:31+01:00"
draft: false
toc: true
weight: 210
---

{{% alert context="warning" text="The front matter `description` value for this page has been intentionally left empty in order to demonstrate FlexSearch's suggested results fallback behaviour." /%}}

## 1. 문서 설명
신호처리를 할 때 Decimation과 down-sampling는 헷갈리는 개념이다.

Decimation과 down-sampling의 의미에 대해 알아보고, 신호처리 관점 및 RTL구현 관점에서 해당 개념을 기술한다.

## 2. 정의 

- Decimation : 디지털 신호를 먼저 Low-Pass-Filtering(LPF)를 수행하고, 디지털 신호를 구성하는 샘플들 중 특정 간격의 샘플만 취한다.

- down-sampling : 디지털 신호를 구성하는 샘플들 중 특정 간격의 샘플만 취하고 끝난다.

Decimation과 down-sampling의 차이는 LPF를 수행하냐 안 하냐의 차이다. 아래 섹션에서 자세히 알아보자.

## 3. 상황 가정 및 문제

두 개념의 차이를 설명하기 위해 아래와 같은 상황을 가정해보자.

1. 내가 사용하는 신호 : 중심 주파수가 150Hz이고 대역폭이 143.75Hz인 대역 신호

2. 남이 사용하는 신호 : 중심 주파수가 400Hz이고 대역폭이 143.75Hz인 대역 신호

3. 수신 신호 : 내가 사용하는 신호 + 남이 사용하는 신호 &nbsp; (노이즈는 없다고 가정하자, 남의 신호를 노이즈라고 가정해도 된다.)

4. 샘플링 클럭 : 1kHz

5. 수신 신호를 facotr = 2로 Decimation 하는 상황

샘플링 클럭을 낮춰 수신 신호를 처리하면 구현 관점에서 전력, 발열에 유리하다. 그래서 수신 신호를 Decimation하는 상황을 가정했다.

샘플링 클럭을 낮추기 위해서 단순히 시간 축에서 특정 간격의 샘플만 선택하는 down-sampling이면 충분할까? 답은 아니다.

그 이유를 신호처리 관점에서 이해해보자.

## 4. 신호처리 관점

### 4.1 스펙트럼 분석

주파수 영역에서 신호를 분석하면 두 개념의 차이를 쉽게 이해할 수 있다. 아래 그림은 수신 신호의 스펙트럼이다.

![Internal link preview tooltip](/images/content/decimation/rx_sig_1.png)  

파란색 신호는 내가 만든 신호고, 빨간색 신호는 남이 만든 신호다. 발열을 낮추기 위해 수신 신호를 절반의 샘플링 클럭인 500Hz로 down-sampling을 해보자.

아래 스펙트럼은 시간 축에서 수신 신호의 샘플을 2개 간격으로 선택하여 샘플링 클럭을 500MHz로 낮춘 신호다.

![Internal link preview tooltip](/images/content/decimation/rx_sig_downsample_1.png)  

보다시피 빨간색인 남이 만든 신호가 Aliasing이 일어나 내 신호를 간섭하는 것을 확인할 수 있다. 여기서 간단히 Aliasing이 일어난 과정을 알아보자.

샘플링 클럭이 500MHz이므로 유효 주파수 대역은 그 절반인 250MHz다. 따라서 250MHz 이상의 신호 성분은 0~250MHz 영역으로 Aliasing이 일어나게 된다.

400Mhz 신호는 250MHz기준 오른쪽으로 150Mhz 떨어져 있기 때문에 250MHz를 기준으로 왼쪽으로 150MHz만큼 떨어진 100MHz에 Aliasing이 일어난다.

결과적으로 down-sampling 이전에는 신호들이 서로 분리되어 간섭을 주지 않았지만, down-sampling 이후에는 신호들이 서로 간섭한다.

&nbsp; 


### 4.2 Low-Pass-Filtering의 필요성

4.1에서 살펴봤듯이 down-sampling에 의해 aliasing되는 신호 때문에 내 신호에 간섭이 발생할 수 있다. 

따라서 2개 간격으로 샘플을 선택하는 down-sampling을 하기 이전에 먼저 간섭이 될 수 있는 신호를 제거해야한다. 이를 위해 먼저 LPF를 통과 시킨다.

Decimation Factor가 2이므로 Passband가 250MHz인 LPF를 적용한다. 

아래 그림은 LPF를 거친 수신 신호의 스펙트럼이다. (아직 샘플링 클럭은 1kHz다.)

![Internal link preview tooltip](/images/content/decimation/lpf_rx_1.png) 

LPF를 거친 이후에, 신호를 2개 샘플 간격으로 선택하는 down-sampling을 진행한다.

아래 그림은 LPF를 한 후, down-sampling을 진행한 스펙트럼이다.

![Internal link preview tooltip](/images/content/decimation/deci_sig_1.png) 

그림에서 알 수 있듯이, 단순히 down-sampling을 진행했을 때보다. Decimation(LPF + down-sampling)을 진행했을 때, 내 신호에 대한 간섭이 줄어 들었음을 확인할 수 있다.


&nbsp;

### 4.3 MATLAB CODE
```MATLAB
close all;
clear all;

%% Set Simulation Parameter
fs = 1000;                              % SampleRate
sps = 8;                                % SampleperSym
beta = 0.15;                            % RRC roll-off
span = 10;                              % filter span (심볼 단위)
NFFT = 2^15;                            % FFT Size

t = 0:1/fs:5;                           % Continuous Time index
f = linspace(-fs/2, fs/2, NFFT);        % Discrete-Frequency axis (SampleRate)
f_down = linspace(-fs/4, fs/4, NFFT);   % Discrete-Frequency axis (Downsample)
%% RRC pulse shaping 필터 생성
rrc_filter = rcosdesign(beta, span, sps, 'normal'); % (RRC Filter coeffs)

%% Create My Signal
my_bits = 2*randi([0 1], 1, 500)-1;                         % BPSK Modulation
my_upsampled = upsample(my_bits, sps);                      % upsampling
my_shaped = conv(my_upsampled, rrc_filter, 'same');         % RRC Pulse shaping

fc1 = 150;                                                  % My Signal Center Freq
my_sig = my_shaped .* cos(2*pi*fc1*t(1:length(my_shaped))); % Upconversion

%% Create Other Signal
other_bits = 2*randi([0 1], 1, 500)-1;                      % BPSK Modulation
other_upsampled = upsample(other_bits, sps);                % upsampling
other_shaped = conv(other_upsampled, rrc_filter, 'same');   % RRC Pulse shaping

fc2 = 400;                                                  % Ohter signal Center Freq
other_sig = other_shaped .* cos(2*pi*fc2*t(1:length(other_shaped))); % Upconversion

%% rx_sig
rx_sig = my_sig + other_sig;                           

%% rx_sig spectrum
figure;
fft_my = 20*log10(abs(fftshift(fft(my_sig,NFFT))));
fft_other = 20*log10(abs(fftshift(fft(other_sig,NFFT))));

plot(f, fft_my);
hold on;
plot(f, fft_other,'r');
title('rx sig');
xlabel('Frequency (Hz)');
legend('내 신호','남의 신호');

%% Downsampling
down_my = my_sig(1:2:end);          % my_signal downsampling
down_other = other_sig(1:2:end);    % other_signal downsampling
down_rx = down_my + down_other;     % rx_signal downsampling

fft_down_my = 20*log10(abs(fftshift(fft(down_my,NFFT))));
fft_down_other = 20*log10(abs(fftshift(fft(down_other,NFFT))));

%% Downsampling spectrum
figure;
plot(f_down, fft_down_my);
hold on;
plot(f_down, fft_down_other,'r')
title('Downsampled Spectrum (Aliased & Overlapped)');
xlabel('Frequency (Hz)');
legend('내 신호','남의 신호');

%% Decimation
lpf_my = lowpass(my_sig, 0.5);      % my_signal LPF filtering
lpf_other = lowpass(other_sig, 0.5);% other_signal LPF filtering

deci_my = lpf_my(1:2:end);          % my_signal downsampling
deci_other = lpf_other(1:2:end);    % other_signal downsampling


fft_lpf_rx = 20*log10(abs(fftshift(fft(lpf_my,NFFT))));
fft_lpf_other = 20*log10(abs(fftshift(fft(lpf_other,NFFT))));

fft_deci_my = 20*log10(abs(fftshift(fft(deci_my,NFFT))));
fft_deci_other = 20*log10(abs(fftshift(fft(deci_other,NFFT))));

%% LPF Spectrum
figure;
plot(f, fft_lpf_rx);
hold on;
plot(f, fft_lpf_other);
title('After LPF Spectrum')
xlabel('주파수 (Hz)');
legend('내 신호', '남의 신호');

%% Decimation(LPF + downsampling) spectrum
figure;
plot(f_down, fft_deci_my);
hold on;
plot(f_down, fft_deci_other,'r');
title('Decimation Spectrum')
xlabel('주파수 (Hz)');
legend('내 신호', '남의 신호');


```
해당 예제를 모델링 한 MATLAB 코드다. 

- 18 ~ 31 Line : 내 신호와, 남의 신호를 대역 신호로 만드는 과정이다. (대역 신호를 만드는 방법은 추후 포스팅)

- 34 ~ 36 Line : 수신 신호 스펙트럼 모델링

- 49 ~ 63 Line : Down-sampling 한 스펙트럼 모델링

- 66 ~ 95 Line : Decimation (LPF + downsampling) 한 수신 신호 모델링

&nbsp; 


### 4.4 신호처리 관점 결론

Decimation이란 Low-Pass-Filtering을 수행한 뒤 down-sampling을 하는 것을 의미한다.

현업에서 설계를 할 때 모뎀 신호를 down-sampling을 한다고 표현하면 큰일난다. 내 신호가 간섭되어 엉망이 되어도 상관 없다는 말을 하는 것과 같기 때문이다.

따라서 신호를 Decimation 한다는 표현을 꼭 사용하자. 아니면 Low Pass Filtering을 거친 후 down-sampling을 진행 한다고 말하는게 정확한 표현이다.

&nbsp; 


### 5 구현 관점