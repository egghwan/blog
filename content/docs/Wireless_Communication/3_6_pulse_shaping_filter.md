---
weight: 1135
title: "3.06 Pulse Shaping Filter"
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

## 3.6 Pulse Shaping Filter

통신 모뎀 설계를 위해 필요한 펄스 정형 필터에 대해 기술한다.

### 3.6.1 ISI(Inter-Symbol-Interference)란?

한국어로 직역하면 심볼 간 간섭이다. 명확한 이해를 위해 아래 그림을 살펴보자.


![Internal link preview tooltip](/images/content/pulse_shaping/pic1.png)  

빨간색 동그라미는 심볼이고 파란색 동그라미는 심볼을 4배 Upsampling한 샘플을 나타낸다. 위 심볼들은 시간 축에서 직사각형 형태를 띈다. 이렇게 직사각형 형태로 신호를 만들면 서로 다른 심볼은 다른 심볼 구간을 침범하지 않고 분리되어 있다. 이런 경우 심볼 간 간섭(ISI)가 없다고 말한다.

그러나 이러한 직사각형 펄스 형태의 신호는 많은 문제가 있다. 이를 이해하기 위해 먼저 직사각형 펄스 형태의 신호를 알아보자.

### 3.6.2 Spectrum of Rectangular Pulse

3.6.1 그림에서 심볼 1개에 대한 신호만 보면 직사각형 펄스 형태의 신호를 보인다. 시간 축에서 직사각형 펄스는 주파수 축에서 Sinc 형태를 보인다.

심볼 당 샘플 수가 $L$인 직사각형 펄스 신호의 주파수 스펙트럼 식은 아래와 같이 쓸 수 있다.

$$
\left|P_{\text{rect}}[k]\right| = \frac{\sin\left(\pi L k / N\right)}{\sin\left(\pi k / N\right)}
\$$

위 식에서 주파수 성분의 크기가 0이 되는 순간은 분자가 0일 때다. 따라서 $ \pi L (k / N) $ 이 $ \pi $의 배수일 때 분모가 0이 된다. 따라서 $ k / N = \pm 1 / L, \pm 2 / L ... $ 일 때 분자는 0이된다.

이산 주파수 성질을 활용해 $F_{null} = F_S\frac{k}{N} = F_S\frac{m}{L}=\frac{m}{T_M}$로 다시 쓸 수 있다. 여기서 $m$은 정수다.

정리하면 시간 축에서 심볼 당 샘플이 $L$개인 직사각형 펄스의 주파수 스펙트럼은 이산 주파수 $ \pm 1 / T_M, \pm 2 / T_M, \pm 3 / T_M ... $ 일 때 크기가 0이다.

나이퀴스트 정리에 의해 유효한 주파수 범위는 $-0.5F_s \leq F \leq 0.5F_S $ 인데 심볼 당 샘플 수가 $L$이고 심볼 레이트 $T_M$이면 $F_S = L/T_M$이 성립한다. 

따라서 유효 주파수 범위를  $-0.5 \frac{L}{T_M} \leq F \leq 0.5\frac{L}{T_M}$로 다시 쓸 수 있다.

만약 심볼 당 샘플 $L$이 8이면, 유효 주파수 범위는 $ -\frac{4}{T_M} \leq F \leq \frac{4}{T_M} $이다. 심볼 당 샘플이 8인 직사각형 펄스 형태의 시간 축 신호를 주파수 축 스펙트럼으로 나타내면 아래 그림과 같다.
  
![Internal link preview tooltip](/images/content/pulse_shaping/pic2.png)  
  
스펙트럼에서 보면 알 수 있겠지만 직사각형 펄스 형태의 시간 축 신호는 아주 큰 문제가 있다. 피크 대비 사이드 로브의 크기 차이가 13dB밖에 차이가 나지 않는다는 점이다.

이러한 경우, 인접한 스펙트럼이 다른 사용자에게 할당되었을 경우 사이드로브의 큰 에너지 때문에 심한 간섭이 발생할 수 있다. 이러한 경우를 채널 간 간섭이라고 부른다.

직사각형 펄스 신호는 심볼 간 간섭은 없지만, 주파수 측 측면에서 채널 간 간섭을 유발할 수 있다는 문제가 있다.

두 번째 문제는 점유하고 있는 대역폭이 너무 넓다는 점이다. 주파수 역시 한정된 자원이기 때문에 내가 사용하는 신호의 주파수 대역폭이 좁을 수록 유리하다. 

위에 열거된 문제를 해결하기 위해 엔지니어들은 다양한 관점에서 개선을 시도했다.


### 3.6.2 Nyquist No-ISI 조건 (시간 축에서)

직사각형 펄스 형태의 단점을 안 이상, 채널 간 간섭을 줄이면서 대역폭을 줄일 수 있는 방법을 찾아야 한다. 먼저 대역폭을 줄이는 방식을 살펴보자.

그러나 가장 중요한 것은, 대역폭과 사이드 로브의 크기는 줄이지만, 심볼 간 간섭이 0인 조건은 유지해야한다. 그러기 위해 먼저 시간 축에서 심볼 간 간섭이 없는 조건을 알아야 한다.

이를 위해 시간 축에서 직사각형 펄스의 auto-correlation 신호를 살펴보자.

![Internal link preview tooltip](/images/content/pulse_shaping/pic3.png)  

빨간색 곡선은 직사각형 펄스의 자기상관 결과이고, 파란색 점선은 어떤 특정 신호의 자기상관 결과다. 

두 신호 모두 심볼 간격 $T_M$​에서 0의 값을 가지므로, 둘 다 ISI는 발생하지 않는다.

차이점은 빨간색 신호는 $-T_M \leq t \leq T_M$ 구간만 0이 아니고 다른 시간에서는 전부 0이다. 반면 파란색 신호는 심볼 간격 $T_M$에서만 0이고 나머지에서 0이 아니다.

이때 중요한 점은, 빨간색 곡선처럼 모든 구간이 0이어야만 ISI가 없는 것이 아니라, 심볼 간격에서만 0이 되면 ISI는 발생하지 않는다는 사실이다.

즉, 샘플링 시점인 심볼 간격에서만 ISI가 없으면, 나머지 시점에서는 값이 0이 아니어도 상관없다.

일반적으로 시간 축에서 좁은 신호(예: 직사각형 펄스)는 주파수 대역에서는 넓은 대역폭을 차지한다. 반대로 시간 축에서 길게 퍼진 신호는 주파수 영역에서는 좁은 대역폭을 가진다.

따라서, 시간 축에서 길게 퍼져 있지만 심볼 간격에서는 0을 유지하는 파란색 곡선처럼 신호를 설계하면 ISI 없이도 대역폭을 줄일 수 있다.

정리하면, 어떤 신호의 auto-correlation 결과가 심볼 간격 $T_M$ 에서, 해당 심볼을 제외한 나머지에서 모두 0이면, ISI가 발생하지 않는다.

여기서 한 가지 의문이 생긴다. 왜 auto-correlation 결과로 ISI 여부를 판단하는가?

그 이유는 수신기가 송신된 신호를 검출할 때 auto-correlation을 이용하기 때문이다. 특히 무선 통신에서는 송신 시점이 불확실하므로, 송신기는 앞부분에 알려진 심볼 시퀀스를 삽입하고, 수신기는 수신된 신호 전체에 대해 correlation을 수행한다.

이때, auto-correlation 결과가 최대가 되는 시점을 기준으로 송신 신호가 도착했다고 판단한다. 따라서 수신기를 설계할 때 auto-correlation은 필수적인 과정이다.

만약 auto-correlation 수행 중 ISI가 발생한다면, 심볼 간격 시점의 값이 망가져 정확한 심볼 추정이 불가능하다. 반대로 ISI가 없다면 수신기는 올바른 정보를 얻을 수 있다.

결론적으로, auto-correlation 결과가 심볼 간격에서 0이 되도록 설계하면 시간 영역에서 ISI 없는 신호를 만들 수 있다. 이것이 Nyquist No-ISI 조건의 핵심이다.

### 3.6.2 Nyquist No-ISI 조건 (주파수 축에서)

![Internal link preview tooltip](/images/content/pulse_shaping/pic4.png)  

위 그림에서 (a)는 시간 축에서 ISI가 없는 조건을 만족하는 첫 번째 심볼의 시간 축 파형이다. 빨간색 신호는 심볼 당 샘플이 $L$인 신호고 파란색 신호는 Down-Sampling을해 심볼 만 나타낸 신호다.

실제 우리가 송신하는 신호는 여러개의 심볼이 존재한다. 예를 들어 두 번째 심볼의 시간 축 파형은 $T_M$일 때 1, 나머지 심볼 간격에서는 0인 신호가 있을 것이다.

그리고 (a)에서의 신호와 합쳐져서 전송될 것이다.

이렇게 만들어진 송신 신호를 주파수 스펙트럼에서 보면 심볼 간격 $\frac{1}{T_M}$ 마다 반복되어 나타나게 된다.

이유를 간단히 살펴보면 원래 샘플레이트 $F_S$로 송신된 신호는 $F_S$간격으로 주파수 레플리카가 반복된다. 이 신호를 심볼 당 샘플 $L$로 down-sampling을 하면 샘플레이트 역시 $\frac{F_S}{L} = \frac{1}{T_M}$으로 줄어들게 된다. 따라서 down-sampling된 신호는 주파수 레플리카가 $\frac{1}{T_M}$마다 반복되게 된다.

![Internal link preview tooltip](/images/content/pulse_shaping/pic5.png)  

위 그림의 왼쪽 스펙트럼은 $\frac{1}{T_M}$간격마다 스펙트럼이 반복되고 스펙트럼의 합이 평탄하게 이루어져 있다. 이럴 경우 No-ISI 조건을 만족한다.

반면 오른쪽 스펙트럼은 $\frac{1}{T_M}$마다 스펙트럼이 반복되지만 그 합이 평탄하지 못하고 Hole이 존재한다. 이럴 경우 No-ISI 조건을 만족하지 못한다.

### 3.6.3 Coefficients of an Ideal Pulse Auto-correlation 

심볼 간 간섭이 없는 이상적인 송신 신호를 만들기 위해서 주파수 축에서 $-\frac{1}{2T_M} \leq F \leq \frac{1}{2T_M}$에서 평탄한 직사각형 형태를 가져야 함을 알았다.

주파수 축에서 직사각형 펄스는 시간 축에서 Sinc함수의 형태를 띈다. 즉 시간 축 신호에서 심볼을 Sinc함수 형태로 만든다면 ISI가 없는 이상적인 신호를 만들 수 있다.

아래 그램은 ISI가 없는 이상적인 송신 신호를 시간 축에서 나타냈다. 심볼 당 샘플은 4일 때를 가정한다.

![Internal link preview tooltip](/images/content/pulse_shaping/pic6.png)  

심볼 간격 $T_M$에서 0이고 Sinc함수의 형태를 갖는다. 그러나 이 신호는 실제로 구현될 수 없다. Sinc함수는 시간 축에서 무한한 길이를 갖기 때문이다.

실제 구현을 위해서는 Sinc 신호의 양 옆을 일정부분 잘라야 한다. 양 옆을 자르면 주파수 영역에서 완벽한 직사각형 형태를 띄지 못하고, 주파수 레플리카가 서로 겹치게 되는 문제가 발생한다.

또한 실제 시스템에서 송신기와 수신기는 독립적인 클럭을 바탕으로 동작하기 때문에 타이밍 오류가 발생하여 정확한 심볼 간격에서 값을 수신하지 못할 수 있다. 이럴 경우 ISI가 발생한다.

이러한 현실적인 문제를 해결하기 위해서 Raised Cosine 필터가 등장한다.

### 3.6.4 Raised Cosine Filter

3.6.2에서 주파수축에서 ISI가 없는 조건은 $-\frac{1}{2T_M} \leq F \leq \frac{1}{2T_M}$에서 평탄한 스펙트럼을 가져야 하는 것이다.

그러나 시간 축에서 무한히 긴 Sinc함수를 송신 신호로 사용할 수 없기 때문에, 양 옆을 잘라야하고 결국 주파수 스펙트럼상에서 완벽한 직사각형 모양은 약간 찌그러지게 된다.

그러나 모양이 찌그러지더라도, 이를 잘 활용해 주파수 스펙트럼을 평탄하게 만들 수 있다. 아래 그림을 살펴보자.

![Internal link preview tooltip](/images/content/pulse_shaping/pic7.png)  

파란색 스펙트럼은 약간 찌그러진 사각 스펙트럼이고, 점선 스펙트럼은 주파수 레플리카다. 이 때 인접한 레플리카가 넘어온 영역이 $\frac{1}{2T_M}$에 대해 홀수 대칭을 띈다면
그 합은 여전히 평탄할 것이다.

즉 레플리카가 신호 영역을 침범해도, 결과적으로 주파수 스펙트럼은 평탄한 모양을 띌 수 있게 된다.

여기서 핵심은 스펙트럼 영역에서 직사각형 형태의 펄스 정형 필터를 어떻게 잘 찌그러트려서 $\frac{1}{2T_M}$에 대해 홀수 대칭을 유지하면서, 시간 축에서 최대한 짧은 꼬리를 가질 수 있게 만들지 생각해봐야 한다.

방법은 생각보다 간단하다.시간 영역에서 Sinc 신호의 긴 꼬리는 주파수 영역에서 직사각형 펄스의 갑작스러운 변화 때문이므로, 주파수 영역에서 직사각형 펄스를 최대한 부드럽게 만들어 주면 된다.

우리가 가장 쉽게 생각할 수 있는 부드러운 신호는 사인파다. 그래서 주파수 영역의 직사각형 펄스에 주파수 영역의 사인파를 컨볼루션해준다면, 시간 축 영역에서 짧아진 꼬리를 갖는 Sinc 신호가 만들어지게 될 것이다. 그 과정은 아래에 나타낸다.

![Internal link preview tooltip](/images/content/pulse_shaping/pic8.png)  

위 그림에서 주파수 영역의 직사각형 펄스에 주파수 영역의 사인파를 컨볼루션하면 $\frac{1}{2T_M}$에 대해 홀수 대칭을 유지하면서 부드러워진다.

주파수 영역에서 이러한 형태의 스펙트럼을 갖는 펄스 정형 필터를 Raised Cosine 필터라고 말한다.

이 때 $\alpha$를 roll-off 인자라고 말한다. $\alpha = 0.25$면 최소 대역폭 대비 25%가 넓어졌다는 의미이다.

이 roll-off 인자는 대역폭과, 시간 축에서 신호의 감쇄정도에 영향을 준다. 먼저 대역폭에 대해 살펴보자.

![Internal link preview tooltip](/images/content/pulse_shaping/pic9.png)  

roll-off가 클수록 대역폭은 넓어지게 된다.

다음으로 시간 축 감쇄에 대해 살펴보자.

![Internal link preview tooltip](/images/content/pulse_shaping/pic10.png)  

roll-off가 클수록 감쇄가 빨라지게 된다.

결과적으로 roll-off가 클수록 대역폭은 커지지만 시간 축에서 감쇄는 빠르게 일어난다. 감쇄가 빠르면 송/수신기의 타이밍 클럭 오차에서 발생하는 심볼 간 간섭을 줄여 타이밍 오차에 강인하게 만들 수 있다.

반대로 roll-off가 작다면 대역폭은 작아지지만 시간 축에서 감쇄는 느리게 일어난다. 따라서 송/수신기의 타이밍 클럭 오차에서 발생하는 심볼 간 간섭이 커져 타이밍 오류에 민감하게 된다.

### 3.6.5 Squared Root Raised Cosine Filter

그럼 모뎀을 설계할 때 Rasied Cosine Pulse Shaping Filter는 어디에 배치해야 할 까? 송신기와 수신기 관점에서 생각해보자.

만약 수신기에 Pulse Shaping 필터를 배치한다면, 송신기에서 신호를 만들 때 사이드로브를 제어할 수 없다. 따라서 인접 채널에 영향을 주게 된다.

반대로 송신기에 배치하면 어떨까? 이럴 경우 수신기에서는 무선 환경에서 추가된 잡음이 신호와 함께 들어오게 되고, SNR이 나빠지는 경우에 대해 대처할 수 없게 된다.

따라서 이 필터를 송신기와 수신기에 나눠서 배치하게 된다. 이를 위해 Raised Cosine 필터의 계수를 Squared root해 송신기와 수신기에 각각 나눠 구현하게 된다.

송신기에 있는 필터를 SRRC Pulse Shaping Filter, 수신기에 있는 필터를 Matched Filter로 표현하기도 한다.

SRRC를 거쳐 나온 시간 축 송신 신호 파형은 아래와 같다.

![Internal link preview tooltip](/images/content/pulse_shaping/pic11.png)  

더 이상 심볼 간격 $T_M$에서 0이 아니다. 즉 ISI가 발생한다. 하지만 이는 당연하다. 수신기의 Matched Filter까지 거쳐야 심볼 간 간섭이 완벽히 제거되는 것이다.

### 3.6.6 SRRC 필터의 단점

송신기와 수신기에 Raised Cosine 필터를 나누어서 구현하면 많은 장점이 존재한다. 송신기에서 대역폭 컨트롤이 가능하고 수신기에서 효과적으로 잡음 제거가 가능하다.

그러나 분명히 단점도 존재한다. 사실 SRRC 필터는 이론상으로는 No-ISI 조건을 만족하는 필터지만, 실제 구현상으로는 그러지 않는다.

유한한 길이의 필터를 사용해야하기 때문에, SRRC 필터의 탭 계수 역시 유한개로 잘리게 된다. 그럴 경우 스펙트럼 상에서 더 이상 $\frac{1}{2T_M}$에 대해 홀수 대칭을 띄지 않게 된다.

아래 그림을 살펴보자.

![Internal link preview tooltip](/images/content/pulse_shaping/pic13.png) 

$\frac{1}{2T_M}$을 기준으로 약 3dB 위쪽으로 스펙트럼이 지나가게 된다. 이럴 경우 스펙트럼 레플리카가 더해지면 더 이상 평탄하지 않게 된다.

따라서 주파수 영역에서 No-ISI 조건을 만족할 수 없게 되어 약간의 심볼 간 간섭이 발생하게 된다.

### 3.6.6 Upgrade SRRC Filter

우리는 Pulse Shaping Filter의 스펙트럼이 직사각형 일 때 발생하는 문제를 해결하기 위해 부드러운 사인파를 주파수 영역에서 컨볼루션했다.

그 결과 시간 축에서 무한한 길이를 유한하게 바꿀 수 있었고, 동시에 심볼 간 간섭을 0으로 만드는 Pulse Shaping Filter를 만들 수 있었다.

![Internal link preview tooltip](/images/content/pulse_shaping/pic12.png)  

위 그림에서 알 수 있듯이, 시간 축에서 직사각형 Pulse Shaping 필터를 사용하는 것 대비, SRRC 필터를 사용하면 대역폭 및 사이드로브의 크기를 획기적으로 줄일 수 있다.

그러나 아직 사이드로브의 크기가 충분히 감쇄된건 아니다. 우리는 감쇄를 충분히 더 주기 위해 직사각형 스펙트럼에 사인파를 컨볼루션 하는데신 카이저 파형을 컨볼루션 할 수 있다.

![Internal link preview tooltip](/images/content/pulse_shaping/pic14.png)  

위 그림을 통해 RRC Pulse Shaping Filter 대비 더 많은 감쇄를 줄 수 있다. 그러나 주파수의 평탄한 영역이 줄어드므로 이에 따른 trade-off를 잘 고려해야 한다.