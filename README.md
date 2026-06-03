# 三端口 MAC 遍历回环验证工程

本仓库是集成电路课程 final project 的 ModelSim 仿真工程。工程在老师提供的 MAC 核仿真环境基础上，将单端口自回环验证改造成三端口遍历回环验证。

本次改造的核心目标是：不修改 `new_mac/hdl/` 下的 MAC 核 RTL，只通过 testbench 连接关系和仿真用例验证帧数据能按 `Port1 -> Port2 -> Port3 -> Port1` 的路径完整传递。

## 拓扑结构

![三端口 MAC 遍历回环拓扑](assets/topology.png)

数据路径如下：

```text
ephy 外部帧激励
  -> Port1 MAC RX
  -> Port2 MAC TX
  -> Port2 物理侧回环
  -> Port2 MAC RX
  -> Port3 MAC TX
  -> Port3 物理侧回环
  -> Port3 MAC RX
  -> Port1 MAC TX
  -> data_cmp 记录并比较最终输出
```

`data_cmp` 会同时记录 1 口输入和最终从 1 口输出的数据，生成 `indata.log` / `outdata.log`，用于判断三端口遍历后数据是否保持一致。

## 工程目录

```text
.
├── assets/
│   └── topology.png                       # README 使用的三端口验证拓扑图
├── new_mac/
│   ├── doc/                               # 实验文档、参考视频
│   │   ├── 参考视频.mp4                   # Git LFS 跟踪的视频文件
│   │   ├── 实验MAC核.docx
│   │   ├── MAC核控制器及回环验证实验.pdf
│   │   └── Modelsim仿真与FPGA工具应用.pdf
│   ├── hdl/                               # MAC 核 RTL 源码
│   │   ├── MAC_top.v                      # MAC 顶层
│   │   ├── MAC_rx.v / MAC_tx.v            # 收发主模块
│   │   ├── MAC_rx_ctrl.v / MAC_tx_Ctrl.v
│   │   └── ...                            # CRC、FIFO、RMON、寄存器等模块
│   ├── rtl.f                              # RTL 文件列表
│   └── sim/
│       ├── bfm/                           # 仿真辅助模型
│       │   ├── ephy.v                     # 外部以太网帧激励
│       │   ├── data_cmp.v                 # 输入/输出日志记录与比较
│       │   ├── host_sim.v                 # CPU 配置接口仿真模型
│       │   └── clockGenerator.v
│       ├── filelist/
│       │   ├── sim_filelist.v             # testbench/BFM 编译列表
│       │   └── hdl_filelist.v             # RTL 编译列表
│       ├── in_out/                        # 仿真输入/输出日志目录
│       ├── run/
│       │   ├── run.bat                    # Windows 下启动 ModelSim 的脚本
│       │   ├── sim.do                     # ModelSim 编译和运行脚本
│       │   ├── wave.do                    # 波形脚本占位文件
│       │   ├── modelsim.ini
│       │   └── top_define.v               # 仿真宏定义
│       ├── testbench/
│       │   └── testbench.v                # 三端口遍历回环 testbench
│       └── testcase/
│           ├── 0100000064.v               # 100M 随机帧测试
│           └── 0100000065.v               # 1000M 随机帧测试
├── .gitattributes                         # Git LFS 规则
├── .gitignore
├── LICENSE
└── README.md
```

## 关键实现

`new_mac/sim/testbench/testbench.v` 中实例化了 3 个 `MAC_top`：

```verilog
MAC_top MAC_top_inst1(...);  // Port1
MAC_top MAC_top_inst2(...);  // Port2
MAC_top MAC_top_inst3(...);  // Port3
```

用户侧连接关系改为遍历路径：

```text
Port1 用户侧 RX -> Port2 用户侧 TX
Port2 用户侧 RX -> Port3 用户侧 TX
Port3 用户侧 RX -> Port1 用户侧 TX
```

Port2 和 Port3 的 MII 物理侧做本地回环：

```verilog
hm_Rx_dv2 <= hm_Tx_en2;
hm_Rxd2   <= hm_Txd2;

hm_Rx_dv3 <= hm_Tx_en3;
hm_Rxd3   <= hm_Txd3;
```

三个 MAC 都通过 `host_sim` 完成速率配置。`0100000064.v` 配置为 100M，`0100000065.v` 配置为 1000M。仿真结束时，`testbench.v` 会打印 `PORT_COUNTS` 和 `USER_COUNTS`，用于检查中间端口是否真的完成收发。

## 运行环境

推荐环境：

- Windows
- ModelSim / QuestaSim，命令行可直接调用 `vsim`
- Git LFS，用于拉取 `new_mac/doc/参考视频.mp4`

第一次克隆仓库后，如果需要参考视频，先执行：

```bat
git lfs install
git lfs pull
```

如果只运行 Verilog 仿真，不拉取视频也不影响编译和仿真。

## 运行方法

进入仿真运行目录：

```bat
cd new_mac\sim\run
```

方式一：使用批处理脚本启动 ModelSim：

```bat
run.bat
```

方式二：直接用 ModelSim 命令行运行：

```bat
vsim -c -do "do sim.do; quit -f"
```

`sim.do` 会依次执行：

```text
vlib ./lib/
vlib ./lib/work
vmap work ./lib/work
vlog -f ../filelist/sim_filelist.v
vlog -f ../filelist/hdl_filelist.v -cover bcesxf
vsim -voptargs=+acc -coverage work.testbench
run -all
```

如果 ModelSim 对中文路径兼容不好，可以先把工程目录映射到英文盘符：

```bat
subst X: "D:\study\大三下\集成电路\final_project"
cd /d X:\new_mac\sim\run
vsim -c -do "do sim.do; quit -f"
```

仿真完成后，重点查看下面这些文件：

```text
new_mac/sim/run/transcript
new_mac/sim/in_out/0100000064_indata.log
new_mac/sim/in_out/0100000064_outdata.log
new_mac/sim/in_out/0100000065_indata.log
new_mac/sim/in_out/0100000065_outdata.log
```

也可以在 `transcript` 中搜索：

```text
PORT_COUNTS
USER_COUNTS
Errors:
Warnings:
```

## 测试用例

| 用例 | 速率 | 入口文件 | 激励 | 预期结果 |
| --- | --- | --- | --- | --- |
| `0100000064` | 100M | `new_mac/sim/testcase/0100000064.v` | 100 帧随机长度以太网帧 | 输入日志和最终输出日志一致 |
| `0100000065` | 1000M | `new_mac/sim/testcase/0100000065.v` | 100 帧随机长度以太网帧 | 输入日志和最终输出日志一致 |

两个 testcase 都由 `new_mac/sim/testbench/testbench.v` 通过 `` `include `` 顺序执行：

```verilog
`include "../testcase/0100000064.v"
`include "../testcase/0100000065.v"
```

## 当前验证结果

当前工程已完成 100M 和 1000M 两组遍历回环验证，编译无错误：

```text
vlog -f ../filelist/sim_filelist.v    Errors: 0, Warnings: 0
vlog -f ../filelist/hdl_filelist.v    Errors: 0, Warnings: 0
```

100M 用例：

```text
PORT_COUNTS 0100000064 p1_tx=100 p2_tx=100 p2_rx=100 p3_tx=100 p3_rx=100
USER_COUNTS 0100000064 p1_rx=100 p2_rx=100 p3_rx=100 uflow=0/0/0
```

1000M 用例：

```text
PORT_COUNTS 0100000065 p1_tx=100 p2_tx=100 p2_rx=100 p3_tx=100 p3_rx=100
USER_COUNTS 0100000065 p1_rx=100 p2_rx=100 p3_rx=100 uflow=0/0/0
```

日志比较结果：

| 用例 | 输入帧数 | 输出帧数 | 结果 |
| --- | ---: | ---: | --- |
| `0100000064` | 100 | 100 | 输入/输出日志一致 |
| `0100000065` | 100 | 100 | 输入/输出日志一致 |

## 常见问题

### 1. GitHub 上看不到参考视频

视频文件使用 Git LFS 管理。克隆后执行：

```bat
git lfs pull
```

### 2. `vsim` 命令找不到

说明 ModelSim 没有加入系统 `PATH`。可以把 ModelSim 的 `win64` 或 `win32` 目录加入环境变量，或者在 `run.bat` 中把 `vsim` 改成完整路径，例如：

```bat
"C:\modeltech64_10.5\win64\vsim.exe" -do sim.do
```

### 3. 中文路径导致脚本或文件打不开

使用英文路径或 `subst` 映射盘符：

```bat
subst X: "D:\study\大三下\集成电路\final_project"
cd /d X:\new_mac\sim\run
```

### 4. 仿真后生成很多临时文件

ModelSim 可能生成 `work/`、`lib/`、`transcript`、`vsim.wlf` 等文件。这些属于运行产物，不需要提交到 Git。

## 结论

本工程完成了三端口 MAC 遍历回环验证。100M 和 1000M 模式下，100 帧随机长度以太网帧均能按 `1 -> 2 -> 3 -> 1` 的路径传递，最终输出与输入一致，中间端口收发计数一致，发送 FIFO 下溢计数为 0。
