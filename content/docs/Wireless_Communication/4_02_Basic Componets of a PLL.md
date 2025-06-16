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

PLL의 성능을 결정짓는 가장 중요한 파라미터를 2가지를 소개한다.

첫 번째는 Dampling factor $\zeta$ 다. 이게 뭔지 알아보자.

쉽게 설명하기 위해 테니스 공을 땅에 떨어뜨리는 상상을 해보자. 공은 바닥에 부딪혀 다시 튀어오르고 점차 감쇠되는 진동을 보이다 결국 평형을 이룬다.

PLL역시 처음 위상 획득 과정에서 초기에는 테니스공 처럼 진동하다가 점차 평형 상태로 수렴하게 된다.

이 때 Damping factor $\zeta$는 감쇠비를 의미한다. Damping factor가 크면 감쇠 진동은 줄어들지만 수렴 시간이 길어진다.

반대로 Damping factor가 작다면 수렴 시간이 빠르지만 감쇠 진동이 발생한다. 아래 그림을 통해 Damping factor에 따른 진동 정도를 살펴보자.

![Internal link preview tooltip](/images/content/PLL/pic12.png)

Damping factor가 1보다 작을 때 PLL응답은 과도한 상승(oversrhoot)과 과도한 하강(undershoot) 형태의 감쇠 진동을 보인다. 이러한 경우 underdamped 상태라고 한다.

Damping factor가 1보다 클 경우 PLL응답은 진동성 반응이 사라지게 된다. 이러한 경우 overdamped(과감쇠) 상태라고 한다.

Damping factor가 정확히 1일 경우 PLL응답은 underdamped와 overdamped 사이의 중간 상태 정도로 진동한다. 이러한 경우 critically damped(임계 감쇠) 상태라고 부른다.

두 번째는 Natural frequency $w_n$이다.

우리가 PLL을 사용하는 목적은 입력되는 파형의 위상과 주파수를 추적하기 위함이다. 통신 모뎀의 경우 수신 신호가 무선 채널 환경에 의해 왜곡됐을때 이 오차를 추적하기 위함이다.

그러나 이러한 입력 신호는 잡음에 오염되어 있기 때문에 정확한 수신 신호의 복구를 위해 잡음을 제거해야 한다. 그리고 이를 PLL이 수행한다.

따라서 PLL은 신호를 통과시키고 잡음은 제거시키는 필터와 비슷하게 동작한다. 아래 그림을 살펴보자.

![Internal link preview tooltip](/images/content/PLL/pic13.png)

위 그래프는 Proportional+Integrator 형태의 루프 필터를 갖는 PLL의 주파수 응답이다. 위 그림을 통해 PLL이 저역통과(LPF) 필터임을 알 수 있다.

잘 살펴보면 주파수 응답이 0에서 $w_n$까지는 거의 평탄한 응답을 보인다. 이 뜻은 PLL의 입력 신호의 위상 오차의 변화가 $w_n$이하일 경우, PLL은 오차를 잘 추적해 수렴할 수 있음을 의미한다.

그러나 위 그림에서 같은 $w_n$이라도 Damping factor에 따라 Passband의 영역이 달라진다. 따라서 우리는 더 나은 PLL의 Passband 대역정의가 필요하다.

이를 위해 등가 잡음 대역폭(Equivalent noise BW) $B_n$이라는 개념을 사용한다.

이 뜻은 주파수 응답 곡선의 아래 면적과 동일한 면적을 갖는 이상적인 벽돌 필터의 대역을 의미한다. 아래 그램을 참고해보자.

![Internal link preview tooltip](/images/content/PLL/pic14.png)

파란색 주파수 응답은 PLL의 주파수 응답이다. 이때 파란색 곡선 아래의 면적과 동일한 면적의 벽돌 필터가 보인다. 이 때 $B_n$은 벽돌 필터의 대역폭을 의미한다.

내용이 어려워 생략하겠지만, 등가 잡음 대역폭 $B_n$과 Natural Frequency $w_n$과 Damping Factor $\zeta$의 관계식을 아래와 같이 나타낼 수 있다.

$$B_n = \frac{\omega_n}{2} \left(1 + \frac{1}{4\zeta}\right)$$

등가 잡음 대역폭 $B_n$은 Loop Bandwidth라고도 불린다.

자 이제 PLL을 설계할 준비가 끝났다. PLL을 설계하기 위해서는 Damping Factor와 Loop Bandwidth를 먼저 고려해야 한다.

먼저 Damping Factor에 대해 적절한 값을 찾아보자.

앞서 말했듯이, Damping Factor가 크면 감쇠 진동이 작지만 수렴 시간이 길어지고, Damping Factor가 작으면 감쇠 진동이 크지만 수렴 시간이 짧아진다.

이러한 trade-off 관계에서 좋은 균형을 이루는 Damping Factor 값으로 0.707이 많이 사용된다.

그 다음은 Loop bandwidth에 대해 적절한 값을 찾아보자.

좁은 Loop bandwidth를 선택하면 대부분의 잡음을 효과적으로 걸러낼 수 있지만 빠른 위상 변화를 추적할 수는 없다.

반면 넓은 Loop bandwidth를 선택하면 빠른 위상 변화를 잘 추적할 수 있지만, 더 많은 잡음이 루프를 통해 들어올 수 있다.

대부분의 수신기에서는 입력 신호 SymbolRate의 약 1%정도인 값이 $B_n$의 좋은 시작점 값이다.

그 다음은 루프 상수 $K_0$, $K_D$, $K_p$, $K_i$를 결정해야 한다.

![Internal link preview tooltip](/images/content/PLL/pic15.png)

위 그림은 PLL 이득을 결정하는 순서를 나타낸 그림이다.

먼저 Phase Error Detector Gain $K_D$를 결정한다.

그 다음 PLL Input 신호가 갖는 SampleRate의 a%만큼을 루프 대역폭으로 설정한다.

마지막으로 루프 필터 Gain $K_P$와 $K_i$를 설정한다.

$K_P$와 $K_i$를 설정하기 위해 먼저 Normalized natural frequency $\theta_n$을 정의해보자.

$$ \theta_n = w_n \frac{T_S}{2}$$

위 식에 루프 대역폭 $B_n$의 식을 대입하면 아래와 같이 다시 쓸 수 있다.

$$ \theta_n = \frac{B_nT_S}{\zeta+\frac{1}{4\zeta}}$$

위 식을 바탕으로 $K_P$와 $K_i$의 식을 유도할 수 있다. 유도과정은 생략한다.

$$K_P = \frac{1}{K_DK_0}\frac{4\zeta\theta_n}{1+2\zeta\theta_n+\theta^2}$$

$$K_i = \frac{1}{K_DK_0}\frac{4\theta_n^2}{1+2\zeta\theta_n+\theta^2}$$

하지만 디지털 통신 시스템에서 PLL의 루프 대역폭은 일반적으로 샘플링 속도 $f_s$를 기준으로 정의된다. 그러나 나중의 동기화 알고리즘에서 사용되기 위해서는 심볼률 $f_M$이 더 적절한 파라미터다.

이 때 심볼 당 샘플수 $L$인 디지털 신호에 대해 PLL의 $K_P$와 $K_i$값은 아래와 같이 달라진다.

$$K_P = \frac{1}{K_DK_0}\frac{4\zeta\frac{\theta_n}{L}}{1+2\zeta\frac{\theta_n}{L}+(\frac{\theta}{L})^2}$$

$$K_i = \frac{1}{K_DK_0}\frac{4(\frac{\theta_n}{L})^2}{1+2\zeta\frac{\theta_n}{L}+(\frac{\theta}{L})^2}$$

수식만으로는 PLL을 완벽하게 이해하는 데 어려울 수 있어서 간단한 예제를 살펴보자.

![Internal link preview tooltip](/images/content/PLL/pic16.png)

PLL의 입력 신호 $r[n]$이 있다고 해보자. PLL의 최종 출력$s[n]$은 결국 $r[n]$과 같아지는 것이다.

$$r[n] = Acos(2 \pi \frac{1}{15}n + \theta[n])$$

그리고 $\theta_n$이 서서히 변한다고 가정해보자. 그렇다면 PLL은 입력 신호의 위상 오차를 계산하여 보정한다.

NCO의 출력은 I/Q 신호로 구성된 복소수 신호다. 만약 입력 신호가 복소수면 I/Q신호를 전부 사용하고, 실수 신호면 Q신호만 사용해 보정한다.

$$s_I[n] = cos(2 \pi \frac{k}{N}n + \hat{\theta}[n])$$
$$s_Q[n] = -sin(2 \pi \frac{k}{N}n + \hat{\theta}[n])$$

그 다음은 Phase Error Detector에서 일어나는 일을 살펴보자.

그림을 잘 살펴보면 Phase Error Detector에서 NCO의 출력의 Q신호가 PLL의 입력신호와 곱해짐을 알 수 있다.

그 이유는 위상 오차는 비선형 입력신호에 숨어 있기 때문에 Q신호를 곱함으로써 위상 오차를 계산할 수 있기 때문이다. 아래 식을 통해 자세히 살펴보자.

$$e_D[n] = -sin(2 \pi \frac{k}{N}n + \hat{\theta}[n]) Acos(2 \pi \frac{1}{15}n + \theta[n])$$

삼각함수 변환 공식에 의해 위 식의 우변은 아래와 같이 변형될 수 있다.

$$e_D[n] = \frac{A}{2}sin(\theta[n]-\hat{\theta}[n]) - \frac{A}{2}sin(2 \pi \frac{2k}{N}n+\theta[n]+\hat{\theta}[n])$$

여기서 $\frac{A}{2}sin(2 \pi \frac{2k}{N}n+\theta[n]+\hat{\theta}[n])$는 주파수가 2배인 항이다.

PLL은 루프 대역폭 $B_n$을 갖는 저역통과 필터로 동작하기 때문에 주파수가 2배인 항은 필터링 되어 사라지게 된다. 따라서 Phase Error Detector의 출력 $e_D[n]$은 아래와 같이 쓸 수 있다.

$$e_D[n] = \frac{A}{2}sin\theta_e[n]$$

따라서 위 PLL의 S-Curve는 Sin인 것을 알 수 있다. S-curve에 대한 그림을 아래처럼 나타낼 수 있다.

![Internal link preview tooltip](/images/content/PLL/pic17.png)

만약 위상 오차가 매우 작다면 $sin\theta_e[n] = \theta_e[n]$을 만족하므로

$$e_D[n] = \frac{A}{2}\theta_e[n]$$을 만족한다.

위 식에서 우리는 Phase Error Detector의 Gain을 구할 수 있다. 

$$K_D = \frac{A}{2}$$

위에서 Phase Error Detector의 Gain은 PLL 입력신호의 진폭 $A$에 의해 결정된다. 만약 입력 신호의 레벨이 변해 진폭이 바뀐다면 $K_D$값 역시 불안정해져

PLL에서 설계된 노이즈 대역폭과 Damping Factor에 맞게 동작하지 않을 수 있다.

따라서 수신기에서는 AGC를 활용해 입력 신호의 레벨을 일정하게 맞추어 안정적인 PLL 동작을 보장해야 한다.

예제의 간단화를 위해 입력 신호의 진폭 $A$는 항상 1로 고정되어 있다고 가정해보자.

그럼 Phase Error Detector는 0.5가 된다.

그 다음은 Damping Factor를 결정할 차례다. PLL의 수렴속도와 안정성의 trade-off관계에서 일반적으로 좋은 시작점은 0.707이다.

$$ \zeta = 0.707 $$

그 다음은 PLL의 노이즈(루프)대역폭 $B_n$을 결정할 차례다. 일반적으로 PLL 입력 신호 SampleRate의 5%가 좋은 시작점이다.

$$B_nTs = 0.05 $$

이제 PLL 루프 필터의 Gain $K_P$와 $K_i$를 결정해보자. 위에서 살펴보았던 식에 Damping Factor와 노이즈 대역폭 값을 대입하면 아래와 같다.

$$K_P = 0.2667 $$
$$K_i = 0.0178 $$

이렇게 설계된 PLL에서 각 단계별로 신호가 어떻게 바뀌는지 살펴보자.

먼저 Phase Error Detector의 출력을 살펴보자.

![Internal link preview tooltip](/images/content/PLL/pic18.png)

그림에서 알 수 있듯이 Phase Error Detector의 출력 $e_D[n]$는 파란색 신호에 해당한다. 그리고 빨간색 신호는 위상 오차 $\theta_e[n]$을 나타낸다.

시간이 지날수록 위상 오차 $\theta_e[n]$이 0이 되어 출력 위상이 안정화 되는 것을 볼 수 있다.

Phase Error Detector의 출력 신호 $e_D[n]$은 루프 필터의 입력 신호로 들어간다. 루프필터를 거치고 나온 신호는 아래와 같이 표현된다.

![Internal link preview tooltip](/images/content/PLL/pic19.png)

그림에서 알 수 있듯이 신호의 피크 투 피크 값이 1에서 0.3으로 감소했음을 알 수 있다.

이 뜻은 PLL이 저역통과 필터의 특성을 띠기 때문에 고주파 성분이 감쇠됐기 때문이다.

루프 필터를 거치고 나온 신호의 위상 추적 결과를 살펴보면 아래와 같다.

![Internal link preview tooltip](/images/content/PLL/pi20.png)

초기 위상 오차 $\pi$를 잘 추적했음을 알 수 있다. 그러나 $\pi$를 기준으로 조금씩 진동하고 있다. 이 이유는 Phase Error Detector에서 나온 이중 주파수 성분에 의한 떨림이다.

마지막으로 최종 PLL의 출력 신호에 대해 알아보자.

NCO의 Q신호는 위상 오차를 계산하기 위해 Phase Error Detector로 보내졌다. 반면 NCO의 I신호는 PLL의 최종 출력이 된다.

아래 그림을 통해 PLL의 출력 신호가 점차 입력 신호와 같아짐을 확인할 수 있다.

![Internal link preview tooltip](/images/content/PLL/pic21.png)

아래 그림은 PLL의 입력신호가 복소 신호일 때의 구조이다. PLL 입력 신호가 실수 신호일 때와 구조가 거의 비슷하지만 Phase Error Detector에서 약간의 차이를 보인다.

![Internal link preview tooltip](/images/content/PLL/pic24.png)

### 4.7 Complex PLL Matlab 구현
이제 MATLAB으로 PLL을 구현해보자.

Phase Noise가 있는 Complex 신호를 PLL의 입력신호로 넣고 PLL이 어떻게 위상을 따라가는지 살펴보자.

먼저 MATLAB 코드는 아래와 같다.

```verilog
close all; clear all;

%% PLL Simulation parameter
debug           = 1;
pll_iteration   = 2e4;
pn_var          = 1e-9; % Phase noise variance
Kd              = 0.5;
BnTs            = 0.05;
K0              = 1;
zeta            = 1/sqrt(2);     % Damping factor
theta           = BnTs/(zeta + 1/(4*zeta));
Kp              = 1/(Kd*K0) * (4*zeta*theta^2)/(1+2*zeta*theta+theta^2);
Ki              = 1/(Kd*K0) * (4*theta^2)/(1+2*zeta*theta+theta^2);

%% Generate Input Complex Signal
fs              = 1e6;
f0              = 1e3;
y_ppm           = 50;
y               = y_ppm * 1e-6;
foffset         = y * f0;

phase_noise = sqrt(pn_var) * randn(pll_iteration,1);
delta_phi_in = 2 * pi * (f0 + foffset)/fs;
phase = (0:pll_iteration-1).'* delta_phi_in + phase_noise;
pll_in = exp(1j * phase);

%% PLL Ioop Initialization
pd_comp      = zeros(pll_iteration, 1);
pd_err       = zeros(pll_iteration, 1);
lf_kp_out    = zeros(pll_iteration, 1);
lf_ki_out    = zeros(pll_iteration, 1);
lf_out       = zeros(pll_iteration, 1);
dds_out      = zeros(pll_iteration, 1);
pd_in        = zeros(pll_iteration, 1);
pd_conjugate = zeros(pll_iteration, 1);
pll_out      = zeros(pll_iteration, 1);

lf_ki_init = 0;
dds_out_init = pi;

for i = 1 : pll_iteration
    %% Phase Error Detector
    if(i == 1)
        pd_in(i) = exp(1j*dds_out_init);
    else
        pd_in(i) = exp(1j*dds_out(i-1));
    end
    
    % Conjugate
    pd_conjugate(i) = conj(pd_in(i));
    
    % Phase Compensate
    pd_comp(i) = pll_in(i) * pd_conjugate(i);
    
    % Phase Detector Error
    pd_err(i) = angle(pd_comp(i));
    
    %% Loop Filter
    % Proportional Controller
    lf_kp_out(i) = Kp * pd_err(i);
    
    % Integrator Controller
    if(i == 1)
        lf_ki_out(i) = Ki * pd_err(i) + lf_ki_init;
    else
        lf_ki_out(i) = Ki * pd_err(i) + lf_ki_out(i-1);
    end
    
    % Loop Filter Out
    lf_out(i) = lf_kp_out(i) + lf_ki_out(i);
    
    %% DDS
    f_target = 2*pi*f0/fs;
    
    if(i == 1)
        dds_out(i) = lf_out(i) + f_target + dds_out_init;
    else
        dds_out(i) = lf_out(i) + f_target + dds_out(i-1);
    end
    pll_out(i) = exp(1j*dds_out(i));
end

```

코드를 천천히 분석해보자.

### 4.7.1 ppm오차와 위상 잡음이 있는 PLL 입력신호

먼저 위상 잡음이 껴있는 신호를 만드는 방법에 대해 알아보자.

그러기 위해서는 ppm(parts-per-million)에 대해 알아야 한다.

1ppm은 기준 주파수 대비 1/1e6(백만) 이내의 오차가 있다는 뜻이다.

예를 들어 PLL에 100MHz의 기준 주파수를 갖고 50ppm의 오차를 갖는 입력 신호를 넣는다고 가정해보면

$$100MHz \times \frac{50}{1000000} = 5000Hz$$

따라서 입력 신호는 100~100.005MHz의 이내에서 주파수가 흔들리는 신호임을 알 수 있다.

MATLAB 코드 20Line에서 foffset = y_ppm * 1e-6 * fo로 구하는식이 위에서 언급한 식과 동일하다.

따라서 코드에서 foffset은 기준 주파수가 갖는 오차를 의미하기 때문에 delta_phi_in 부분에서 주파수 부분에 f0+foffset을 통해 ppm오차를 반영할 수 있다.

그리고 이산 시간 정현파 신호는 $exp(1j2 \pi f_c/f_s)$로 표헌 가능하고 $2 \pi f_c/fs$는 정현파의 위상을 나타낸다.

따라서 MATLAB 23Line처럼 ppm을 반영한 PLL 입력 신호의 위상을 나타낼 수 있다.

이제 위상 잡음을 추가할 차례다. 22 Line에서 위상 랜덤 잡음을 추가하여 delta_phi_in과 더해주면 24 Line에서 ppm오차와 랜덤 위상 잡음이 포함된 최종 PLL입력신호의 위상을 표현할 수 있다.

이제 정현파 신호의 표현식 $exp(1j*위상)$식을 활용해 25 Line처럼 표현하여 PLL 입력신호를 나타낼 수 있다.

### 4.7.2 Digital PLL

이해를 위해 코드에서 나타낸 부분을 그림에 같이 표현했다. 아래 그림을 참고해보자.

![Internal link preview tooltip](/images/content/PLL/pic25.png)

그림에서 매핑된 변수와 코드부분을 따라가보면 블록다이어그램이 어떻게 코드로 표현됐는지 확인할 수 있다.

### 4.7.3 결과

![Internal link preview tooltip](/images/content/PLL/pic26.png)

위 그림은 PLL의 결과다. 빨간색 신호는 PLL의 출력신호다. 파란색 신호는 위상 잡음과 ppm이 포함된 입력 신호다.

시간이 지나면서 PLL의 출력신호인 빨간색 신호가 PLL의 입력신호인 파란색 신호를 잘 따라가는 것을 확인할 수 있다.