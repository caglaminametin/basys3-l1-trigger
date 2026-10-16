# Jet tagger results

hls4ml LHC jet dataset (OpenML 42468), 16 high-level features, 5 classes (g, q, t, w, z).
Stratified 80/20 train/test split (seed 42), StandardScaler fitted on the training set only.
Architecture: 16 → 64 → 32 → 32 → 5 MLP (ReLU), logits output.

## Accuracy vs. resources (HGQ2 quantization-aware training)

| Model | β | EBOPs (after `trace_minmax`) | hls4ml test accuracy | Δ vs. float | Bit-exact (Keras ↔ hls4ml C-sim) |
|---|---|---|---|---|---|
| Float baseline | — | — | 77.13 % | — | — |
| HGQ2 | 1e-6 | 34 441 | 76.78 % | −0.35 | ✅ |
| HGQ2 | 3e-6 | 9 872 | 76.25 % | −0.88 | ✅ |
| HGQ2 | 1e-5 | 2 926 | 75.38 % | −1.75 | ✅ |
| HGQ2 | 3e-5 | 1 307 | 74.61 % | −2.52 | ✅ |

Test set: 166 000 jets. "Bit-exact" means the hls4ml C++ model output is identical to the
Keras model output for every test jet (max |difference| = 0).

EBOPs are HGQ2's resource estimate (≈ LUT + 55 × DSP for hls4ml). Real LUT/DSP numbers
from Vitis HLS / Vivado synthesis on `xc7a35tcpg236-1` are still to be added.

## Settings

- HGQ2 0.2.0, hls4ml 1.3.0, Keras 3.15.1 (TensorFlow backend), Google Colab CPU
- 100 epochs, batch 1024, Adam with cosine-decay learning rate (3e-3 → 0)
- Weights: `kbi` quantizers, SAT_SYM; activations: `kif` quantizers, WRAP
- hls4ml: Vitis backend, `io_parallel`, part `xc7a35tcpg236-1`, 10 ns clock

## Methodology note

The model is taken from the **last epoch**. An earlier version selected the epoch with the best
validation accuracy; for large β this picked an early, almost unpruned model
(β = 3e-5: 220 985 EBOPs instead of 1 307), because accuracy peaks before the resource penalty
has pruned the bit widths. All results above use last-epoch selection.
