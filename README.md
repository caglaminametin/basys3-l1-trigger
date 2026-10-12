# Basys 3 Mini L1 Trigger

A scaled-down **Level-1 trigger system** with **machine learning inference on an FPGA**, built on a low-cost Digilent Basys 3 board.

At the LHC, Level-1 trigger systems must decide within microseconds which collision events to keep, and a growing share of these decisions is made by small neural networks running on FPGAs. This project reproduces that workflow end to end on a small Artix-7 device: a PC emulates the detector and streams events over UART, the FPGA runs hand-written trigger logic and a quantized neural network, and every decision is checked bit-exactly against a software reference model.

## Goals

- Build a complete, testable trigger chain on real hardware, not only out-of-context synthesis estimates
- Run a jet tagging neural network on the FPGA using the **hls4ml** workflow (quantization-aware training → HLS → Vivado)
- Measure accuracy, latency (in clock cycles) and resource usage, and study the trade-offs on a device with only 90 DSP slices
- Keep everything reproducible: version-controlled sources, testbenches and scripted builds

## Hardware and tools

| | |
|---|---|
| Board | Digilent Basys 3 |
| FPGA | AMD Artix-7 `xc7a35tcpg236-1` (≈33k logic cells, 90 DSP, 50 BRAM36) |
| Clock | 100 MHz on-board oscillator |
| Toolchain | Vivado ML Standard 2024.1 (includes Vitis HLS) |
| HDL | Verilog |
| ML | Python, Keras / QKeras, hls4ml |

## Architecture

```
   PC (Python)                          Basys 3 (FPGA)
 ┌───────────────┐   UART    ┌──────────────────────────────────────┐
 │ Event         │ ────────► │ UART RX → Event buffer (BRAM)        │
 │ generator     │           │                │                     │
 │               │           │     ┌──────────┼──────────┐          │
 │ Reference     │           │     ▼          ▼          ▼          │
 │ model         │           │  Cluster    Neural net  Autoencoder  │
 │               │           │  finder     (hls4ml)    (anomaly)    │
 │ Bit-exact     │           │  (RTL)                               │
 │ comparison    │ ◄──────── │      Trigger decision + latency      │
 │ + reports     │   UART    │      counter → UART TX, LEDs         │
 └───────────────┘           └──────────────────────────────────────┘
```

UART is slow, but it only loads the event buffer. The trigger logic itself runs at the full 100 MHz clock, and an on-chip counter measures its true latency in clock cycles.

## Project stages

| Stage | Description | Status |
|---|---|---|
| 0 | Toolchain bring-up: switches, LEDs, clock divider, button synchronizer | ✅ Done |
| 1 | UART RX/TX, packet format, Python host interface, first testbenches | ⏳ Next |
| 2 | Hand-written RTL trigger: thresholding, local maxima, cluster sums on an 8×8 calorimeter grid, fixed latency | Planned |
| 3 | Jet tagging MLP with hls4ml (hls4ml LHC jet dataset), comparison with published XC7A35T results |🔄 Float baseline done (77.1%)  |
| 4 | Autoencoder-based anomaly detection trigger | Planned |
| 5 | Documentation and technical note | Planned |

## Stage 0 results

Simple bring-up design: `sw[14:0]` drive `led[14:0]`, `led[15]` blinks at 1 Hz, `btnC` resets the blink logic through a 2-FF synchronizer.

| Metric | Value |
|---|---|
| Flip-flops | 29 (26-bit counter + blink + 2-stage synchronizer) |
| LUTs | 10 |
| Clock constraint | 100 MHz (10 ns) |
| Worst negative slack (WNS) | +5.376 ns |
| Worst hold slack (WHS) | +0.263 ns |

All timing constraints met. Verified on hardware.

## Repository layout

```
hw/
  rtl/           Verilog sources
  constraints/   XDC pin and timing constraints
  sim/           Testbenches
sw/              Host-side Python (UART, event generator, reference model)
ml/              Training, quantization and hls4ml notebooks
docs/            Diagrams, results, technical note
```

## Building (Stage 0)

1. Create a new RTL project in Vivado for part `xc7a35tcpg236-1` (or the Basys 3 board).
2. Add `hw/rtl/top.v` as a design source and `hw/constraints/basys3.xdc` as a constraint file, **without** copying them into the project.
3. Run *Generate Bitstream* and program the board from the Hardware Manager.

A scripted Tcl build will replace these manual steps in a later stage.

## References

- J. Duarte et al., *Fast inference of deep neural networks in FPGAs for particle physics*, JINST 13 P07027 (2018), [arXiv:1804.06913](https://arxiv.org/abs/1804.06913)
- *hls4ml: A Flexible, Open-Source Platform for Deep Learning Acceleration on Reconfigurable Hardware*, [arXiv:2512.01463](https://arxiv.org/abs/2512.01463)
- hls4ml LHC jet dataset (high-level features): [OpenML 42468](https://www.openml.org/d/42468), [doi:10.5281/zenodo.3602260](https://doi.org/10.5281/zenodo.3602260)

## Author

Çağla Mina Metin

## License

MIT, see [LICENSE](LICENSE).
