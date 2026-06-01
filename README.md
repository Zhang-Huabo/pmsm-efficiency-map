# 🚀 Professional Four-Quadrant PMSM Efficiency Map Calculator
## 永磁同步电机四象限效率图计算与绘制工具箱

[![MATLAB Version](https://img.shields.io/badge/MATLAB-R2022a%2B-blue.svg)](https://www.mathworks.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![GitHub Actions](https://img.shields.io/badge/CI-MATLAB--Workflow-orange.svg)](.github/workflows/ci.yml)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](#contributing)

A high-performance, modular, and physics-informed MATLAB toolbox designed to compute and visualize **four-quadrant efficiency maps (Efficiency Maps)** for Permanent Magnet Synchronous Motors (PMSM). 

本工具箱是一个专为**永磁同步电机（PMSM）**设计的、高性能且物理特征完备的四象限效率图（Efficiency Map）计算与可视化 MATLAB 工具箱。通过解耦模块化重构，代码对 Git 差异控制极度友好，适用于学术研究、工程级电机性能评估与报告生成。

---

## 🌟 Key Features / 功能亮点

- **⚡ Four-Quadrant Analysis (四象限完整分析)**: Supports both motoring (电动) and generating/regenerative (发电/制动) modes, with rigorous quadrant-specific efficiency definition calculations.
- **🎯 MTPA Stator Current Optimization (最大转矩电流比控制)**: Numerically solves for the optimal $I_d$ and $I_q$ trajectories to minimize copper losses under all torque demands.
- **🌀 Dynamic Flux Weakening Boundary (动态弱磁控制)**: Automatically engages a robust voltage-limit-circle solver (`fzero` on negative $I_d$) when back-EMF exceeds inverter DC bus limits.
- **📊 segregate Loss Modeling (多维损耗精确剥离)**: Calculates and maps separate core loss components:
  - **Copper Losses (铜损)**: Stator Joule heating $P_{cu} = 3 R_s I_s^2$.
  - **Iron Losses (铁损)**: Speed-dependent hysteresis and eddy-current losses $P_{fe} = K_h \omega_e + K_e \omega_e^2$.
  - **Windage & Friction (风摩损耗)**: Cubically speed-dependent mechanical losses $P_{fw} = K_{fw} \omega_m^3$.
  - **Stray Losses (杂散损耗)**: Load-dependent stray losses $P_{stray} = 0.5\% \times |P_{out}|$.
- **🎨 Elite Visualizations (学术级图表渲染)**: Automatically identifies and marks the **peak efficiency point**, plots the **rated continuous point**, traces continuous power envelopes, and generates highly polished contour plots.

---

## 📐 Underlying Engineering Physics / 核心数学模型

### Maximum Torque Per Ampere (MTPA)
For an Interior PMSM (IPMSM) where $L_d < L_q$, the electromagnetic torque is:
$$T_e = 1.5 p \left[ \psi_f I_q + (L_d - L_q) I_d I_q \right]$$

The MTPA control searches for a minimum current amplitude $I_s = \sqrt{I_d^2 + Iq^2}$ for any given torque $T_e$. This yields the optimal d-axis trajectory:
$$I_d = \frac{\psi_f}{2(L_q - L_d)} - \sqrt{\frac{\psi_f^2}{4(L_q - L_d)^2} + I_q^2}$$

### Inverter Voltage Limit & Flux Weakening
The stator steady-state phase voltages in the d-q rotating frame are:
$$\begin{cases} 
V_d = R_s I_d - \omega_e L_q I_q \\ 
V_q = R_s I_q + \omega_e (L_d I_d + \psi_f) 
\end{cases}$$

The voltage must satisfy the inverter capability limit:
$$V_s = \sqrt{V_d^2 + V_q^2} \le V_{\max} = \frac{V_{dc}}{\sqrt{3}} \cdot m_{\max}$$
When $V_s > V_{\max}$, the flux weakening controller injects additional negative d-axis demagnetizing current $I_d$ to satisfy the voltage circle limit.

---

## 📂 Project Structure / 目录结构

```text
├── .github/
│   └── workflows/
│       └── ci.yml               # GitHub Actions CI Workflow configuration
├── src/                         # Core Source Code Library
│   ├── mtpaCurrent.m            # Numerical MTPA solver
│   ├── pmsmEfficiencyMap.m      # Four-quadrant calculation engine
│   └── plotEfficiencyMap.m      # High-end figure plotting & annotation
├── examples/                    # Examples and Demonstrations
│   └── run_example.m            # One-click execution script script
├── PMSM_Efficiency_Map.mlx      # Live Script Demonstration
├── .gitignore                   # MATLAB Git exclusion patterns
├── LICENSE                      # MIT Permissive License
└── README.md                    # This document
```

---

## 🚀 Quick Start / 快速开始

To run the calculation and plot the efficiency map, clone the repository and run the demo runner script:

只需将本项目克隆至本地，在 MATLAB 中运行 `examples/run_example.m` 即可一键完成计算与高颜值云图绘制：

```matlab
% In MATLAB Command Window:
cd('examples');
run_example;
```

### Core API Usage / 核心 API 调用示例

```matlab
% 1. Add src folder to MATLAB path
addpath('../src');

% 2. Define motor physical parameters struct
motor = struct(...
    'p', 2, 'Rs', 12.45e-3, 'Ld', 38.2e-6, 'Lq', 46.3e-6, ...
    'psi_f', 28.67e-3, 'Vdc', 270, 'm_max', 0.95, ...
    'Imax', 400, 'Pn', 26e3, 'P_max', 75e3, 'n_max', 40000, ...
    'T_max', 35, 'n_rated', 18000 ...
);

% 3. Run high-performance computation
[N, T, ETA, losses] = pmsmEfficiencyMap(motor);

% 4. Render and annotate the map
fig = plotEfficiencyMap(N, T, ETA, losses, motor);
```

---

## 📈 Visualizations / 效果图

When executing the runner script, a high-contrast figure using the `turbo` colormap will be generated, automatically annotating:
1. **The Peak Efficiency Point (最高效率点)** with a red pentagram and precise percentage value.
2. **The Continuous Rated Continuous Point (额定持续工作点)** marked with a magenta asterisk.
3. **Motoring & Generating Constant Power Boundaries (恒功率双向曲线)** traced dynamically with white dashed curves.

---

## 🤝 Contributing / 贡献指南

Contributions are highly welcome! If you want to add new features (such as thermal models, spatial harmonic losses, or different modulation techniques), please:
1. Fork this Repository.
2. Create a feature branch (`git checkout -b feature/NewFeature`).
3. Commit your changes.
4. Push to the branch (`git push origin feature/NewFeature`).
5. Open a Pull Request.

欢迎对本项目做出贡献！如果您希望扩展新的功能（例如：电机热网络模型、空间谐波铁损、不同调制策略下的电压环计算），欢迎提交 Issue 或 Pull Request。

---

## 📜 License / 开源协议

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.
本项目基于 **MIT 开源协议** 共享 - 详情请参阅 [LICENSE](LICENSE) 文件。
