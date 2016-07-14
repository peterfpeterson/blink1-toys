#include <algorithm>
#include <array>
#include <blink1-lib.h>
#include <iostream>
#include <memory>
#include <signal.h>
#include <vector>
#include <time.h>
#include <unistd.h>

using std::vector;

const uint8_t LED_START = 3;
const uint8_t LED_STOP = 15;
const uint8_t LED_NUM = LED_STOP - LED_START;
const int MILLIS = 10 + (300 / LED_NUM);
const int MILLIS_DELAY = 100;
const uint8_t MAX_BRIGHT = 127; // 255 is the absolute max

/* -------------------------------------------------------------------------- */

struct Color {
  uint8_t red;
  uint8_t green;
  uint8_t blue;
};

const Color COLOR_OFF{0, 0, 0};

struct LedColor {
  Color color;
  uint8_t number;
};

/* -------------------------------------------------------------------------- */

typedef std::array<Color, LED_STOP-LED_START> FrameStill;

typedef std::array<LedColor, LED_STOP-LED_START> FrameAnim;

FrameStill generateFill(const Color &color) {
  FrameStill frame;
  frame.fill(color);
  return frame;
}

FrameAnim generateFillDecreasing(const Color &color) {
  LedColor led{color, 0};
  uint8_t ledn = LED_STOP-1;

  FrameAnim frame;
  frame.fill(led);
  for (auto & led : frame) {
    led.number = ledn;
    ledn -= 1;
  }
  return frame;
}

/* -------------------------------------------------------------------------- */

class Blink {
public:
  Blink() : dev(NULL) {
#ifndef NDEBUG
  std::cout << "opening default device" << std::endl;
#endif

  this->dev = blink1_open();

#ifndef NDEBUG
  std::cout << "serial: " << blink1_getSerialForDev(dev)
            << ((blink1_isMk2(dev)) ? " (mk2)" : "")
            << " path: " << blink1_getCachedPath(blink1_getCacheIndexByDev(dev))
            << std::endl;
#endif
  }

  ~Blink() {
    if (this->dev) {
      blink1_close(dev);
    }
  }

  int fadeToRGB(const Color &color, const uint8_t ledn) {
    return blink1_fadeToRGBN(this->dev, MILLIS, color.red, color.green,
                             color.blue, ledn);
  }

  /// Convenience function
  int showFrame(const FrameStill &frame) {
    uint8_t ledn = LED_START;
    int rc = 0;
    for (const auto& color : frame) {
      rc += fadeToRGB(color, ledn);
      ledn += 1;
    }
    return rc;
  }

  /// Frame is played in increasing ledn order
  int showFrame(const FrameAnim &frame, const int delay = MILLIS_DELAY) {
    uint8_t ledn = LED_START;
    int rc = 0;
    for (const auto& led : frame) {
      rc += fadeToRGB(led.color, led.number);
      blink1_sleep(delay);
      ledn += 1;
    }
    return rc;
  }

  /// Convenience function to turn all the leds off in decreasing order
  int fadeToOff() {
    FrameAnim frame = generateFillDecreasing(COLOR_OFF);
    return showFrame(frame);
  }

private:
  blink1_device* dev;
};

/* -------------------------------------------------------------------------- */

vector<uint8_t> createGradient(const char *label, const int led_max) {
  vector<uint8_t> gradient(LED_NUM, 0);

  for (int i = 0; i < LED_NUM; i++) {
    if (i < led_max) {
      int value = static_cast<int>(MAX_BRIGHT) * (i + LED_NUM - led_max + 1) /
                  static_cast<int>(LED_NUM);
      gradient[LED_NUM - i - 1] = static_cast<uint8_t>(value);
    }
  }

#ifndef NDEBUG
  std::cout << label << "=" << led_max << ": ";
  for (auto it = gradient.begin(); it != gradient.end(); ++it)
    std::cout << static_cast<int>(*it) << " ";
  std::cout << std::endl;
#endif

  return gradient;
}

struct tm getNow() {
  time_t now_int = time(0);
  struct tm now_struct = *localtime(&now_int);
  return now_struct;
}

int calcGradIndex(const int i, const int j, int led_max) {
  if (i < led_max) {
    int index = (LED_NUM - led_max - j + i) % LED_NUM;
    if (index < 0)
      index += LED_NUM;
    return index;
  } else {
    return calcGradIndex(led_max - 1, j, led_max);
  }
}

void showTime(std::unique_ptr<Blink> &blink1, const struct tm time) {
  int led_hour = (time.tm_hour % 12);
  if (led_hour == 0)
    led_hour = LED_NUM;

  int led_min = time.tm_min * LED_NUM / 60;
  // FIXME - not right for last 5 minutes

  int led_sec = time.tm_sec * LED_NUM / 60;
  // FIXME - not right for last 5 seconds

#ifndef NDEBUG
  std::cout << "time " << time.tm_hour << ":" << time.tm_min << ":"
            << time.tm_sec << std::endl;
  std::cout << "LED_NUM = " << static_cast<int>(LED_NUM) << std::endl;
  std::cout << "leds " << led_hour << " " << led_min << " " << led_sec
            << std::endl;
#endif

  // change of variables
  int led_red = 0; // disable
  int led_green = led_hour;
  int led_blue = led_min;

  auto gradient_red = createGradient("red", led_red);
  auto gradient_green = createGradient("green", led_green);
  auto gradient_blue = createGradient("blue", led_blue);

  uint8_t ledn;
  int grad_index, grad_index_red, grad_index_green, grad_index_blue;
  int rc;
  for (int i = 0; i < LED_NUM; ++i) {
#ifndef NDEBUG
    std::cout << "------------ i=" << i << std::endl;
#endif
    for (int j = 0; j < LED_NUM; ++j) {
      ledn = j + LED_START;
      grad_index = calcGradIndex(i, j, 12);
      grad_index_red = calcGradIndex(i, j, led_red);
      grad_index_green = calcGradIndex(i, j, led_green);
      grad_index_blue = calcGradIndex(i, j, led_blue);

#ifndef NDEBUG
      printf("L%2d\tG%2d\tr[%2d] %3d", ledn, grad_index, grad_index_red,
             gradient_red[grad_index_red]);
      printf("\tg[%2d] %3d", grad_index_green,
             gradient_green[grad_index_green]);
      printf("\tb[%2d] %3d\n", grad_index_blue, gradient_blue[grad_index_blue]);
#endif

      if (j <= i) {
        rc = blink1->fadeToRGB(Color{gradient_red[grad_index_red],
                                     gradient_green[grad_index_green],
                                     gradient_blue[grad_index_blue]},
                               ledn);
      } else {
        rc = blink1->fadeToRGB(COLOR_OFF, ledn);
      }
    }
    blink1_sleep(MILLIS_DELAY);
  }
}

void cleanup(int param) {
  std::cout << "\ncleaning up" << std::endl;

  auto blink = std::make_unique<Blink>();
  blink->fadeToOff();
  exit(0);
}

int main(int argc, char **argv) {
  signal(SIGINT, cleanup);

  std::cout << "press 'ctrl-c' to quit" << std::endl;
  while (true) {
    {
      auto blink = std::make_unique<Blink>();
      struct tm now = getNow();
      showTime(blink, now);
    }
    usleep(10000000);
  }

  return 0;
}
