---
weight: 1135
title: "3.07 Quadrature Amplitude Modulation (QAM)"
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


## 3.7.1 QAM 송신기 구조

![Internal link preview tooltip](/images/content/qam/pic2.png)  

위 그림은 QAM Modulator의 구조다. 위 구조를 바탕으로 단계를 따라가면 QAM Waveform이 생성되는 과정을 살펴본다.

### 3.7.1.1 Bits to Symbol

QAM 웨이브폼을 만들기 위한 순서에 대해 알아보자. 설명을 쉽게 하기 위해 2-QAM을 가정한다. 

2-QAM은 비트 1개가 심볼 1개에 매핑되는 QAM 변조 방식이다. 만약 4-QAM이라면 비트 2개가 심볼 1개에 매핑된다.

먼저 비트레이트 $R_b$에 해당하는 속도로 비트가 생성된다. 2-QAM 기준으로 비트 1개가 심볼 1개를 구성하므로 심볼레이트 $T_M = R_b$가 성립한다.

들어온 비트는 미리 정의된 LUT의 주소로 사용되어 심볼과 매핑된다.

![Internal link preview tooltip](/images/content/qam/pic1.png)  

위 그림을 참고해보면 쉽게 이해할 수 있다. 예를 들어 비트 00이 들어오면 I-Waveform에 해당하는 심볼은 $+A$가 되고 Q-Waveform에 해당하는 심볼은 $-A$가 된다.

그래서 성상도에서 제 4사분면에 위치하는 심볼로 결정된다.

만약 비트 01이 들어오면 주소는 1이다. 즉 I-Waveform에 해당하는 심볼은 $-A$가 되고 Q-Waveform에 해당하는 심볼은 $-A$가 된다. 그리고 성상도에서 제 3사분면에 위치하는 심볼로 결정된다.

이러한 방식으로 연속으로 들어온 2개의 비트를 각각 I와 Q 심볼에 매핑해 같은 시간에 심볼을 병렬적으로 보낼 수 있다.

### 3.7.1.2 Up-Sampling
다음은 Up-Sampling 차례다. 디지털 신호를 처리하기 위해서 고속의 샘플레이트를 갖는 FPGA를 사용하는데, 이때 사용되는 클럭이 SampleRate를 결정한다.

만약 SymbolRate가 100Mbps고 SampleRate가 200MHz라면 SymbolRate를 SampleRate에 맞추기 위해 2배 Up-Sampling을 수행하게 된다.

이 때 기호로 $L$로 표현하고 $L=2$는 심볼 당 샘플 수라고 정의한다. 심볼레이트와 샘플레이트의 관계는 $T_S = LT_M$를 만족한다.

I-Waveform과 Q-Waveform에 각각 Upsampling을 수행하면 $\tilde{a_I}(nT_S)$와 $\tilde{a_Q}(nT_S)$와가 만들어지게 된다.

### 3.7.1.3 Pulse Shaping
다음은 Pulse Shaping차례다. 3.6절에서는 최적의 Pulse-Shaping Filter로 SRRC(Squared-Root-Raised-Cosing Filter)를 발견했다.

$\tilde{a_I}(nT_S)$와 $\tilde{a_Q}(nT_S)$과 SRRC 필터의 계수를 시간 축에서 Convolution을 수행해 Pulse Shaping 과정을 수행한다.

식으로 표현하면 아래와 같다.

$$v_I(nT_S) = \tilde{a_I}(nT_S) * p(nT_S)\quad (I-Waveform)$$ 
$$v_Q(nT_S) = \tilde{a_Q}(nT_S) * p(nT_S)\quad (Q-Waveform)$$ 

그리고 Convolution 정의에 맞게 풀어 정리하면 아래와 같다.

$$v_I(nT_S) = \sum_{m=-\infty}^{\infty} a_I[m] \cdot p\big( n T_S - m T_M \big)$$
$$v_Q(nT_S) = \sum_{m=-\infty}^{\infty} a_Q[m] \cdot p\big( n T_S - m T_M \big)$$

### 3.7.1.4 Upconverter

Pulse Shaping필터를 거쳐 나온 I-Waveform과 Q-Waveform신호를 FFT하여 주파수 스펙트럼을 나타내면 아래와 같다.

![Internal link preview tooltip](/images/content/qam/pic3.png)  

그림에서 확인할 수 있듯이 중심 주파수가 0이다. 이런 신호를 Baseband 신호로 표현한다. 실제 무선 통신에서는 Baseband 신호로 신호를 송신하면 많은 단점을 초래한다.

따라서 중심 주파수를 높은 주파수로 옮기는 방식을 통해 Baseband 신호를 Passband 신호로 바꾼다. 이러한 과정을 Upconverter라고 표현한다.

높은 주파수로 옮기기 위해 Baseband신호의 I-Waveform에 cos을 곱하고 Q-Waveform에 Sin을 곱한다. 이 때 Cos과 Sin이 갖는 주파수를 Carrier Frequency라고 한다.

수식으로 $F_C$로 표현한다.

Pulse Shaping 이후의 신호에 Upconverter를 적용한 수식은 아래와 같다. 이 때 I신호와 Q신호는 더해서 복소수로 표현한다.

$$s(nT_S) = v_I(nT_S)2^{1/2}cos2\pi\frac{F_C}{F_S}n-v_Q(nT_S)2^{1/2}sin2\pi\frac{F_C}{F_S}n$$

$$s(nT_S) = v_I(nT_S)2^{1/2}cos2\pi F_C nT_S-v_Q(nT_S)2^{1/2}sin2\pi F_CnT_S$$

위 신호는 Upconverter된 QAM 신호를 수식으로 표현했다.

Carrier를 곱하는 과정에서 루트2를 곱하는 이유는 I심볼과 Q심볼의 에너지를 1로 유지하기 위함이다.

### 3.7.1.5 DAC
upconverted 된 QAM 송신 신호는 DAC를 거쳐 아날로그 신호로 변화한다. 식으로 나타내는 것은 간단하다 이산 시간 인덱스 $nT_S$를 연속 시간 $t$로 바꿔주면 된다.

$$s(t) = v_I(t)2^{1/2}cos2\pi F_C nt - v_Q(t)2^{1/2}sin2\pi F_Cnt$$


### 3.7.1.6 I-Waveform과 Q-Waveform의 관계

우리는 연속된 비트 2개를 각각 I-Waveform과 Q-Waveform로 매핑했고, Pulse Shaping을 수행한 뒤, Upconverter를 통해 QAM 송신 신호를 만들었다.

이러한 과정의 핵심은 병렬처리에 있다. 연속된 2개의 비트는 시간적으로 선후관계가 명확하다. 쉽게 말하면 처음 들어온 비트와 두 번째로 들어온 비트가 시간 간격을 두고 들어온다.

그러나 QAM 변조를 위해 연속된 2개의 비트를 각각 I-Waveform과 Q-Waveform 심볼로 매핑해 같은 시간에 파형을 내보내 병렬 처리가 가능하다는 뜻이다.

그러나 병렬로 처리하려면 I-Waveform과 Q-Waveform이 서로 영향을 줘서는 안된다. 아래 그림을 참고해보자.

![Internal link preview tooltip](/images/content/qam/pic4.png) 

(a)그림은 I-Waveform과 Q-Waveform의 Pulse Shaping이후의 파형을 시간 축에서 나타낸 그림이다. 그림에서 알 수 있듯이 I-Waveform과 Q-Waveform은 복소평면에서 위상이 90도 차이를 보인다. 이러한 직교성을 활용하면 서로에 간섭없이 병렬처리가 가능하다는 것이다.

우리는 3.7.4에서 최종 QAM 신호 $s(nT_S)$를 표현하기 위해서 I-Waveform과 Q-Waveform을 서로 더했다. 그 결과가 위 그림의 (c)다.

그림상으로는 I-Waveform과 Q-Waveform이 뒤섞인 것처럼 보이지만 위상이 90도 차이를 보이기 때문에 수신기는 이들을 분리해 낼 수 있다.

우리는 QAM 신호를 심볼을 활용하여 아래와 같이 다시 표현 가능하다.

$$s(nT_S) = \sum_{m=-\infty}^{\infty} a_I[m] \cdot p\big( n T_S - m T_M \big)2^{1/2}cos2\pi F_C nT_S-\sum_{m=-\infty}^{\infty} a_Q[m] \cdot p\big( n T_S - m T_M \big)2^{1/2}sin2\pi F_CnT_S$$

위 식을 삼각함수 합성 공식을 활용하여 정리하면 아래와 같이 표현 가능하다.

$$s(nT_S) =  \sum_{m=-\infty}^{\infty} 2^{1/2} \cdot \sqrt{a_I(nT_S)^2 + a_Q(nT_S)^2} \cdot \cos\left(2\pi F_C nT_S + \tan^{-1}\left(-\frac{a_Q(nT_S)}{a_I(nT_S)}\right)\right)$$

삼각함수 합성결과 나온 식의 cos부분을 따로 쓰면 $$\cos\left(2\pi F_C nT_S + \tan^{-1}\left(-\frac{a_Q(nT_S)}{a_I(nT_S)}\right)\right)$$ 을 만족한다.

이 cos 함수의 그래프를 그려보면 아래와 같다.

![Internal link preview tooltip](/images/content/qam/pic5.png) 

그림에서 알 수 있듯 심볼레이트 $T_M$간격으로 위상이 급격하게 변화하는 것을 알 수 있다.

### 3.7.1.6 PAM과 QAM의 관계


![Internal link preview tooltip](/images/content/qam/pic6.png) 

위 그림을 살펴보면 결국 QAM은 PAM의 심볼레이트를 2배 올린 변조 방식임을 알 수 있다.

2배 빠른 심볼레이트를 처리하기 위해서 I-Waveform과 Q-Waveform을 만들어 병렬처리를 수행한다.

## 3.7.2 QAM 수신기 구조

이제 QAM Waveform을 수신할 차례다. QAM 수신기는 QAM 송신기의 역순으로 진행된다. 전체적인 구조는 아래 그림과 같다.

![Internal link preview tooltip](/images/content/qam/pic7.png) 

QAM RF 송신 신호는 아래와 같다.

$$s(t) = v_I(t)2^{1/2}cos2\pi F_C nt - v_Q(t)2^{1/2}sin2\pi F_Cnt$$

### 3.7.2.1 ADC
이 신호를 ADC를 거쳐 아날로그 신호를 디지털 신호로 변환한다. 연속 시간 $t$를 이산 시간 $nT_S$로 바꿔 표현하면 된다.

$$r(nT_S) = v_I(nT_S)2^{1/2}cos2\pi F_C nT_S-v_Q(nT_S)2^{1/2}sin2\pi F_CnT_S + w(t)$$

그런데 한 가지 주목해야 할 점은 $w(t)$다. 이는 무선 환경에서 추가된 AWGN 노이즈를 나타낸다.

### 3.7.2.2 Down-Converter

이제 Passband에 위치한 신호를 다시 Baseband신호로 내려줘야 한다. 이를 위해서 Up-Converter에서 곱했던 Cos신호와 Sin신호를 다시한 번 곱해준다.

Down-Converter된 신호는 아래와 같다.

![Internal link preview tooltip](/images/content/qam/pic8.png) 

식을 잘 살펴보면 Baseband 신호인 $v_I(nT_S)$와 $v_Q(nT_S)$가 보이고 그 뒤로 2배의 주파수 성분을 갖는 항이 추가되어 보인다.

2배의 주파수 성분은 이후의 Matched Filtering을 통해 사라지게 된다.

Down-Converter 이후의 신호를 $x_I(nT_S)와 x_Q(nT_S)$로 표현한다.

### 3.7.2.3 Matched Filtering

![Internal link preview tooltip](/images/content/qam/pic9.png) 

이제 RRC 필터와 컨볼루션을 수행해 Matched Filtering을 수행한다. 위 식에서 살펴보면

2배의 주파수 성분 항은 Matched Filter를 거치면서 사라지게 된다. Matched Filtering의 주파수 응답은 Low-Pass Filter이기 때문에 가능하다.

Matched Filtering 이후의 신호를 $z_I(nT_S)$ 와 $z_Q(nT_S)$로 표현한다.

### 3.7.2.4 Decision of Symbol 

이제 Up-Sampling된 신호에서 최적의 심볼에 해당하는 샘플을 추출하고 나머지는 버리는 과정을 수행한다. 이를 위해 Down-Sampling을 수행한다.

아래 식을 참고해보자.

![Internal link preview tooltip](/images/content/qam/pic10.png) 

$nT_S$ 디지털 신호를 $m_TM$ 심볼 속도로 다운 샘플링하여 최종 수신 심볼에 대한 식을 완성한다.

이 떄 $r_p$는 SRRC의 Auto-Correlation결과이다. SRRC의 Auto-Correlation 결과는 No-ISI 조건을 만족하므로 심볼 간 간섭이 존재하지 않는다.

따라서 위 식의 ISI항을 없앨 수 있다.

그래서 최종 수신된 심볼은 $z_I(mT_M)$과 $z_Q(mT_M)$으로 표현 가능하다.

## 3.7.3 가정

QAM 송/수신 구조를 분석하면서 누락한 가정들이 존재한다.

### 3.7.3.1 Symbol Timing Offset
실제로 ADC가 신호를 변환할 때 송신 신호의 최적의 시작 시점을 샘플링하지 않는다. 이러한 오차는 SRRC 필터의 No-ISI 조건을 깨트린다. 따라서 이러한 Symbol Timing Offset에 대한 보정이 수신기에 추가로 필요하다.

### 3.7.3.2 Resampling
ADC가 신호를 수신할 때 심볼의 정수배의 SampleRate로 신호를 변환하지 않는다. 따라서 실수배의 SampleRate를 갖는 신호를 정수배의 SampleRate로 Re-Sampling하는 과정이 필요하다.

### 3.7.3.3 Carrier Frequency Offset
무선 환경에서 물체의 이동에 의해 발생하는 도플러효과가 존재한다. 또한 Up-Conversion과 Down-Conversion에 사용되는 오실레이터의 주파수 역시 완벽히 동일하지 않다.
여기서 발생하는 Carrier Freuqncy Offset을 보정해야 한다.

### 3.7.3.4 Carrier Phase Offset
오실레이터의 시작 위상 역시 랜덤하다. 따라서 이러한 위상 차이를 보정해야 한다.

### 3.7.3.5 Equalization
실제 무선 통신 환경에서는 AWGN 노이즈만 존재하는 것이 아니다. 다중 경로 페이딩에서 발생하는 심볼간 간섭을 보정하기 위한 블록이 필요하다.