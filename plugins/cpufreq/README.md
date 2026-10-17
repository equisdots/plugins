# CPU Frequency

Average CPU frequency in MHz.

- Kind: **bar module** (`provides.bar.modules.cpufreq`)
- Value producer: `scripts/cpufreq.sh`
- Settings: Plugins → CPU Frequency (`settings/CpufreqPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
