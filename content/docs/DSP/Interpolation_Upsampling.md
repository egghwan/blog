---
title: "Interpolation vs Upsampling"
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
신호처리를 할 때 Interpolation과 Up-sampling은 헷갈리는 개념이다.

Interpolation을 정확히 이해하기 위해서 먼저 Interpolation과 Up-sampling의 의미에 대해 알아보고, 신호처리 관점 및 RTL구현 관점에서 해당 개념을 기술한다.

## 2. 정의 

- Interpolation : 디지털 신호를 먼저 샘플들 사이에 0을 집어넣어 up-sampling을 진행한다. 그 다음 Low-Pass-Filtering을 수행한다.

- Up-sampling : 디지털 신호를 샘플들 사이에 up-sampling factor 만큼 0을 넣어 up-sampling을 한다.

Interpolation과 Up-Sampling의 차이는 Low-Pass-Filtering을 수행하냐 안 하냐의 차이다.

## 3. 상황 가정 및 문제

두 개념의 차이를 설명하기 위해 아래와 같은 상황을 가정해보자.

1. 수신 신호 : 중심 주파수가 150Hz이고 대역폭이 143.75Hz인 대역 신호

2. 샘플링 클럭 : 1kHz

5. 수신 신호를 facotr = 2로 Interpolation 하는 상황

모뎀 수신 동기화 알고리즘에서 Interpolation을 통해 심볼 타이밍을 복구하는 경우가 있다. 따라서 수신 신호를 Interpolation 하는 상황이 종종 있다.

단순히 시간 축에서 0을 추가하여 샘플링 클럭 높히는 Up-sampling이면 충분할까? 답은 아니다.

그 이유를 신호처리 관점에서 이해해보자.

## 4. 신호처리 관점
&nbsp;

### 4.1 스펙트럼 분석

주파수 영역에서 신호를 분석하면 두 개념의 차이를 쉽게 이해할 수 있다. 아래 그림은 수신 신호의 스펙트럼이다.

![Internal link preview tooltip](/images/content/interpolation/rx_sig.png)  


이제 시간 축에서 디지털 신호에 0을 추가해서 up-sampling을 전행하면 아래 스펙트럼과 같이 바뀐다.

![Internal link preview tooltip](/images/content/interpolation/upsampling.png)  

Up-Sampling 이후에 빨간색 Image 신호가 보이기 시작한다. 이러한 Image 신호는 신호 품질에 영향을 준다.

### 4.2 LPF의 필요성

따라서 위 Image 신호를 LPF를 통해 필터링 해줘야 한다.

아래 그림은 이미지 신호를 LPF를 통해 필터링한 스펙트럼이다. 

![Internal link preview tooltip](/images/content/interpolation/lpf.png)  

이렇게 이미지 신호를 제거해줘야 비로소 Interpolation이 완성된다.

&nbsp;

### 4.3 시간 축에서 Upsampling과 Interpolation 비교
시간 축에서 Interpolation과 Upsampling을 비교해보자.

파란색 신호는 0을 추가해서 up-sampling을 한 신호다. 빨간색 신호는 Interpolation(up-sampling 후 LPF)을 한 신호다.

신호를 보면 알 수 있듯이, 단순히 up-sampling만 한 신호 대비, LPF를 추가로 수행하여 Interpolation을 하면 신호가 부드럽게 채워짐을 알 수 있다.

이 효과를 통해 샘플 사이의 값을 유추할 수 있는 효과가 나타난다. 그래서 모뎀의 수신 동기화 알고리즘에서 많이 사용한다.

![Internal link preview tooltip](/images/content/interpolation/time_interp.png)  

### 4.3 MATLAB 코드
```MATLAB
close all;
clear all;
%% Set Simulation Parameter
fs = 500;                              % SampleRate
sps = 8;                                % SampleperSym
beta = 0.15;                            % RRC roll-off
span = 10;                              % filter span (심볼 단위)
NFFT = 2^15;                            % FFT Size
t = 0:1/fs:10;                           % Continuous Time index
f = linspace(-fs/2, fs/2, NFFT);        % Discrete-Frequency axis (SampleRate)
f_up = linspace(-fs, fs, NFFT);         % Discrete-Frequency axis (Upsample)

%% RRC pulse shaping 필터 생성
rrc_filter = rcosdesign(beta, span, sps, 'normal'); % (RRC Filter coeffs)

%% Create my Signal
my_bits = 2*randi([0 1], 1, 500)-1;                         % BPSK Modulation
my_upsampled = upsample(my_bits, sps);                      % upsampling
my_shaped = conv(my_upsampled, rrc_filter, 'same');         % RRC Pulse shaping
fc1 = 150;                                                  % My Signal Center Freq
my_sig = my_shaped .* cos(2*pi*fc1*t(1:length(my_shaped))); % Upconversion

%% rx_sig
rx_sig = my_sig;  

%% rx_sig spectrum
figure;
fft_my = 20*log10(abs(fftshift(fft(my_sig,NFFT))));
fft_rx_sig = 20*log10(abs(fftshift(fft(rx_sig,NFFT))));
plot(f, fft_rx_sig);
title('rx sig');
legend('수신 신호')
%% Upsampling (Zero-Padding)
up_rx_sig = upsample(rx_sig,2); % Zero-Padding을 수행하면 이미지 시그널이 생김
fft_up_my = 20*log10(fftshift(abs(fft(up_rx_sig, NFFT))));

img_idx = abs(f_up) > fs/2;
origin_idx = abs(f_up) < fs/2;

figure;
plot(f_up(img_idx), fft_up_my(img_idx),'r');
hold on;
plot(f_up(origin_idx), fft_up_my(origin_idx),'b');
title('Upsampling Signal')
legend('수신 신호','이미지 신호');

%% Interpolation
interp_rx_sig = lowpass(up_rx_sig, 0.5);
fft_interp_rx_sig = 20*log10(fftshift(abs(fft(interp_rx_sig,NFFT))));
figure;
plot(f_up, fft_interp_rx_sig);
title('Interpolation Signal');

```

&nbsp;
### 4.4 신호처리 관점 결론

Interpolation과 Upsampling의 차이는 LPF의 유무이다. Interpolation을 하기 위해서는 Up-sampling 이후에 LPF를 통해 Image 신호를 제거함을 기억하자.

## 5. 구현관점

신호처리 관점에서 Interpolation을 수행하는 과정을 살펴보았다. 과정을 요약해보면 Upsampling Factor만큼 0을 넣어서 Upsampling을 한다. 그 다음 LPF를 통과해 스펙트럼 상에서 Image 신호를 제거한다.


![Internal link preview tooltip](/images/content/interpolation/picture1.png)  

위 그림을 살펴보면, 위 아래가 각각 주파수 축과 시간 축에서 대응되는 신호다. 

주파수 축에서 수신 신호를 2배 Upsampling한 신호에 대해 완벽한 LPF를 곱한다면 Image신호가 완벽하게 제거될 것이다.

그러나 완벽한 LPF는 시간 축에서 무한한 길이의 Sinc 파형이다.

주파수 축에서 곱은, 시간 축에서 Convolution이므로 이는 곧 무한한 계수를 갖는 Sinc 계수를 시간 축에서 Convolution을 해야 Image가 완벽히 제거된 Interpolation 신호를 얻을 수 있다는 것이다.

따라서 완벽한 LPF를 곱하는 방식으로 Interpolation을 수행하는 것은 구현 관점에서 불가능하다. 이를 해결하기 위해 엔지니어들은 다양한 근사화를 시도했다.

&nbsp;

### 5.1 Fir Filter기반 Interpolation

근사화를 하는 가장 쉬운 방법은 덜 완벽한 LPF를 사용하는 것이다.