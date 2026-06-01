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
- **📊 Advanced Loss Modeling & Separation (多维损耗精确剥离与先进模型)**: Calculates and maps separate physical loss components across the motor and inverter:
  - **Copper Losses (铜损)**: Stator winding Joule heating $P_{cu} = 3 R_s (I_d^2 + I_q^2)$.
  - **Bertotti Iron Losses (铁损 - Bertotti 模型)**: Stator flux linkage dependent hysteresis, classical eddy current, and excess losses $P_{fe} = K_h \omega_e \psi_s^2 + K_c \omega_e^2 \psi_s^2 + K_e \omega_e^{1.5} \psi_s^{1.5}$.
  - **PM Eddy Current Losses (永磁体涡流损耗)**: Stator current and frequency dependent rotor PM heating $P_{pm} = K_{pm} \omega_e^2 (I_d^2 + I_q^2)$.
  - **Inverter Losses (逆变器损耗)**: Conduction and switching losses of power semiconductor switches $P_{inv} = (V_{on} I_s + R_{on} I_s^2) + K_{sw} f_{sw} V_{dc} I_s$.
  - **Windage & Friction (风摩损耗)**: Cubically speed-dependent mechanical losses $P_{fw} = K_{fw} \omega_m^3$.
  - **Stray Losses (杂散损耗)**: Load-dependent stray losses $P_{stray} = 0.5\% \times |P_{out}|$.
- **🎨 Elite Visualizations (学术级图表渲染)**: Automatically identifies and marks the **peak efficiency point**, plots the **rated continuous point**, traces continuous power envelopes, and generates highly polished contour plots.

---

## 📐 Underlying Engineering Physics / 核心数学模型

### Maximum Torque Per Ampere (MTPA)

For an Interior PMSM (IPMSM) where $L_d < L_q$, the electromagnetic torque is:

$$
T_e = 1.5 p \left[ \psi_f I_q + (L_d - L_q) I_d I_q \right]
$$

The MTPA control searches for a minimum current amplitude $I_s = \sqrt{I_d^2 + Iq^2}$ for any given torque $T_e$. This yields the optimal d-axis trajectory:

$$
I_d = \frac{\psi_f}{2(L_q - L_d)} - \sqrt{\frac{\psi_f^2}{4(L_q - L_d)^2} + I_q^2}
$$

### Inverter Voltage Limit & Flux Weakening

The stator steady-state phase voltages in the d-q rotating frame are:

$$
\begin{cases}
V_d = R_s I_d - \omega_e L_q I_q \\
V_q = R_s I_q + \omega_e (L_d I_d + \psi_f)
\end{cases}
$$

The voltage must satisfy the inverter capability limit:

$$
V_s = \sqrt{V_d^2 + V_q^2} \le V_{\max} = \frac{V_{dc}}{\sqrt{3}} \cdot m_{\max}
$$

When $V_s > V_{\max}$, the flux weakening controller injects additional negative d-axis demagnetizing current $I_d$ to satisfy the voltage circle limit.

### Advanced Loss Models (先进损耗模型)

To achieve higher accuracy, the toolbox implements high-fidelity loss models for each physical component:

#### 1. Bertotti Iron Loss Model (铁损)
Instead of simple speed-dependent terms, we utilize the stator flux linkage amplitude $\psi_s = \sqrt{\psi_d^2 + \psi_q^2}$ where $\psi_d = L_d I_d + \psi_f$ and $\psi_q = L_q I_q$:

$$
P_{fe} = K_h \omega_e \psi_s^2 + K_c \omega_e^2 \psi_s^2 + K_e \omega_e^{1.5} \psi_s^{1.5}
$$

where $K_h$ is the hysteresis coefficient, $K_c$ is the classical eddy current coefficient, and $K_e$ is the excess loss coefficient.

#### 2. Permanent Magnet Eddy Current Loss (永磁体涡流损耗)
Rotor permanent magnet losses induced by stator slotting harmonics and inverter carrier harmonics are modeled as:

$$
P_{pm} = K_{pm} \omega_e^2 (I_d^2 + I_q^2)
$$

#### 3. Inverter Loss Model (逆变器损耗)
Switching and conduction losses of the IGBT/SiC inverter are computed based on the phase current amplitude $I_s = \sqrt{I_d^2 + I_q^2}$:

$$
P_{inv} = \underbrace{(V_{on} I_s + R_{on} I_s^2)}_{\text{Conduction Losses}} + \underbrace{K_{sw} f_{sw} V_{dc} I_s}_{\text{Switching Losses}}
$$

where $V_{on}$ is the device forward voltage drop, $R_{on}$ is the dynamic resistance, $f_{sw}$ is the switching frequency, and $K_{sw}$ is the switching loss coefficient.

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

% 3. Define advanced loss parameters struct (optional)
loss = struct(...
    'Kh', 60.0, ...       % Hysteresis loss coefficient
    'Kc', 0.02, ...       % Classical eddy current loss coefficient
    'Ke', 0.1, ...        % Excess eddy current loss coefficient
    'Kpm', 1e-10, ...     % PM eddy current loss coefficient
    'Von', 1.2, ...       % Inverter switch forward voltage drop [V]
    'Ron', 15e-3, ...     % Inverter switch dynamic resistance [Ohm]
    'fsw', 10e3, ...      % Switching frequency [Hz]
    'Ksw', 2e-6, ...      % Inverter switching loss coefficient
    'Kfw', 8e-8 ...       % Friction & windage loss coefficient
);

% 4. Run high-performance computation
[N, T, ETA, losses] = pmsmEfficiencyMap(motor, loss);

% 4. Render and annotate the map
fig = plotEfficiencyMap(N, T, ETA, losses, motor);
```

---

## 📈 Visualizations / 效果图

When executing the runner script, a high-contrast figure using the `turbo` colormap will be generated, automatically annotating the Peak Efficiency Point, Rated continuous point, and symmetrical motoring/generating Constant Power Boundaries:

当运行示例程序后，工具箱将自动绘制高学术质感的四象限效率 Map 云图：

<p align="center">
  <img src="assets/efficiency_map_plot.png" alt="PMSM Four-Quadrant Efficiency Map" width="750"/>
</p>

- **Peak Efficiency (最高效率点)**: Marked with a red pentagram (红色五角星) and precise percentage text.
- **Rated Point (额定工作点)**: Marked with a magenta asterisk (品红色星号).
- **Constant Power Limits (恒功率边界)**: Symmetrically traced by top and bottom white dashed curves (白虚线).

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
