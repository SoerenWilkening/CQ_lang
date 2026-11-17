__attribute__((noinline)) static _Float16 twice16(_Float16 h) { return h + h; }
float float16_q(float f0, double th, float c) {
    float f = f0;
    cq_theta(&f, th);
    _Float16 h = (_Float16)f;
    h = h * (_Float16)c + 1.0f16;
    return cq_measure((float)twice16(h));
}
