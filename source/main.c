#include <3ds.h>
#include <stdio.h>

double charSelectTime = 62.50;
double alchemyTime = 35.00;
bool timerRunning = false;
u64 startTicks = 0;

void PressA() {
    hidScanInput();
    u32 kDown = hidKeysDown();
    if (kDown & KEY_A) return;
    hidKeyInput_t keys = {KEY_A, 0};
    hidSetKeys(&keys);
    svcSleepThread(50000000LL);
    keys = {0, 0};
    hidSetKeys(&keys);
}

void TimerThread(void* arg) {
    while (timerRunning) {
        u64 now = svcGetSystemTick();
        double elapsed = (now - startTicks) / 26812352.0;
        if (elapsed >= charSelectTime && elapsed < charSelectTime + 0.01) PressA();
        if (elapsed >= alchemyTime && elapsed < alchemyTime + 0.01) PressA();
        svcSleepThread(1000000LL);
    }
    vTaskExit();
}

int main() {
    gfxInitDefault();
    consoleInit(GFX_TOP, NULL);

    printf("MH4G SnipeAutoA\n");
    printf("A: 開始\n");
    printf("B: 終了\n");

    while (aptMainLoop()) {
        hidScanInput();
        u32 kDown = hidKeysDown();

        if (kDown & KEY_A) {
            if (timerRunning) continue;
            startTicks = svcGetSystemTick();
            timerRunning = true;
            threadCreate(TimerThread, NULL, 32*1024, 0x30, -1, false);
            printf("タイマー開始！\n");
        }

        if (kDown & KEY_B) break;

        gfxFlushBuffers();
        gfxSwapBuffers();
        gspWaitForVBlank();
    }

    gfxExit();
    return 0;
}
