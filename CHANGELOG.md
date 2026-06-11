# 更新记录

## 2026-06-11

- 将 `data_cmp` 改为带 `MONITOR_NAME` 参数的可复用监视器。
- 在 testbench 中为 MAC1、MAC2、MAC3 分别实例化数据监视器。
- 日志命名调整为 `<testcase>_<MAC>_[in|out]data.log`。
- 修正 TX 延迟采样时钟为 `Tx_clk`。
- 更新 100M、1000M testcase，使其依次等待三个监视器完成。
- 使用 ModelSim 10.4 完整回归 100M、1000M 两种模式，各发送 100 帧。
- 验证三个 MAC 的输入输出日志逐对 SHA256 一致，TX FIFO 下溢计数为 0。
- 更新 README 和 CSDN 发布版说明，增加最终课程报告。
