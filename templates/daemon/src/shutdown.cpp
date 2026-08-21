#include "shutdown.hpp"

#include <cerrno>
#include <chrono>
#include <ctime>
#include <system_error>

// signal.h rather than <csignal>: POSIX puts sigtimedwait, pthread_sigmask and
// the rest of what is used here in that header, and <csignal> is only required
// to provide the C subset, which none of them is in.
#include <signal.h>  // NOLINT(modernize-deprecated-headers,hicpp-deprecated-headers)

#include "service.hpp"

namespace mydaemon::shutdown {

namespace {

// The two NOLINTs here and below are one thing: glibc declares sigset_t and
// siginfo_t in a private bits/ header, so clang-tidy's include-cleaner has no
// public header to be told to include. There is nothing to fix.
auto watched() -> sigset_t  // NOLINT(misc-include-cleaner)
{
    sigset_t set{};
    sigemptyset(&set);
    sigaddset(&set, SIGTERM);
    sigaddset(&set, SIGINT);
    sigaddset(&set, SIGHUP);
    return set;
}

}  // namespace

void block()
{
    const sigset_t set = watched();

    // pthread_sigmask rather than sigprocmask: what the latter does in a process
    // with more than one thread is unspecified. Doing it here, before any thread
    // exists, is also what makes every thread started later inherit it.
    const int failure = pthread_sigmask(SIG_BLOCK, &set, nullptr);
    if (failure != 0) {
        throw std::system_error(failure, std::generic_category(), "blocking the signals this process answers");
    }
}

auto wait(std::chrono::milliseconds limit) -> service::Wakeup
{
    const sigset_t set = watched();
    const auto whole_seconds = std::chrono::duration_cast<std::chrono::seconds>(limit);

    std::timespec timeout{};
    timeout.tv_sec = whole_seconds.count();
    timeout.tv_nsec = std::chrono::nanoseconds(limit - whole_seconds).count();

    for (;;) {
        siginfo_t received{};  // NOLINT(misc-include-cleaner)
        if (sigtimedwait(&set, &received, &timeout) >= 0) {
            return received.si_signo == SIGHUP ? service::Wakeup::Reload : service::Wakeup::Stop;
        }
        if (errno == EAGAIN) {
            return service::Wakeup::Timeout;
        }
        if (errno != EINTR) {
            throw std::system_error(errno, std::generic_category(), "waiting for a signal");
        }
    }
}

}  // namespace mydaemon::shutdown
