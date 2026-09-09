#include "shutdown.hpp"

#include <chrono>
#include <csignal>
#include <thread>

#include <pthread.h>

#include <gtest/gtest.h>

#include "service.hpp"

// The wait is given an interval and has to end within it. What makes that hard
// is EINTR: any signal the process catches ends the poll early, and a running
// system has no shortage of them - a profiler's timer, a debugger, a terminal
// resuming a stopped process. A wait that asked again for its whole interval
// each time would keep postponing the next run for as long as they arrived.

namespace {

extern "C" void caught(int /*signal_number*/)
{
}

/// Catches SIGUSR1 for the length of a test, so that a poll interrupted by one
/// comes back with EINTR. Without SA_RESTART deliberately: with it - which is
/// what a handler installed through signal() gets - the kernel restarts the
/// poll and there is nothing here to measure.
class Interruptions {
public:
    Interruptions()
    {
        struct sigaction handler{};
        handler.sa_handler = caught;
        sigemptyset(&handler.sa_mask);
        ::sigaction(SIGUSR1, &handler, &previous_);
    }

    ~Interruptions()
    {
        ::sigaction(SIGUSR1, &previous_, nullptr);
    }

    Interruptions(const Interruptions&) = delete;
    Interruptions(Interruptions&&) = delete;
    auto operator=(const Interruptions&) -> Interruptions& = delete;
    auto operator=(Interruptions&&) -> Interruptions& = delete;

private:
    struct sigaction previous_{};
};

/// A Watcher blocks the signals a service manager sends and never unblocks
/// them. In the program that is the point; here the thread it did it in
/// outlives the test, and one of those signals is the SIGTERM ctest stops a
/// test with when it runs out of time.
class BlockedSignals {
public:
    BlockedSignals()
    {
        ::pthread_sigmask(SIG_SETMASK, nullptr, &previous_);
    }

    ~BlockedSignals()
    {
        ::pthread_sigmask(SIG_SETMASK, &previous_, nullptr);
    }

    BlockedSignals(const BlockedSignals&) = delete;
    BlockedSignals(BlockedSignals&&) = delete;
    auto operator=(const BlockedSignals&) -> BlockedSignals& = delete;
    auto operator=(BlockedSignals&&) -> BlockedSignals& = delete;

private:
    sigset_t previous_{};
};

}  // namespace

TEST(Watcher, SaysNothingArrivedWhenNothingDid)
{
    const BlockedSignals restored;
    mydaemon::shutdown::Watcher watcher;

    EXPECT_EQ(watcher.wait(std::chrono::milliseconds{20}), mydaemon::service::Wakeup::Timeout);
}

TEST(Watcher, AnswersASignalThatArrivedBeforeTheWait)
{
    const BlockedSignals restored;
    mydaemon::shutdown::Watcher watcher;

    ASSERT_EQ(::raise(SIGTERM), 0);

    EXPECT_EQ(watcher.wait(std::chrono::seconds{10}), mydaemon::service::Wakeup::Stop);
}

TEST(Watcher, EndsWithinItsLimitWhileOtherSignalsInterruptIt)
{
    const BlockedSignals restored;
    const Interruptions interrupted;
    mydaemon::shutdown::Watcher watcher;

    constexpr auto limit = std::chrono::milliseconds{600};
    constexpr auto between = std::chrono::milliseconds{80};
    constexpr int interruptions = 5;

    const pthread_t waiting = ::pthread_self();
    std::thread interrupter{[waiting, between] {
        for (int sent = 0; sent < interruptions; ++sent) {
            std::this_thread::sleep_for(between);
            ::pthread_kill(waiting, SIGUSR1);
        }
    }};

    const auto started = std::chrono::steady_clock::now();
    const auto woke = watcher.wait(limit);
    const auto elapsed = std::chrono::steady_clock::now() - started;
    interrupter.join();

    EXPECT_EQ(woke, mydaemon::service::Wakeup::Timeout);

    // The last interruption lands 400ms in. A wait that started its limit over
    // there would end at 1000ms, so ending before 800 can only mean the time
    // already spent was counted.
    EXPECT_LT(elapsed, std::chrono::milliseconds{800});
}
