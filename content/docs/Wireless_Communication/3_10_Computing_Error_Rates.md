---
weight: 1135
title: "3.10 Computing Error Rates"
icon: keyboard_double_arrow_right
description: "How to configure Breadcrumb navigation for your Lotus Docs site."
date: 2022-11-27T07:08:15+00:00
lastmod: 2023-08-16T02:49:15+00:00
aliases:
    - ../guides/theme-options/breadcrumbs
draft: false
images: []
toc: true
katex: true
---


## 3.10 Computing Error Rates
디지털 통신 모뎀을 설계하고 나면 성능을 측정해야 한다. 가장 대표적인 성능 측정 방법으로는 BER(Bit-Error-Rate) 또는 SER(Symbol-Error-Rates)있다.
BER 공식은 아래와 같다.

### 3.10.1 SER 과 BER
![Internal link preview tooltip](/images/content/ber/pic1.png) 

식은 간단하다. SER의 경우 에러가 난 심볼 개수를 전체 송신 심볼 개수로 나누면 된다.

BER의 경우 에러나 난 비트 개수를 전체 송신 비트 개수로 나누면 된다.

### 3.10.2 SNR

SNR은 디지털 통신 모뎀의 성능을 측정할 때 가장 많이 사용되는 지표다. 정의는 신호 전력을 노이즈 전력으로 나눈 값이다.

$$ SNR_{dB} = 10log{\frac{P_M}{P_w}} = 10log{P_M}-10log{P_w} $$

이 때 신호 전력 $P_M$은 평균 심볼 에너지 $E_M$을 심볼 시간 $T_M$으로 나눈 값이다.

$$ P_M = \frac{E_M}{T_M} $$

아래 수신 신호에 대한 SNR을 나타내는 그림이다.

![Internal link preview tooltip](/images/content/ber/pic2.png) 

스펙트럼에서 신호의 피크 전력과 노이즈 플로의 전력의 차이를 구하면 SNR을 구할 수 있다.

### 3.10.3 EbNo

EbNo 지표를 이해하기 위해서는 먼저 단위 대역폭 잡음 전력 $N_0$을 이해해야한다.

$N_0$는 단위 대역폭 잡음 전력이고 단위는 W/Hz로 정의된다. 즉 대역폭을 나타내는 Hz당 잡음 전력을 의미한다.

만약 노이즈 대역폭이 3Hz라면 노이즈 전력은 $3N_0$가 되는 것이다.

즉 대역 노이즈의 전력은 $P_w = N_0B$를 만족한다.

SNR과 EbNo의 관계에 대해 알아보자.

$SNR = \frac{P_M}{P_w} = \frac{E_M}{T_M}  \frac{1}{N_0B} $ 이다.

하나의 심볼을 구성하는 비트는 $log_2M$개 이므로 심볼 전력 $E_M$을 심볼을 구성하는 비트의 개수 $log_2M$으로 나누면 비트 전력 $E_b$가 나온다.

$$E_b = \frac{E_M}{log_2M} $$

비트레이트 $R_b$는 심볼을 구성하는 비트의 개수를 심볼 시간으로 나눈 값이다.

$$R_b = \frac{log_2M}{T_M}$$

위 식을 정리하면 EbNo 식이 도출된다.

$$\frac{E_b}{N_0} = SNR \frac{B}{R_b} $$

### 3.10.4 실제 웨이브폼에서 EbNo 계산하기

MATLAB에서 제공하는 변환 식이다. 참고하자.


![Internal link preview tooltip](/images/content/ber/pic4.png) 