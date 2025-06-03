---
title: "I2C Protocol Demo"
description: ""
icon: "code"
date: "2023-05-22T00:44:31+01:00"
lastmod: "2023-05-22T00:44:31+01:00"
draft: false
toc: true
weight: 210
---

{{% alert context="warning" text="The front matter `description` value for this page has been intentionally left empty in order to demonstrate FlexSearch's suggested results fallback behaviour." /%}}

## 1. 데모 설명
Zybo Z7-10 FPGA 보드에서 I2C-Protocol을 활용해 외부 장치인 Display를 제어하는 방법을 기술한다.

I2C 프로토콜의 동작원리를 파악하고 Verilog를 활용해 I2C-Protocol를 설계한다. 그 다음 SSD 1306 드라이버 기반으로 동작하는 디스플레이 주변장치를 FPGA와 연결하여 제어하는 DEMO를 기술한다.

## 2. I2C 프로토콜

I2C 프로토콜이란 서로 다른 두 개의 칩 사이의 통신 프로토콜 중 하나이다.

I2C 프로토콜은 한 개의 Master가 여러 개의 Slave를 제어할 때 사용할 수 있는 프로토콜이다. 또한 I2C 프로토콜은 Master와 Slave가 클럭에 동기화 되어 동작하는 프로토콜이다.

&nbsp;

### 2.1 I2C-Protocol 동작 원리

![Internal link preview tooltip](/images/content/i2c/i2c_image.png)  
위 그림에서 살펴볼 수 있듯이 1개의 Master가 여러개의 Slave와 데이터를 주고 받기 위해서 I2C 프로토콜을 활용한다. 이 때 Slave의 개수는 보통 127개에서 1024개까지 사용한다. Vs는 Slave가 동작하는데 필요한 입력 전압이다. 해당 Demo에서 사용할 SSD 1306 디스플레이 장치는 3.3V를 사용하여 동작한다.

SCL은 Master와 Slave가 공유하는 데이터 클럭 라인이다. I2C는 그래서 동기식 프로토콜이다. SCL의 클럭 상태에 맞춰서 데이터가 전송된다.

SDA는 Master와 Slave사이에서 데이터가 이동하는 라인이다. 즉 I2C 프로토콜은 SCL라인과 SDA라인 2개만 사용해서 데이터를 주고 받는 아주 간단한 프로토콜이다.

I2C 프로토콜에서 사용되는 인터페이스를 모두 알았다. 다음은 SCL과 SDA의 동작 관계에 살펴보자.

&nbsp;

![Internal link preview tooltip](/images/content/i2c/timing.png) 

I2C 프로토콜이 동작하기 전, SDA와 SCL의 초기값은 항상 1상태를 유지해야한다. 왜냐면 Open Drain을 사용해야 하기 때문이다. 

초기값이 1일 때 하나의 선에 여러 Slave가 데이터를 공유할 수 있고, 신호 충돌을 방지할 수 있는 장점이 있다고 한다. (이해는 못했음..)

이제 I2C 프로토콜의 동작 타이밍을 살펴보자.

1. SDA가 1에서 0으로 떨어진다.

2. SCL 클럭의 7클럭 동안 SDA를 통해 Slave의 Address 주소 데이터가 전달된다.

    -- 7클럭 동안 Slave의 Address 주소 데이터를 전달하는 이유는 간단하다. I2C 프로토콜에서 Slave의 개수는 128개 까지 늘어날 수 있기 때문이다. (물론 1024개라면 10클럭동안 Address 주소 데이터를 전달해야 한다.)

3. 8번째 클럭에서 Master는 Read또는 Write 정보를 SDA를 통해 전달한다. 만약 8번째 클럭에 전달되는 데이터가 0이라면 Write 명령이다. 즉 Master는 앞선 7비트 주소를 갖는 Slave에 데이터를 쓰겠다는 의미다. 반대로 8번째 클럭에 전달되는 데이터가 1이라면 Read 명령이다. 즉 7비트 주소를 갖는 Slave로부터 데이터를 읽겠다는 의미다.

4. 8번째 클럭에서 Write 또는 Read 명령이 Slave에게 전달되면 9번째 클럭에서 Slave는 Ack 정보를 Master에게 전달한다. 만약 9번째 클럭에서 Master가 0을 받는다면 Slave로부터 ACK를 받은 것이다. 이 말은 8번째 클럭에서 Slave가 Write/Read 데이터를 제대로 받았다는 뜻이다. 반대로 9번째 클럭에서 Master가 1을 받는다면 Slave로부터 NACK를 받은 것이다. 즉 8번째 클럭에서 Slvae가 Write/Read 데이터를 제대로 받지 못했다는 뜻이다. 이 경우 1번 과정으로 돌아간다.

5. 만약 Master ACK를 받았다면 이제 데이터를 Write 또는 Read해야 한다. 8번째 클럭에서 Master가 Write 명령을 줬다면 Master가 Slave에 쓸 데이터를 이제 보내기 시작한다. Master가 8클럭에 걸쳐서 8개의 비트를 보내면 Slave는 8번째 비트를 받을 때마다, ACK를 보낸다. 

6. 8번째 클럭에서 Master가 Read 명령을 줬다면 Slave가 Master에게 데이터를 보내기 시작한다. 이 때 Master가 8비트의 데이터를 받았다면 ACK를 Slave에게 보내야 한다.

