---
weight: 1135
title: "4.2 Basic Components of a PLL"
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


## 4.2 PLL이란

PLL(Phase-Locked-Loop)는 말 그대로 위상을 고정하는 장치임을 의미한다.

이게 통신 모뎀에서 왜 필요할까? 그것은 바로 무선 통신 환경에서 손상되는 송신 신호를 복구하여 수신 하기 위함이다.

무선 통신 환경에서는 송신기와 수신기의 클럭이 독립적으로 동작한다. 만약 200MHz의 송신기 클럭과 200MHz의 수신기 클럭이 있다면 이 2개의 클럭이 과연 같을까?

정답은 아니다. 우선 첫번째로 클럭의 시작 위상이 다를 수 있다.

![Internal link preview tooltip](/images/content/PLL/pic1.png) 

$V_1(t)$가 송신기 클럭이고 $V_2(t)$가 수신기 클럭이라고 하자.

만약 데이터가 지연 시간 없이 전달된다고 가정한다면 시작 위상이 다르기 때문에 데이터를 수신하는 순간이 달라지게 된다. 따라서 데이터 시작 지점이 달라져 수신 불가능해진다.

물론 지연 시간 없이 데이터가 전달 될 수도 없다. 언제 데이터가 수신기로 전달될지 모른다는 건 결국 클럭의 위상이 다르다는 것과 같다.

또 다른 이유는 송신기의 200MHz와 수신기의 200MHz가 완벽히 동일한 200MHz가 아니다. 

세상에서 가장 정밀한 크리스탈로 만든 클럭도 0.000001Hz 정도의 오차가 존재한다.

이러한 오차가 누적되면 데이터가 잘 수신되다가도 갑자기 끊어질 수 있다.

이처럼 송신기와 수신기 사이에는 클럭의 오차 또는 무선 환경에 의한 노이즈 등 여러 이유 때문에 송신 신호와 수신 신호간 오차가 발생한다.

이 오차를 줄이기 위해 필요한 것이 PLL이다. 오차를 입력으로 받아서 계속 Loop를 돌리면 최종적으로 수렴되는 오차가 존재한다. 이 최종 오차를 계산해 결정(=고정)하는 것이 PLL의 역할이다.

그리고 최종 결정된 오차를 수신 신호에 보정해주면 우리는 오차를 극복하여 신호를 수신할 수 있다.

### 4.2.1 PLL 기본 구조 (Input, Output)

![Internal link preview tooltip](/images/content/PLL/pic2.png) 

위 그림은 PLL의 기본 구조다. 천천히 단게별로 어떤 기능을 하는지 살펴보자.

먼저 입력 신호(input)을 Cos 신호로 가정해보자.

$$Input = Acos(2 \pi \frac{k}{N}n+\theta[n])$$

그리고 PLL의 초기 출력 신호 (output)을 아래와 같이 가정해보자.

$$Input = Acos(2 \pi \frac{k}{N}n+\hat{\theta}[n])$$

입력 신호와 출력 신호의 차이는 위상 $\theta[n]$에 존재한다. 즉 입력 신호와 출력 신호의 위상 오차 $\theta_e[n]$을 아래와 같이 정의할 수 있다.

$$\theta_e[n] = \theta[n] - \hat{\theta}[n]$$

PLL은 위상 오차 $\hat{\theta}[n]$을 입력으로 계속 받아서 최종적으로 수렴되는 오차를 구한뒤, 그 오차만큼을 출력 신호에 보정해주면 PLL은 입력 신호와 비슷한 출력 신호를 만들 수 있게 된다.

### 4.2.2 PLL 기본 구조 (Phase Error Detector)

PLL로 입력되는 신호와 PLL의 출력 신호와의 오차를 비교하는 블록이다.

PLL의 Input 신호와 PLL의 Output신호를 서로 비교하여 위상 오차 $\theta_D[n]$을 계속 만들어낸다.

### 4.2.3 PLL 기본 구조 (Loop Filter)

Phase Error Detector에서 탐지된 오차 $\theta_D[n]$은 Loop Filter로 들어가게 된다.

루프 필터는 "얼마나 큰 오차를" 또는 "얼마나 빨리 오차를" 수렴시킬지 결정할 수 있는 블록이다.

루프필터를 거쳐 나온 위상 오차를 $\theta_F[n]$으로 정의한다.

시간이 지나면 $\theta_F[n]$은 결국 특정 값으로 서서히 수렴되게 될 것이다.

### 4.2.3 PLL 기본 구조 (NCO)

루프 필터를 거쳐 서서히 특정 값으로 수렴되는 오차 $\theta_F[n]$을 입력으로 받아 주파수를 생성하는 오실레이터 모듈이다.

위상 오차가 최종 수렴되면 NCO에서 나오는 Cos 신호는 Input 신호와 동일하게 바뀔 것이다.

이럴 때 PLL은 잠금(Lock)되었다고 표현한다.

### 4.3 Phase Error Detector
Phase Error Detector에서는 PLL Input신호와 PLL Output신호의 위상 오차를 비교하는 블록이다.

동작 매커니즘을 자세히 살펴보자.

쉽게 생각하면 위상 오차를 비교하기 위해서 Input신호의 위상 $\theta[n]$과 Output신호의 위상 $\hat{\theta}[n]$을 뺀 값이 위상 오차 $\theta_D[n]$이라고 생각하기 쉽다.

하지만 그렇게 간단하지 않다. 그 이유는 Input 신호가 비선형 신호일 때도 동작해야하기 때문이다.

현재 가정을 들고 있는 Cos신호의 경우 위상 $\theta[n]$이 선형적으로 변하더라도 Cos신호는 비선형적으로 변한다. PLL은 비선형 신호 안에 숨어 있는 선형으로 변하는 위상을 찾아내야한다.

따라서 단순히 Input 신호의 위상과 Output 신호의 위상을 뺀 선형 오차를 계산한다면 오차를 정밀하게 추적할 수 없다.

그래서 특정 비선형함수를 $f$를 거쳐 위상 오차를 추적한다.

$$e_D[n] = f(\theta[n]-\hat{\theta[n]}) $$ 

그런데 우리는 구현을 하는 입장에서 이러한 비선형 함수를 다루기 까다로우므로 $f$를 선형 근사 시켜버린다.

사실 이렇게 해도 큰 문제가 없는 이유는 PLL이 수렴해가는 과정에서 위상 오차 $e_D[n]$은 매우 작은 값이 될 것이고 결국 0이 된다.

즉 비선형 곡선을 아주 짧게 보면 직선 처럼 보이듯이 선형 근사를 시켜도 크게 문제가 없다는 것이다. 아래 그림을 보면서 이해해보자.

![Internal link preview tooltip](/images/content/PLL/pic4.png) 

여기서 추가로 주목할 점은 위상 오차 $e_D[n]$이 0으로 수렴하기 위해 비선형 함수 $f$가 어떤 모양이어야 하는지 알아야 한다.

이에 대한 답을 찾기 위해서 먼저 Phase Error Detector에서 탐지된 초기 오차 $\theta_e[n]$이 양수라고 가정해보자. 그럼 아래와 같은 관계 식이 성립한다.

![Internal link preview tooltip](/images/content/PLL/pic5.png) 

식을 설명하면 $\theta[n]-\hat{\theta}[n]$이 0보다 크므로 $\hat{\theta}[n]$이 커져야 한다.

그러기 위해서는 $e_F[n]$, $e_D[n]$, $f(\theta_e[n])$이 차례대로 커져야 한다.

만약 초기 오차 $\theta_e[n]$이 음수라면 반대로 $e_F[n]$, $e_D[n]$, $f(\theta_e[n])$이 차례대로 작아져야 한다. 이러한 관계를 만족하는 비선형 함수 $f$는 아래와 같다.

![Internal link preview tooltip](/images/content/PLL/pic6.png) 

위 그림을 잘 살펴보면 $\theta_e[n]$이 양수일 때 $\theta_D[n]$은 0의 위쪽 방향에서 감소하는 방향으로 움직인다.

반대로  $\theta_e[n]$이 음수일 때 $\theta_D[n]$은 0의 아래쪽 방향에서 증가하는 방향으로 움직인다.

이러한 관계는 알파벳 S와 비슷하기 때문에 PLL의 S-Curve라고 부른다.

정리하면 Phase Error Detector의 비선형 함수 $f$는 S-Curve형태를 띄어야 위상 오차를 정밀하게 추적할 수 있는 것이다.

주목할 점은 $\theta_D[n]$을 0으로 만들려고 하는 강도(세기)가 $\theta_e[n]$에 따라 일정하지 않다는 점이다. 위 그림의 빨간색 화살표의 기울기가 $\theta_D[n]$을 조정하는 세기가 된다.

그리고 원점 부근에서 양의 기울기를 가져야한다는 점이다. 양의 기울기를 가질 때 위상 오차는 원점으로 수렴할 수 있게 된다.

앞서 언급한대로 상대적으로 작은 위상 오차 $\theta_e[n]$인 경우 S-curve는 기울기가 $K_D$인 직선으로 선형 근사 가능하다.

$$ f(\theta_e[n]) = K_D \theta_e $$

이것을 하드웨어로 구현하게 되면 단순 곱셈기로 구현할 수 있게 된다.

선형 근사화된 Phase Error Detector의 모듈을 아래와 같이 다시 그릴 수 있다.

![Internal link preview tooltip](/images/content/PLL/pic7.png)

### 4.4 Loop Filter
Loop Filter에서는 Phase Error Detector에서 생성된 $\theta_D[n]$을 입력으로 받아 최종 위상 오차로 수렴시키는 블록이다.

루프 필터의 주 목표는 NCO에 최종 오차로 수렴되고 있는 위상 오차인 $\theta_F[n]$을 제공하여 최종 위상 오차를 0으로 수렴시킨다.

루프 필터의 다른 목표는 위상 오차내에 포함되어 있는 노이즈 및 고주파 성분을 제거하는 것이다. 위상 오차 내의 노이즈를 제거하여 정밀한 오차 추적을 가능하게 만든다.

위상 오차내에 포함되어 있는 노이즈 성분을 줄이기 위해 루프 필터는 Proportional + Integrator (PI) 루프 필터 형태를 갖는다.

Proportional(비례) 필터는 현재의 에러성분을 바탕으로 Gain을 조절하는 부분이다. 만약 Phase Error Detector에서 출력된 위상 오차 $\theta_D[n]$이 크다면, Proportional Gain을 크게 설정해서 루프 필터가 추정한 위상 오차 값을 더 빨리 키워 수렴 속도를 빠르게 하는 것이다.

좀 더 쉽게 설명하자면 오차가 30이라면 10씩 3번 루프 필터를 돌면서 보정하는 것보다, 한 번에 30을 보정하는게 더 빨리 수렴하게 되는 것이다. 이 때의 Proportional Gain을 $K_P$로 정의한다.

그리고 Proportional 필터의 출력을 아래와 같이 정의한다.

$$e_{F,1}[n] = K_Pe_D[n]$$

다음은 Integrator(적분) 필터는 미세한 오차를 보정하기 위해 존재한다.

이전 루프에서 출력했던 위상 오차와 현재 루프에서 출력하는 위상 오차를 누적하면 미세한 오차가 보다 더 커질 것이고, 이 오차를 Integrator Gain $K_i$로 증폭시켜준다.

즉 미세한 오차를 증폭시켜 잔여 위상 오차를 줄일 수 있게 된다. Integrator 필터의 출력을 아래와 같이 정의한다.

$$e_{F,2}[n] = e_{F,2}[n-1] + K_ie_D[n]$$

그리고 루프 필터의 최종 위상 오차 출력은 Proportional과 Integrator를 더한 위상 오차 값이다.

$$e_F[n] = e_{F,1}[n] + e_{F,2}[n] $$

아래 그림은 PLL의 루프 필터를 자세히 그린 PLL 전체 구조다.

![Internal link preview tooltip](/images/content/PLL/pic8.png)

### 4.5 NCO (Numberically Controlled Oscillator)

NCO는 직역하면 수치 제어 발진기다. 즉 발진기에 입력되는 숫자 값을 기반으로 동작한다.

루프 필터에서 나온 수렴되고 있는 위상 오차를 입력으로 받으면 NCO에서 출력되는 발진 주파수는 서서히 Input 신호의 위상을 갖도록 바뀌게 되는 것이다.

NCO는 크게 2개의 부분으로 구성된다. 아래 그림을 참고하자.

![Internal link preview tooltip](/images/content/PLL/pic9.png)

이 그림은 NCO의 내부 구조이다. 크게 Phase Accumulator랑 LUT가 보인다.

먼저 Phase Accumulator는 Loop Filter의 출력 위상 오차 $e_{F}[n]$을 바탕으로 PLL의 추정 위상인 $\hat{\theta}[n]$을 조정하는 부분이다.

식 부터 살펴보자.
$$
\hat{\theta}[n] = K_o \sum_{i=-\infty}^{n-1} e_F[i] \quad \quad mod \\ 2 \pi
\$$

수식을 보면 루프 필터에서 출력한 위상 오차를 계속 누적하고 있음을 알 수 있다. 오차를 계속해서 더해서 최종 위상 오차를 출력해 내는 것이다.

이 때 $K_0$는 루프 필터가 출력한 위상 오차에 대해 얼마나 민감하게 반응할지를 결정한다. $K_0$가 크다면 보다 루프 필터가 출력한 위상 오차에 대해 민감하게 반응할 것이다.

이럴 경우 수렴 속도는 빨라질 수 있지만 오차의 변동이 크다면 수렴 자체가 불가능할 수 있다.

주목할 점은 $mod \ 2 \pi$다. 왜 $mod \ 2 \pi$로 나눗셈 연산을 진행하냐면 누적 위상의 범위가 $0 \le \hat{\theta}[n] \le 2 \pi $면 충분하기 때문이다. 사인파든 코사인파든 위상이 360도 돌면 같은 위치기 떄문이다.

다음은 LUT다. Phase Accumulator에서 출력된 위상 오차 $\hat{\theta}[n]$을 LUT의 입력으로 넣어주면 그 위상을 갖는 Cos과 Sin가 출력된다. 식은 아래와 같다.
$$
\\
s_I[n] = \cos \hat{\theta}[n]
\\
$$
$$
\\
s_Q[n] = \sin \hat{\theta}[n]
\$$

### 4.5.1 최종 PLL 구조

Phase Error Detector, Loop Filter, NCO를 자세히 그려서 최종 PLL 블록 다이어그램을 그리면 아래와 같다.

![Internal link preview tooltip](/images/content/PLL/pic11.png)

이러한 PLL구조는 추후 모뎀의 수신 동기화 알고리즘에 많이 활용된다. 

### 4.6 PLL 디자인

PLL을 구현하기 위해서 가장 먼저 결정해야 할 것은 루프 필터다. 루프 필터의 PI필터가 곧 PLL의 수렴 성능 및 속도를 결정하기 때문이다.

