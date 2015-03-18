#include <blink1-lib.h>
#include <iostream>
#include <vector>
#include <time.h>

using std::vector;

const uint8_t LED_START = 3;
const uint8_t LED_STOP  = 15;
const uint8_t LED_NUM   = LED_STOP-LED_START;
const int MILLIS = 300;//10 + (300/LED_NUM);
const int MILLIS_DELAY = 500/LED_NUM;

blink1_device* initializeBlink() {
    std::cout << "opening default device" << std::endl;
    blink1_device* dev = blink1_open();
    std::cout << "serial: " <<  blink1_getSerialForDev(dev)
              << ((blink1_isMk2(dev)) ? " (mk2)" : "")
              << " path: " << blink1_getCachedPath(blink1_getCacheIndexByDev(dev))
              << std::endl;

    return dev;
}

vector<uint8_t> createGradient(const uint8_t maxBright) {
    vector<uint8_t> gradient;

    for( int i=0; i<LED_NUM; i++ ) {          // LED_NUM-i or i+1
        int value = static_cast<int>(maxBright)*(i+1)/static_cast<int>(LED_NUM);
        gradient.push_back(static_cast<uint8_t>(value));
    }

    return gradient;
}

struct tm getNow() {
    time_t now_int = time(0);
    struct tm  now_struct = *localtime(&now_int);
    return now_struct;
}

void showTime(const struct tm time) {
    std::cout << time.tm_hour << ":" << time.tm_min << ":" << time.tm_sec << std::endl;
}

int main(int argc, char** argv)
{
    blink1_device* dev = initializeBlink();

    auto gradient = createGradient(255);
    // for (auto it=gradient.begin(); it != gradient.end(); ++it)
    //     std::cout << static_cast<int>(*it) << " ";
    // std::cout << std::endl;

    struct tm now = getNow();
    // showTime(now);

    uint8_t r = 255;
    uint8_t g = 255;
    uint8_t b = 255;
    uint8_t ledn;
    int rc;
    for (uint8_t i = 0; i < LED_NUM; ++i) {
        ledn = i + LED_START;
        rc = blink1_fadeToRGBN(dev, MILLIS, gradient[i],gradient[i],gradient[i],ledn);
        blink1_sleep(MILLIS_DELAY);
    }

    return 0;
}


