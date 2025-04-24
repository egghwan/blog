---
title: "lib_sync_fifo.v"
description: ""
icon: "code"
date: "2023-05-22T00:44:31+01:00"
lastmod: "2023-05-22T00:44:31+01:00"
draft: false
toc: true
weight: 210
---

{{% alert context="warning" text="The front matter `description` value for this page has been intentionally left empty in order to demonstrate FlexSearch's suggested results fallback behaviour." /%}}

## 모듈 설명  
Synchronous FIFO에 대한 개념을 설명하고 RTL로 구현하는 과정을 기술한다.

## 1. Synchronous FIFO 란?
FIFO(First-In-First-Out)의 줄임말이다. 말 그대로 먼저 들어온 데이터가 먼저 나간다는 뜻이다.

FIFO는 기본적으로 읽기 포인터와 쓰기 포인터로 동작한다. 아래 예제를 통해 FIFO의 동작원리를 알아보자.

## 2. Synchronous FIFO 예제

DEPTH가 8인 FIFO를 예제로 설명을 진행한다. DEPTH란 FIFO에 저장될 수 있는 데이터 개수를 의미한다. 

Verilog 특성상 FIFO는 데이터를 저장하는 F/F로 구현된다. F/F은 다음 클럭에서 값이 업데이트 된다는 것을 주목하면서 아래 예제를 따라가자.

&nbsp;

![Internal link preview tooltip](/images/content/sync_fifo/ex1.png)  

- 현재 wr_ptr의 index가 0이므로 FIFO의 0번 index에 x[0] 데이터가 저장되는 중이다.

- fifo index 0번에 데이터가 저장되고 있으므로 wr_ptr의 index를 1 증가 시켜 다음 데이터를 받을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex2.png) 

- 다음 클럭이 되면 FIFO index 0에 x[0] 데이터가 최종 저장된다.

- 다음 클럭이 되면 wr_ptr이 최종 1 증가되었다.

- 동시에 현재 wr_ptr의 index가 1이므로 FIFO의 1번 index에 x[1] 데이터를 저장하는 중이다.

- FIFO index 1번에 데이터가 저장되고 있으므로 wr_ptr의 index를 1 증가시켜 다음 데이터를 받을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex3.png)

- 다음 클럭이 되면 FIFO index 1에 x[1] 데이터가 최종 저장된다.

- 다음 클럭이 되면 wr_ptr이 최종 1 증가되었다.

- 동시에 현재 wr_ptr의 index가 2이므로 FIFO의 2번 index에 x[2] 데이터를 저장하는 중이다.

- FIFO index 1번에 데이터가 저장되고 있으므로 wr_ptr의 index를 1 증가시켜 다음 데이터를 받을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex4.png)

- 데이터를 계속 저장하여 CLK6이 되었다. 다음 클럭이 되어 FIFO의 6번 index에 x[6]이 FIFO에 최종 저장되었다.

- 동시에 현재 wr_ptr의 index가 7이므로 FIFO의 7번 index에 x[7] 데이터를 저장하는 중이다.

- FIFO index 7번에 데이터가 저장되고 있으므로 wr_ptr의 index를 1 증가시켜 다음 데이터를 받을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex5.png)

- 다음 클럭이 되면 FIFO index 7에 x[7] 데이터가 최종 저장된다.

- 다음 클럭이 되면 wr_ptr이 최종 1 증가되었다.

- 현재 wr_ptr의 index는 8이다. 그리고 rd_ptr의 index는 0이다. 8(1000)과 0(0000)은 MSB가 다르고 MSB를 제외한 나머지 하위 비트가 같다. 이러한 경우 FIFO가 Full 상태임을 확인할 수 있다.

- FIFO가 Full 상태이므로 더 이상 데이터를 받을 수 없다.

![Internal link preview tooltip](/images/content/sync_fifo/ex6.png)

- 이제 데이터를 읽어보자.

- rd_ptr의 index는 0이다. 따라서 FIFO index 0에서 데이터를 읽는 중이다.

- FIFO index 0에서 데이터를 읽고 있으므로 rd_ptr index를 1 증가 시켜 다음 데이터를 읽을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex7.png)

- x[0] 데이터가 최종 read 되었다. 다만 FIFO에서 데이터를 읽는다고 해도 FIFO안에 저장된 데이터가 사라지지는 않는다. 그러나 x[0] 데이터가 덮어 써져도 문제 없는 상태다.

- 다음 클럭이 되면 rd_ptr이 최종 1 증가한다. 현재 wr_ptr의 index는 8(1000)이고 rd_ptr의 index는 1(0001)이다. MSB는 다르지만, MSB를 제외한 나머지 비트가 모두 다르지 않기 때문에, 더 이상 full 상태가 아니다.

- 다음 데이터를 읽기 위해 rd_ptr을 1 증가 시킨다.

![Internal link preview tooltip](/images/content/sync_fifo/ex8.png)

- x[1] 데이터가 최종 read 되었다.

- 다음 클럭에서 rd_ptr이 최종 1 증가 되었다.

- 현재 rd_ptr의 index는 2이므로 FIFO index 2번에서 데이터를 읽는 중이다.

- rd_ptr을 1 증가 시켜 다음 데이터를 읽을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex9.png)

- x[6] 데이터가 최종 read 되었다.

- 다음 클럭에서 rd_ptr이 최종 1 증가 되었다.

- 현재 rd_ptr의 index는 7이므로 FIFO index 7번에서 데이터를 읽는 중이다.


![Internal link preview tooltip](/images/content/sync_fifo/ex10.png)

- x[7] 데이터가 최종 read 되었다.

- 다음 클럭에서 rd_ptr이 최종 1 증가 되었다.

- 현재 rd_ptr의 index는 8이다. 그리고 rd_ptr과 wr_ptr의 index가 서로 같다. 이 경우 FIFO는 empty 상태에 있다.

- 다음 데이터를 쓰기 위해 wr_ptr의 데이터를 1 증가 시킨다.

- x[8] 데이터를 FIFO에 쓰는 중이다. 현재 wr_ptr의 index는 8(1000)인데 사실 wr_ptr의 하위 3비트를 보고 FIFO index를 결정한다. MSB 비트는 Full 상태를 판단하기 위한 추가 비트다. 따라서 FIFO index 0에 wr_ptr을 쓴다.

![Internal link preview tooltip](/images/content/sync_fifo/ex11.png)

- x[8] 데이터가 최종 write 되었다.

- 다음 클럭에서 wr_ptr이 최종 1 증가 되었다.

- 동시에 현재 wr_ptr에 x[9] 데이터를 write하는 중이다.

- 다음 데이터를 쓰기 위해 wr_ptr을 1 증가 시킨다.

## 3. Verilog RTL 구현

위 예제를 참고하여 RTL로 구현해보자. 구현하면서 주목할 점은 아래와 같다.

1. rd_ptr, wr_ptr의 Bitwidth는 log2(FIFO_DEPTH) + 1로 설정해야한다. 원래는 log2(FIFO_DEPTH)의 길이만 해도 충분하나, 1비트를 추가해서 FULL 상태를 판단할 수 있다.

2. rd_ptr또는 wr_ptr의 MSB를 제외한 비트를 FIFO index로 사용한다. 왜냐면 가장 상위 비트는 FULL 상태를 나타내는 비트기 떄문이다.

3. FULL 상태를 판단하기 위해서는 rd_ptr과 wr_ptr의 MSB가 다르고, MSB를 제외한 나머지 비트가 같다.

4. Empty 상태를 판단하기 위해서는 rd_ptr과 wr_ptr이 서로 같을 때다.