// qs_visualizer — audio spectrum feed untuk Quickshell media visualizer.
//
// Pengganti `cava` + `cava_feed.sh`: membaca langsung dari PipeWire
// (monitor default sink), menghitung spektrum FFT (fftw3), lalu menulis
// 1 baris per frame ke stdout: 64 angka (0-255) dipisah spasi.
//
// Format output identik dengan cava raw ascii, jadi sisi QML yang membaca
// nilai 0-255 tetap kompatibel.
//
// Build:  bash scripts/build-visualizer.sh
// Jalankan saat dibutuhkan (ProcessManager), bukan terus-menerus.

#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>
#include <spa/param/audio/raw.h>
#include <spa/utils/ringbuffer.h>

#include <fftw3.h>
#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <csignal>
#include <thread>
#include <chrono>
#include <vector>

namespace {

constexpr int kBars        = 64;             // harus sama dengan CavaRingDank.bars
constexpr int kFftSize     = 2048;           // window FFT (sampel mono)
constexpr int kWindowRate  = 48000;          // rate yang diminta (resample otomatis)
constexpr int kChannels    = 2;
constexpr float kFrameMs   = 33.f;           // ~30 fps output

// ── Ring buffer single-producer (RT callback) / single-consumer (FFT thread) ──
constexpr size_t kRbFloats = 1 << 19;        // 512k float interleaved (~5.5 s stereo 48k)
constexpr size_t kRbMask   = kRbFloats - 1;
std::vector<float> g_ring(kRbFloats);
std::atomic<size_t> g_wp{0}, g_rp{0};

std::atomic<bool> g_terminate{false};

struct PwState {
    struct pw_main_loop *loop = nullptr;
    struct pw_stream *stream = nullptr;
    struct pw_loop *loopImpl = nullptr;
    bool haveFormat = false;
};

PwState g_pw;

void printZeros() {
    static char line[512];
    size_t off = 0;
    for (int i = 0; i < kBars; i++) off += snprintf(line + off, sizeof(line) - off, "%s0", i ? " " : "");
    off += snprintf(line + off, sizeof(line) - off, "\n");
    fwrite(line, 1, off, stdout);
}

void onProcess(void *userdata) {
    auto *data = static_cast<PwState *>(userdata);
    if (!data->haveFormat) return;

    struct pw_buffer *b = pw_stream_dequeue_buffer(data->stream);
    if (b == nullptr) return;

    struct spa_buffer *buf = b->buffer;
    if (buf->datas[0].data == nullptr) {
        pw_stream_queue_buffer(data->stream, b);
        return;
    }

    const uint32_t nFrames =
        buf->datas[0].chunk->size / (sizeof(float) * kChannels);
    const float *samples = static_cast<const float *>(buf->datas[0].data);

    // Copy interleaved F32 ke ring buffer.
    const size_t total = static_cast<size_t>(nFrames) * kChannels;
    size_t wp = g_wp.load(std::memory_order_relaxed);
    for (size_t i = 0; i < total; i++) {
        g_ring[(wp + i) & kRbMask] = samples[i];
    }
    g_wp.store(wp + total, std::memory_order_release);

    pw_stream_queue_buffer(data->stream, b);
}

void onParamChanged(void *userdata, uint32_t id, const struct spa_pod *param) {
    auto *data = static_cast<PwState *>(userdata);
    if (param == nullptr || id != SPA_PARAM_Format) return;

    struct spa_audio_info_raw raw{};
    if (spa_format_audio_raw_parse(param, &raw) < 0) return;
    (void)raw; // kita tetap minta F32 lewat format builder; chunk sudah float.
    data->haveFormat = true;
}

void onStreamStateChanged(void *userdata, enum pw_stream_state old, enum pw_stream_state state,
                          const char *error) {
    auto *data = static_cast<PwState *>(userdata);
    (void)old;
    if (state == PW_STREAM_STATE_ERROR || state == PW_STREAM_STATE_UNCONNECTED) {
        if (!g_terminate.load()) {   // abaikan error saat shutdown
            fprintf(stderr, "[qs_visualizer] PipeWire stream error: %s\n", error ? error : "unknown");
            g_terminate.store(true);
            pw_main_loop_quit(data->loop);
        }
    }
}

void onSignal(void *userdata, int signal_number) {
    auto *data = static_cast<PwState *>(userdata);
    (void)signal_number;
    g_terminate.store(true);
    pw_main_loop_quit(data->loop);
}

const struct pw_stream_events kStreamEvents = {
    PW_VERSION_STREAM_EVENTS,
    .state_changed = onStreamStateChanged,
    .param_changed = onParamChanged,
    .process = onProcess,
};

// ── FFT worker ───────────────────────────────────────────────────────────
void fftWorker() {
    // fftw plan dibuat di thread ini (non-RT aman).
    double *in = fftw_alloc_real(kFftSize);
    fftw_complex *out = fftw_alloc_complex(kFftSize / 2 + 1);
    fftw_plan plan = fftw_plan_dft_r2c_1d(kFftSize, in, out, FFTW_ESTIMATE);

    std::vector<double> window(kFftSize);
    for (int i = 0; i < kFftSize; i++) {
        window[i] = 0.5 * (1.0 - std::cos(2.0 * M_PI * i / (kFftSize - 1)));
    }

    // Per-band peak untuk AGC (attack cepat, decay lambat).
    std::vector<double> peak(kBars, 1e-6);

    // Rentang frekuensi log-spaced (cava pakai kurva log).
    constexpr double fLow  = 30.0;
    constexpr double fHigh = kWindowRate / 2.0 * 0.95;

    const double rate = kWindowRate;
    const int numBins = kFftSize / 2 + 1;
    const double binHz = rate / kFftSize;

    size_t lastWp = 0;
    auto lastSamples = std::chrono::steady_clock::now();

    while (!g_terminate.load()) {
        const size_t wp = g_wp.load(std::memory_order_acquire);
        const size_t avail = wp - g_rp.load(std::memory_order_acquire);
        const size_t need = static_cast<size_t>(kFftSize);

        if (avail >= need) {
            // Ambil jendela terbaru (mono = rata-rata 2 channel interleaved).
            const size_t start = wp - need;
            for (int i = 0; i < kFftSize; i++) {
                const size_t idx = (start + static_cast<size_t>(i) * kChannels) & kRbMask;
                const float l = g_ring[idx];
                const float r = (kChannels > 1) ? g_ring[(idx + 1) & kRbMask] : 0.f;
                in[i] = window[i] * (l + r) * 0.5;
            }
            g_rp.store(wp, std::memory_order_release);
            lastSamples = std::chrono::steady_clock::now();
        } else {
            // Tidak ada data baru: kosongkan window supaya visualizer flat.
            // Tunggu sebentar dulu (audio diam legit kadang jeda 1-2 frame).
            const auto now = std::chrono::steady_clock::now();
            const auto idleMs =
                std::chrono::duration_cast<std::chrono::milliseconds>(now - lastSamples).count();
            if (idleMs > 120) {
                printZeros();
                fflush(stdout);
                lastSamples = now;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(16));
            continue;
        }

        fftw_execute(plan);

        // Kumpulkan daya per band (log spacing) → RMS → AGC → 0..255.
        char line[1024];
        size_t off = 0;

        // Pre-compute band bin ranges.
        int bandStart[kBars], bandEnd[kBars];
        for (int b = 0; b < kBars; b++) {
            const double f0 = fLow * std::pow(fHigh / fLow, static_cast<double>(b) / kBars);
            const double f1 = fLow * std::pow(fHigh / fLow, static_cast<double>(b + 1) / kBars);
            int s = std::clamp(static_cast<int>(std::floor(f0 / binHz)), 1, numBins - 1);
            int e = std::clamp(static_cast<int>(std::ceil(f1 / binHz)), s + 1, numBins - 1);
            bandStart[b] = s;
            bandEnd[b] = e;
        }

        for (int b = 0; b < kBars; b++) {
            double sum = 0.0;
            int count = 0;
            for (int k = bandStart[b]; k < bandEnd[b] && k < numBins; k++) {
                sum += out[k][0] * out[k][0] + out[k][1] * out[k][1];
                count++;
            }
            const double rms = count ? std::sqrt(sum / count) : 0.0;

            // AGC: peak tracker per band, normalize relatif ke peak.
            if (rms > peak[b]) peak[b] = rms;                 // attack instan
            else peak[b] = peak[b] * 0.90 + rms * 0.10;       // decay lembut

            double norm = rms / (peak[b] * 0.85 + 1e-6);
            if (norm > 1.0) norm = 1.0;
            if (norm < 0.025) norm = 0.0;         // noise gate: abaikan mikro/jitter saat hening
            else norm = std::pow(norm, 1.25);     // kompresi mid → respon lebih tenang

            int val = static_cast<int>(std::round(norm * 255.0));
            if (val > 255) val = 255;
            if (val < 0) val = 0;

            off += snprintf(line + off, sizeof(line) - off, "%s%d", b ? " " : "", val);
        }
        off += snprintf(line + off, sizeof(line) - off, "\n");
        fwrite(line, 1, off, stdout);
        fflush(stdout);

        std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<int>(kFrameMs)));
    }

    fftw_destroy_plan(plan);
    fftw_free(in);
    fftw_free(out);
}

} // namespace

int main() {
    setvbuf(stdout, nullptr, _IONBF, 0);

    // Blok SIGINT/SIGTERM di semua thread; hanya main loop yang menanganinya
    // via pw_loop_add_signal (signalfd). Mencegah proses mati mendadak 143.
    sigset_t sigs;
    sigemptyset(&sigs);
    sigaddset(&sigs, SIGINT);
    sigaddset(&sigs, SIGTERM);
    pthread_sigmask(SIG_BLOCK, &sigs, nullptr);

    pw_init(nullptr, nullptr);
    g_pw.loop = pw_main_loop_new(nullptr);
    if (g_pw.loop == nullptr) {
        fprintf(stderr, "[qs_visualizer] Gagal buat main loop. PipeWire jalan?\n");
        pw_deinit();
        return 1;
    }
    g_pw.loopImpl = pw_main_loop_get_loop(g_pw.loop);

    // Capture monitor default audio sink (menangkap audio yang sedang diputar),
    // sama seperti cara kerja cava pada PipeWire.
    struct pw_properties *props = pw_properties_new(
        PW_KEY_MEDIA_TYPE, "Audio",
        PW_KEY_MEDIA_CATEGORY, "Capture",
        PW_KEY_MEDIA_ROLE, "Music",
        PW_KEY_STREAM_CAPTURE_SINK, "true",
        PW_KEY_NODE_NAME, "qs_visualizer",
        PW_KEY_NODE_NICK, "qs_visualizer",
        PW_KEY_NODE_DESCRIPTION, "Quickshell visualizer",
        nullptr);

    g_pw.stream = pw_stream_new_simple(g_pw.loopImpl, "qs_visualizer", props,
                                       &kStreamEvents, &g_pw);

    const struct spa_pod *params[1];
    uint8_t buffer[1024];
    struct spa_pod_builder b = SPA_POD_BUILDER_INIT(buffer, sizeof(buffer));
    struct spa_pod_frame f;
    spa_pod_builder_push_object(&b, &f, SPA_TYPE_OBJECT_Format, SPA_PARAM_EnumFormat);
    spa_pod_builder_add(&b,
        SPA_FORMAT_mediaType,     SPA_POD_Id(SPA_MEDIA_TYPE_audio),
        SPA_FORMAT_mediaSubtype,  SPA_POD_Id(SPA_MEDIA_SUBTYPE_raw),
        SPA_FORMAT_AUDIO_format,  SPA_POD_Id(SPA_AUDIO_FORMAT_F32),
        SPA_FORMAT_AUDIO_rate,    SPA_POD_Int(kWindowRate),
        SPA_FORMAT_AUDIO_channels, SPA_POD_Int(kChannels));
    params[0] = static_cast<struct spa_pod *>(spa_pod_builder_pop(&b, &f));

    const int status = pw_stream_connect(
        g_pw.stream, PW_DIRECTION_INPUT, PW_ID_ANY,
        static_cast<enum pw_stream_flags>(PW_STREAM_FLAG_AUTOCONNECT | PW_STREAM_FLAG_MAP_BUFFERS |
                                          PW_STREAM_FLAG_RT_PROCESS),
        params, 1);
    if (status < 0) {
        fprintf(stderr, "[qs_visualizer] Gagal konek stream: %s\n", strerror(-status));
        pw_stream_destroy(g_pw.stream);
        pw_main_loop_destroy(g_pw.loop);
        pw_deinit();
        return 1;
    }

    pw_loop_add_signal(g_pw.loopImpl, SIGINT, onSignal, &g_pw);
    pw_loop_add_signal(g_pw.loopImpl, SIGTERM, onSignal, &g_pw);

    std::thread worker(fftWorker);
    pw_main_loop_run(g_pw.loop);

    g_terminate.store(true);
    if (worker.joinable()) worker.join();

    pw_stream_destroy(g_pw.stream);
    pw_main_loop_destroy(g_pw.loop);
    pw_deinit();
    return 0;
}