---
weight: 1135
title: "V.01 Polyphase Filterbank Implementation"
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


## 10.1.1 Polyphase Filterbank 란?

3.06절에서 Pulse Shaping을 수행하기 위해서 심볼을 $L$만큼 Up-Sampling을 수행한다.

SymbolRate를 $T_M$이라고 하면 SampleRate를 아래와 같이 정의할 수 있다.

$$T_{S,1} = \frac{T_M}{L}$$

이러한 구조엥서 우리는 Polyphase Filterbank 구조를 활용해 효율적인 송신기 구조를 만들 수 있다.

심볼 당 샘플 $L=4$이고 Pulse Shaping Filter를 $p(nT_{s,1})$로 표현해보자.

심볼 당 샘플이 $L$을 만족하기 위해서 심볼 사이에 0을 4개씩 추가하여 Up-Sampling을 수행한다. 따라서 실제로 심볼과 Pulse Shaping의 계수가 컨볼루션되는 순간은 4번째마다 일어난다. 왜냐하면 0은 컨볼루션 결과에 아무 의미가 없기 때문이다.

그러면 Pulse Shaping Filter의 계수를 아래와 같이 표현할 수 있다.

![Internal link preview tooltip](/images/content/polyphase/pic1.png)

첫 번째 세로줄에는 Pulse Shaping Filter의 처음 4개의 계수를, 두 번째 세로줄에는 그 다음 4개의 계수를 차례대로 배치했다.

따라서 $p0(mT_M)$은 첫 번째 심볼 스트림이고 $p1(mT_M)$은 두 번째 심볼 스트림인데, 첫 번째 심볼 스트림이 0인 순간에 두 번째 심볼 스트림의 컨볼루션을 처리하면 4개의 심볼 스트림을 동시에 처리할 수 있게 된다.

