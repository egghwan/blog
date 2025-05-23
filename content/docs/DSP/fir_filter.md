---
title: "FIR Filter"
description: ""
icon: "code"
date: "2023-05-22T00:44:31+01:00"
lastmod: "2023-05-22T00:44:31+01:00"
draft: false
toc: true
weight: 210
katex: true
---

{{% alert context="warning" text="The front matter `description` value for this page has been intentionally left empty in order to demonstrate FlexSearch's suggested results fallback behaviour." /%}}

## 1. 문서 설명
신호처리 분야에서 매우 많이 쓰이는 Fir Filter를 신호처리 관점 및 RTL 구현 관점에서 기술한다.

## 2. 정의 

- FIR Filter : FIR은 Finite-Impulse-Response 의 약자이다. FIR 필터는 계수가 시간 축에서 유한한 필터이다.

## 3. 신호처리 관점

### 3.1 Convolution의 시간 축 분석

FIR Filter를 이해하려면 먼저 Convolution 연산에 대해 이해해야 한다. 먼저 시간 축에서 Convolution 식에 대해 알아보자.

사실 Convolution 식이 곧 Filter의 식과 동일하다.

{{< katex >}}
$$
\begin{aligned}
y[n] &= (x * h)[n] = \sum_{k=-\infty}^{\infty} x[n-k]\, h[k] \quad (단 \:\: k ≤ n)\\
\\
x &= \text{필터링의 대상이 되는 신호} \\
h &= \text{필터의 계수}
\end{aligned}
$$
{{< /katex >}}

FIR 필터는 정의는 필터의 계수가 유한한 필터라고 했다. 이 말은 $h$는 유한개의 유의미한 값이 있고, 나머지는 0이라는 소리다.

이해를 위해 $h[0] = 1 , \\: h[1] = 2, \\: h[2] = 3, \\: h[3] = 4$ 이고 나머지 인덱스의 값은 모두 0이라고 가정하자.

$h$가 0인 부분은 아무 의미가 없기 때문에 시그마의 범위를 아래 식과 같이 축소할 수 있다.

{{< katex >}}
$$
\begin{aligned}
y[n] &= (x * h)[n] = \sum_{k=0}^{3} x[n-k]\, h[k] \quad (단 \:\: k ≤ n)\\
\\
x &= \text{필터링의 대상이 되는 신호} \\
h &= \text{필터의 계수}
\end{aligned}
$$
{{< /katex >}}

이제 식을 전개해보자.

{{< katex >}}
$$
\begin{aligned}
y[0] &= x[0]h[0] \\
y[1] &= x[1]h[0] + x[0]h[1] \\
y[2] &= x[2]h[0] + x[1]h[1] + x[0]h[2] \\
y[3] &= x[3]h[0] + x[2]h[1] + x[1]h[2] + x[0]h[3]
\end{aligned}
$$
{{< /katex >}}

이게 Convolution의 연산을 하는 방법이다.

&nbsp;
### 3.2 Convolution의 시간 축, 주파수 축 관계

이제 Convolution연산을 주파수 축에서 살펴보자.

결론부터 말하면 시간 축에서 Convolution 연산은 주파수 축에서 곱셈과 동일하다. 증명은 생략한다.

아래 그림을 살펴보자.

![Internal link preview tooltip](/images/content/fir_filter/time_freq.png)  

위 1열의 그림은 주파수 축에서 신호를 나타냈고, 2열의 그림은 시간 축에서 신호를 나타냈다.

주파수 축에서  -5MHz ~ 5MHz 신호만 선택하기 위해 사각 파형의 계수를 갖는 필터와 곱했다.

주파수 축에서 곱하는 행위는 시간 축에서 Convolution과 동일하다.

주파수 축에서 사각 파형은 시간 축에서 무한한 길이의 Sinc 함수와 대응되므로 필터 계수 $h$가 무한개의 유의미한 값이 존재한다.

이럴 경우에는 이론상으로는 문제가 없지만, 구현상으로 아주 큰 문제가 발생한다. 왜냐하면 결과가 나오려면 무한대의 시간이 걸리기 때문이다.

3.1장에서 시그마의 위 아래를 무한대에서 유한한 값으로 바꿨다. 이것이 가능했던 이유는 계수 $h$를 유한개의 의미있는 값으로 가정했기 때문이다. 

만약 계수 $h$가 무한개의 의미있는 값이라면 $y[0]$을 구하기 위해 무한대의 덧셈을 수행해야 하므로 결과를 얻으려면 무한대의 시간이 필요하다.

&nbsp;
### 3.3 Convolution과 Fir Filter의 관계

3.2에서 우리는 무한한 길이의 Sinc함수가 구현상에서 큰 문제가 되었다. 엔지니어들은 이 문제를 단순하게 해결했다.

그것은 바로 무한한 길이의 Sinc함수를 유한한(Finite) 길이의 Sinc함수로 바꾸는 것이다. 이제 FIR Filter가 뭔지 알 수 있다.

FIR Filter란 이상적으로 무한개의 계수를 갖는 필터를 구현을 위해 유한개의 계수를 갖는 필터로 바꾼 것이다.

그러나 무한개의 필터 계수를 유한개의 필터 계수로 바꾸면 분명 단점도 존재한다. 그것은 바로 필터링의 성능 저하다.

무한 길이의 Sinc함수를 유한 길이의 Sinc함수로 바꾸려면 시간 축에서 단순히 Sinc함수의 양 옆을 잘라버리면 된다. 그러면 주파수 축에서 어떻게 될까?

![Internal link preview tooltip](/images/content/fir_filter/fir.png)  
&nbsp;
왼쪽은 Sinc함수, 오른쪽은 Sinc함수의 주파수 축 그림이다.

무한한 길이의 Sinc 계수를 양 옆을 잘라 유한한 길이의 Sinc 계수로 만들었더니 주파수 축에서는 사각파형 모양이, 살짝 찌그러져 보인다.

이 뜻은, 무한한 길이의 Sinc함수는 주파수 축에서 완벽한 사각 파형을 갖기 때문에 필터링을 거치면 주파수 축에서 내가 원하는 영역을 완벽하게 선택할 수 있다. 

반대로 유한한 길이의 Sinc함수는 찌그러진 사각 파형을 갖기 때문에 주파수 축에서 내가 원하는 영역을 완벽하게 선택할 수 없다.

모든 것에는 대가가 따르는 법이다.

## 4. 구현 관점

이제 Fir Filter를 RTL로 구현해보자. 단순 RTL 구현이 아니라 FPGA에 최적화된 RTL 구조를 알아보자.

&nbsp;

### 4.1 SRL (Shift-Register-Lookup Table)
Xilinx FPGA는 SRL(Shift-Register-Lookup table)이 존재한다. SRL이 뭘까? 아래 그림을 살펴보자.

![Internal link preview tooltip](/images/content/fir_filter/srl.png)  

SRL은 FPGA를 설계할 때 shift-register를 활용하여 지연 로직을 만들때 유용하다.

일반적으로 shift-register는 플립플롭(F/F)을 활용하여 만드는데, SRL을 활용하면 LUT만으로 shift-register 구현이 가능하다.

예를 들어 Xilix FPGA는 SRLC32E SRL로직이 있고, 이는 32clk의 딜레이를 갖는 Shift-Register다. 같은 기능을 구현하기 위해서 F/F 32개가 필요한데, F/F이 SRL 대비 로직면에서 크다. 따라서 SRL을 활용하면 면적 및 전력에서 이점을 갖는다.

Fir-Filter 구현을 위해서는 데이터의 지연 로직이 필수적인데, 이 지연 로직을 SRL을 활용해 구현하면 FPGA상에서 최적화할 수 있다.

### 4.2 DSP
Xilinx FPGA에서는 MAC(Multiply-Accumulate) 연산에 최적화된 DSP 로직이 존재한다. 구조는 아래와 같다.

&nbsp;

![Internal link preview tooltip](/images/content/fir_filter/dsp.png)  

먼저 Input하나를 지연 시킨뒤, 다음 데이터와 서로 덧셈 연산을 수행한다. 그 다음 덧셈 결과를 다른 데이터와 곱셈을 수행한다. 그 다음 곱셈결과를 누적하여 더한다.

위 구조는 FPGA에서 DSP 1개의 로직을 사용하여 구현된다. 그리고 매우 빠른 덧셈, 곱셈 연산을 지원하기 때문에 Timing 관점에서 이득을 볼 수 있다.

&nbsp;

### 4.3 Even Symmetric Fir Filter

Even-Symmetric Fir Filter는 필터의 계수가 짝수개이고, 계수가 좌우 대칭 형태를 이루는 Fir Filter다.

예를 들어 필터 계수가 3,2,1,1,2,3 이라면 필터 계수가 6개고, 좌우 대칭형태를 띈다. 이러한 경우를 Even-Symmetric하다 라고 표현한다. 이제 RTL 블록 다이어그램을 살펴보자.

아래 블록다이어그램은 필터의 계수의 길이가 4이고 Even-Symmetric한 Fir Filter의 블록 다이어그램 구조다.

![Internal link preview tooltip](/images/content/fir_filter/Even-Sym.png)

이해를 위해서 Clock 별로 데이터가 이동하는 것을 그려보자.


