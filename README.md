# 三端口 MAC 遍历回环验证

本工程基于老师提供的单端口 MAC 自回环仿真环境改造而来。原始工程保存在 `old_mac/`，完成后的三端口版本保存在 `new_mac/`。

本次修改没有改动 MAC 核 RTL，主要是在仿真平台中实例化 3 个 `MAC_top`，把原来的单 MAC 自回环改成三端口遍历回环：

```text
Port1 RX -> Port2 TX -> Port2 RX -> Port3 TX -> Port3 RX -> Port1 TX
```

最终验证结果：100M 和 1000M 两个测试用例均发送 100 帧，端口计数一致，发送 FIFO 无下溢，1 口输入日志和最终输出日志完全一致。

## 工程目录

| 路径 | 说明 |
| --- | --- |
| `old_mac/` | 老师给的原始单端口 MAC 自回环工程 |
| `new_mac/` | 改造后的三端口遍历回环工程 |
| `new_mac/hdl/` | MAC 核 RTL，本次基本未改动 |
| `new_mac/sim/testbench/testbench.v` | 三端口 testbench，主要修改文件 |
| `new_mac/sim/bfm/data_cmp.v` | MII 输入/输出日志记录与比较辅助模块 |
| `new_mac/sim/testcase/0100000064.v` | 100M 随机帧测试用例 |
| `new_mac/sim/testcase/0100000065.v` | 1000M 随机帧测试用例 |
| `new_mac/sim/run/sim.do` | ModelSim 仿真脚本 |
| `new_mac/sim/in_out/` | 仿真生成的输入/输出日志 |

## 三端口拓扑

![](C:/Users/ladyg/Downloads/ChatGPT Image 2026年6月3日 19_44_59.png)

​                                                                   图1：流程拓扑图

说明：

- 1 口由 `ephy` 产生外部输入帧。
- 2 口和 3 口把本端 `Tx_en/Txd` 寄存一拍后回接到本端 `Rx_dv/Rxd`，用于模拟物理侧回环。
- `data_cmp` 记录 1 口外部输入和最终从 1 口发出的输出，用于判断最终数据是否一致。
- 中间端口是否真正经过链路，通过 `testbench.v` 中的 `p2_tx/p2_rx/p3_tx/p3_rx` 计数确认。

## 运行方法

进入仿真目录：

```bat
cd new_mac\sim\run
vsim -c -do "do sim.do; quit -f"
```

如果 ModelSim 因中文路径报错，可以先映射一个英文盘符：

```bat
subst X: "D:\study\大三下\集成电路\final_project"
cd /d X:\new_mac\sim\run
vsim -c -do "do sim.do; quit -f"
```

仿真结束后主要查看：

```text
new_mac/sim/run/transcript
new_mac/sim/in_out/0100000064_indata.log
new_mac/sim/in_out/0100000064_outdata.log
new_mac/sim/in_out/0100000065_indata.log
new_mac/sim/in_out/0100000065_outdata.log
```

## 验证结果

当前 `new_mac` 已完成仿真，编译无错误：

```text
vlog -f ../filelist/sim_filelist.v    Errors: 0, Warnings: 0
vlog -f ../filelist/hdl_filelist.v    Errors: 0, Warnings: 0
```

100M 用例 `0100000064`：

```text
PORT_COUNTS 0100000064 p1_tx=100 p2_tx=100 p2_rx=100 p3_tx=100 p3_rx=100
USER_COUNTS 0100000064 p1_rx=100 p2_rx=100 p3_rx=100 uflow=0/0/0
```

1000M 用例 `0100000065`：

```text
PORT_COUNTS 0100000065 p1_tx=100 p2_tx=100 p2_rx=100 p3_tx=100 p3_rx=100
USER_COUNTS 0100000065 p1_rx=100 p2_rx=100 p3_rx=100 uflow=0/0/0
```

日志比较结果：

| 用例 | 模式 | 输入帧数 | 输出帧数 | 结果 |
| --- | --- | ---: | ---: | --- |
| `0100000064` | 100M | 100 | 100 | 输入/输出日志一致 |
| `0100000065` | 1000M | 100 | 100 | 输入/输出日志一致 |

`transcript` 中的 2 条 warning 来自 batch 模式下 WLF 波形文件占用，不影响编译、仿真和日志比较结果。

## 重点代码改动

### 1. `sim/testbench/testbench.v`

原始 `old_mac` 只有一个 `MAC_top`，并把该 MAC 的用户侧 RX 直接接回 TX，只能验证单端口自回环。

现在改为 3 个 MAC 实例：

```verilog
MAC_top MAC_top_inst1(...);  // Port1
MAC_top MAC_top_inst2(...);  // Port2
MAC_top MAC_top_inst3(...);  // Port3
```

用户侧连接改成遍历路径：

```text
Port1 RX -> Port2 TX
Port2 RX -> Port3 TX
Port3 RX -> Port1 TX
```

2 口、3 口增加物理侧回环：

```verilog
hm_Rx_dv2 <= hm_Tx_en2;
hm_Rxd2   <= hm_Txd2;

hm_Rx_dv3 <= hm_Tx_en3;
hm_Rxd3   <= hm_Txd3;
```

同时增加了三组 `host_sim`，保证三个 MAC 都会配置速率：

```verilog
if (mode == 0) begin
    U_host_sim.CPU_wr(7'd34,16'h2);
    U_host_sim2.CPU_wr(7'd34,16'h2);
    U_host_sim3.CPU_wr(7'd34,16'h2);
end else begin
    U_host_sim.CPU_wr(7'd34,16'h4);
    U_host_sim2.CPU_wr(7'd34,16'h4);
    U_host_sim3.CPU_wr(7'd34,16'h4);
end
```

为了解决 1000M 下 RX FIFO 水线过大可能导致卡住的问题，三个 MAC 都通过 CPU 接口配置：

```verilog
Rx_Hwmark = 4;
Rx_Lwmark = 2;
```

另外，`testbench.v` 增加了端口帧计数和下溢计数，仿真结束时打印 `PORT_COUNTS` 和 `USER_COUNTS`。

### 2. `sim/bfm/data_cmp.v`

原来的 `OVER` 会立即关闭日志文件。三端口链路更长，最后一帧可能还没从 1 口 TX 发完，所以现在关闭前会等待输出帧数追上输入帧数：

```verilog
while ((frm_cnt2 < frm_cnt1) && (drain_wait < 500000))
    @(posedge Tx_clk);
```

这样可以避免日志末尾被提前截断。

### 3. `sim/testcase/0100000064.v` 和 `0100000065.v`

测试用例改成先设置 `testcase_name` 和 `mode`，再执行 reset：

```verilog
testcase_name = "0100000064";
mode = 1'b0;
U_clockGenerator.RESET;
CHOOSE_MODE;
```

这样 `data_cmp` 在 reset 下降沿初始化日志时能拿到正确的用例名。1000M 用例末尾还增加了额外等待时间，保证三端口路径排空后再关闭日志。

## 结论

改造后的 `new_mac` 在不修改 MAC 核 RTL 的前提下，通过 testbench 完成了三端口遍历回环验证。100M 和 1000M 模式下，100 帧随机长度以太网帧均能按 `1 -> 2 -> 3 -> 1` 的路径传递，最终输出与输入一致，中间端口收发计数一致，发送 FIFO 下溢计数为 0。
